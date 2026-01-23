/**
 * PythonError.swift
 * SwiftPython
 * 
 * Created by Hunter Baker on 12/25/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunter@literallyanything.net
 */

@preconcurrency import CPython

/// A shared reference to a python object. This is used to encapsulate a noncopyable `PythonObject` type inside a `Copyable` type.
/// This is supposed to be a temporary fix until more protocols and features support noncopyable types.
internal final class SharedPythonObject: @unchecked Sendable {
    var object: PythonObject

    /// Initialize a `SharedPythonObject` with an existing `PythonObject`.
    /// - Parameter object: An existing `PythonObject`.
    init(_ object: consuming PythonObject) {
        self.object = object
    }
}

/// An error that occurred in Python.
public struct PythonError: Error {
    /// The shared storage for the underlying Python exception object.
    internal let sharedObject: SharedPythonObject

    /// The underlying python exception object.
    public var exception: PythonObject {
        _read {
            yield sharedObject.object
        }
        _modify {
            yield &sharedObject.object
        }
    }

    /// Initialize a `PythonError` from a `PythonObject`.
    public init(_ exception: consuming PythonObject) {
        self.sharedObject = SharedPythonObject(exception)
    }
}

extension PythonError: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        exception.description
    }
    public var debugDescription: String {
        "PythonError(\(exception.debugDescription))"
    }
}

// Python exception raising
extension PythonError {
    /// The default type for errors thrown in Swift that have no direct exception type in Python
    /// ToDo: Figure this out...
    internal nonisolated(unsafe) static let swiftException: UnsafePyObjectRef = {
        return PyErr_NewException("SwiftException", nil, nil)!
    }()

    /// Raise the `PythonError` in python.
    /// This sets the error flag, so a function should return back to python with a NULL return value right after calling this.
    @safe
    public func raise(file: StaticString = #filePath, line: CInt = #line, col: CInt = #column) {
        // ToDo: Use actual source location instead of raise location

        let isException: Bool = _PyExceptionInstance_Check(exception.pyObject)
        if isException {
            PyErr_SetRaisedException(exception.copy().take())
        } else {
            PyErr_SetObject(PythonError.swiftException, exception.copy().take())
        }
        PyErr_SyntaxLocationEx(file._cStringStart, line, col)
    }
}

// Initialize from Swift errors
extension PythonError {
    /// Initialize a `PythonError` from an arbitrary Swift `Error`.
    /// If the error is not convertable to a `PythonError` or the conversion fails, `None` is passed as the value of the exception.
    /// - Parameter error: The error to convert into a `PythonError`.
    public init(_ error: any Error) {
        let pythonObject: PythonObject?
        if let error = (error as? any PythonConvertible) {
            pythonObject = try? error.convertToPythonObject()
        } else {
            let str: String = "\(error)"
            pythonObject = str.isEmpty ? nil : try? str.convertToPythonObject()
        }
        self.init(pythonObject ?? PythonObject.none)
    }

    /// Initialize a `PythonError` from an arbitrary Swift `Error` that conforms to `PythonConvertible`.
    /// If the conversion fails, `None` is passed as the value of the exception.
    /// - Parameter error: The error to convert into a `PythonError`.
    @inlinable
    public init(_ error: some Error & PythonConvertible) {
        let pythonObject: PythonObject? = try? error.convertToPythonObject()
        self.init(pythonObject ?? PythonObject.none)
    }
}

// Error types
extension PythonError {
    /// Get a new python `Exception` type with the message "Unknown Error".
    /// This should really never be called. It is a fallback for when no error is found, but something failed.
    public static var unknown: PythonError {
        PythonError(type: PyExc_Exception, message: "Unknown Error")
    }

    /// Creates a new python `TypeError` for use when an argument to a function is invalid.
    /// This is mainly for use in generated bridging code.
    /// - Parameter message: The error message
    /// - Returns: The newly built `PythonError`
    public static func badArgument(_ message: String) -> PythonError {
        return PythonError(
            type: PyExc_TypeError,
            message: message
        )
    }

    /// Creates a new python `TypeError` for use when the type of a PythonObject is invalid in a conversion.
    /// - Parameter real: The name of the type that we are trying to build
    /// - Returns: The newly built `PythonError`
    public static func badType(real: String) -> PythonError {
        return PythonError(
            type: PyExc_TypeError,
            message: "Bad type. Could not convert to `\(real)`"
        )
    }
}

// Error atributes
extension PythonError {
    /// The Python exception `__cause__` value.
    /// Represents the error that caused this error.
    public var cause: PythonError? {
        get {
            let causeExcRef: UnsafePyObjectRef? = PyException_GetContext(exception.pyObject)
            let causeExc: PythonObject? = PythonObject(fromOwned: causeExcRef)
            if let causeExc {
                return PythonError(causeExc)
            } else {
                return nil
            }
        }
        borrowing set(newValue) {
            if _PyExceptionInstance_Check(exception.pyObject) {
                PyException_SetContext(exception.pyObject, newValue?.exception.copy().take())
            }
        }
    }
}

