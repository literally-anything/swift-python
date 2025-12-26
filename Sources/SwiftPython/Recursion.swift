/**
 * Recursion.swift
 * SwiftPython
 * 
 * Created by Hunter Baker on 12/25/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

public import CPython

/// Track recursion depth using CPython and throw a python RecursionError when the limit is reached.
/// Wrap this around the recursive call to track the depth.
/// - Parameters:
///   - name: The name of the function being recursively called or the general task being performed.
///   - body: The block of code to execute after incrementing the recursion depth counter.
/// - Throws: Any error thrown from `body`.
/// - Returns: Any value returned from `body`.
@inlinable
public func withPythonRecursionTracking<T: ~Copyable, E: Error>(
    name: StaticString,
    body: () throws(E) -> T
) throws -> T {
    let ret = Py_EnterRecursiveCall(name._cStringStart)
    guard ret == 0 else {
        fatalError("ToDo: Properly exit when the recursion limit is hit")
    }
    defer {
        Py_LeaveRecursiveCall()
    }
    return try body()
}
