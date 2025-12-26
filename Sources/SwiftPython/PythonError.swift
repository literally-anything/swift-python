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
}

// Error Tracking
extension PythonError {
    public final class TrackingState: @unchecked Sendable {
        public var error: PythonError? = nil

        @usableFromInline
        internal init() {}
    }

    @TaskLocal
    public static var trackingState: TrackingState? = nil

    public static func checkTracked() -> Bool {
        do throws(PythonError) {
            try check()
            return true
        } catch let error {
            if trackingState != nil {
                trackingState!.error = error
            } else {
                fatalError("Python error not caught in Swift code: \(error)")
            }
            return false
        }
    }

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
        }
        if let error {
            throw error
        }
        return returnValue!
    }

    @inlinable
    @_disfavoredOverload
    public static func withErrorTracking<T: ~Copyable>(
        _ body: () throws -> T
    ) throws -> T {
        var returnValue: T? = nil
        try $trackingState.withValue(TrackingState()) {
            returnValue = try body()
            if let error = trackingState!.error {
                throw error
            }
        }
        return returnValue!
    }
}