// Handling

extension PythonError {
    /// Check for python errors and throw them if found.
    /// - Throws: A `PythonError` if one is set.
    public static func check() throws(PythonError) {
        if unsafe PyErr_Occurred() == nil { return }

        let exceptionRef: UnsafePyObjectRef? = unsafe PyErr_GetRaisedException()
        if let exceptionRef {
            let exception: PythonObject = PythonObject(fromOwned: exceptionRef)
            throw PythonError(exception)
        }
    }

    /// Initialize a `PythonError` using a Python error type and a message.
    public init(type: UnsafePyObjectRef!, message: String) {
        PyErr_SetString(type, message)
        let error = PythonObject(fromOwned: PyErr_GetRaisedException())
        assert(error != nil, "Python error not set immediately after setting an error. This should never happen.")
        self.init(error!)
    }
}

// Error Tracking
extension PythonError {
    /// A box for an error to be recorded while using error tracking.
    public final class TrackingState: @unchecked Sendable {
        /// The stored error or `nil` if no error has occured.
        internal var error: PythonError? = nil

        @usableFromInline
        internal init() {}

        /// Record an error into the traking state to be thrown later.
        /// - Parameter error: The error to record
        public func report(_ error: consuming PythonError) {
            if self.error == nil {
                self.error = error
            }
        }

        /// Whether an error has already been recorded.
        public var hasError: Bool {
            error != nil
        }

        /// Take the error out of the `TrackingState` and set `error` to `nil`.
        @usableFromInline
        internal func take() -> PythonError? {
            return error.take()
        }
    }

    /// The current error tracking state.
    /// 
    /// This stores python errors for multi-step operations in swift constructs that cannot throw so
    /// that they can be thrown later. This is enabled using the `withErrorTracking(_:)` function.
    @TaskLocal
    public static var trackingState: TrackingState? = nil

    /// Logs an error into the current tracking state.
    /// This will throw a fatal error if tracking is not running.
    @usableFromInline
    internal static func trackError(error: PythonError) {
        if trackingState != nil {
            trackingState!.error = error
        } else {
            fatalError("Python error not caught in Swift code: \(error.debugDescription) ; This should be wrapped in `PythonError.withErrorTracking {}`")
        }
    }

    /// Check for python errors after a Python C API call and record it to the shared error tracking state.
    /// - Returns: Whether the call was successful (`true` for good, `false` if an error was recorded).
    @discardableResult
    public static func checkTracked() -> Bool {
        do throws(PythonError) {
            try check()
            return true
        } catch let error {
            trackError(error: error)
            return false
        }
    }

    /// Converts a throwing call into error tracking.
    /// This is rarely the best way to do something.
    /// - Parameter body: The throwing closure.
    /// - Returns: The return from `body` or `nil` on error.
    @inlinable
    @discardableResult
    public static func toTracked<T: ~Copyable>(
        _ body: () throws(PythonError) -> T
    ) -> T? {
        do {
            return try body()
        } catch let error {
            trackError(error: error)
            return nil
        }
    }

    /// Enables error tracking in `body`.
    /// Any python errors that occur inside `body` —whether thrown or recorded with error tracking—will be thrown.
    /// - Parameter body: The closure to call with error tracking enabled.
    /// - Throws: `PythonError` if `body` throws or if an error was recorded by the end of `body`.
    /// - Returns: The return from `body`.
    @inlinable
    public static func withErrorTracking<T: ~Copyable>(
        _ body: () throws(PythonError) -> T
    ) throws(PythonError) -> T {
        var returnValue: T? = nil
        var error: PythonError? = nil
        $trackingState.withValue(TrackingState()) {
            do throws(PythonError) {
                returnValue = try body()
            } catch let e {
                error = e
            }
            if let e = trackingState!.take() {
                error = e
            }
        }
        if let error {
            throw error
        }
        return returnValue!
    }

    /// Enables error tracking in `body`.
    /// Any python errors that occur inside `body` —whether thrown or recorded with error tracking—will be thrown.
    /// - Parameter body: The closure to call with error tracking enabled.
    /// - Throws: If `body` throws or a `PythonError` if an error was recorded by the end of `body`.
    /// - Returns: The return from `body`.
    @inlinable
    @_disfavoredOverload
    public static func withErrorTracking<T: ~Copyable>(
        _ body: () throws -> T
    ) throws -> T {
        var returnValue: T? = nil
        try $trackingState.withValue(TrackingState()) {
            returnValue = try body()
            if let error = trackingState!.take() {
                throw error
            }
        }
        return returnValue!
    }
}
