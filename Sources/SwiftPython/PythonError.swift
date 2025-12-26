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
    public let sharedObject: SharedPythonObject
    /// The python traceback object.
    public let traceback: SharedPythonObject?

    /// Initialize a `PythonError` from a `SharedPythonObject`.
    /// - Note: May be removed in the future if `SharedPythonObject` goes away.
    public init(_ sharedObject: SharedPythonObject, traceback: SharedPythonObject? = nil) {
        self.sharedObject = sharedObject
        self.traceback = traceback
    }
    /// Initialize a `PythonError` from a `PythonObject`.
    public init(_ object: consuming PythonObject, traceback: consuming PythonObject? = nil) {
        self.sharedObject = SharedPythonObject(object)
        if traceback != nil {
            self.traceback = SharedPythonObject(traceback!)
        } else {
            self.traceback = nil
        }
    }
}

extension PythonError: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        if traceback != nil {
            sharedObject.description + "\nTraceback:\n" + traceback!.description
        } else {
            sharedObject.description
        }
    }
    public var debugDescription: String {
        "PythonError(\(sharedObject.debugDescription), traceback: \(traceback?.debugDescription ?? "nil"))"
    }
}

extension PythonError {
    /// Check for python errors and throw them if found.
    /// - Throws: A `PythonError` if one is set.
    public static func check() throws(PythonError) {
        // Got from https://github.com/pvieito/PythonKit/blob/master/PythonKit/Python.swift#L249
        if unsafe PyErr_Occurred() == nil { return }

        var typeRef: UnsafePyObjectRef?
        var valueRef: UnsafePyObjectRef?
        var tracebackRef: UnsafePyObjectRef?
        unsafe PyErr_Fetch(&typeRef, &valueRef, &tracebackRef)

        // The value for the exception may not be set but the type always should be.
        let result: PythonObject = PythonObject(unsafeUnretained: valueRef ?? typeRef!)
        let traceback = tracebackRef.map { PythonObject(unsafeUnretained: $0) }
        throw PythonError(result, traceback: traceback)
    }

    public static func getUnknownError() -> PythonError {
        PythonError(
            PythonObject(
                unsafeUnretained: PyErr_NewException("Unknown Error", nil, nil)
            )
        )
    }
}

// Error Tracking
extension PythonError {
    // ToDo: Implement proper error tracking for python objects.
    //       This would allow things like `my_py_object.some_attr.another_attr.my_callable()` to work without hitting a fatalError by wrapping it in a closure
    //       that automatically checks for errors and throws them. This will use TaskLocals to tell whether tracking is on and if there has already been an error.
}
