/**
 * PythonError.swift
 * SwiftPython
 * 
 * Created by Hunter Baker on 12/25/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

import CPython

/// An error that occurred in Python.
public struct PythonError: Error {
    /// The underlying python exception object.
    public let exception: SharedPythonObject

    /// Initialize a `PythonError` from a `SharedPythonObject`.
    /// - Note: May be removed in the future if `SharedPythonObject` goes away.
    public init(_ exception: SharedPythonObject) {
        self.exception = exception
    }
    /// Initialize a `PythonError` from a `PythonObject`.
    public init(_ exception: consuming PythonObject) {
        self.exception = SharedPythonObject(exception)
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

extension PythonError {
    /// Check for python errors and throw them if found.
    /// - Throws: A `PythonError` if one is set.
    public static func check() throws(PythonError) {
        if unsafe PyErr_Occurred() == nil { return }

        let exceptionRef: UnsafePyObjectRef? = unsafe PyErr_GetRaisedException()
        if let exceptionRef {
            let exception: PythonObject = PythonObject(unsafeUnretained: exceptionRef)
            throw PythonError(exception)
        }
    }

    /// Get a new python `Exception` type with the message "Unknown Error".
    /// This should really never be called. It is a fallback for when no error is found, but something failed.
    public static var unknown: PythonError {
        PythonError(
            PythonObject(
                unsafeUnretained: PyErr_NewException("Unknown Error", nil, nil)
            )
        )
    }

    /// Initialize a `PythonError` using a Python error type and a message.
    internal init(type: UnsafePyObjectRef!, message: StaticString) {
        PyErr_SetString(type, message._cStringStart)
        let error = PythonObject(unsafeUnretained: PyErr_GetRaisedException())
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
            self.error = error
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
