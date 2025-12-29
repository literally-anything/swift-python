/**
 * PythonConvertible.swift
 * SwiftPython
 * 
 * Created by Hunter Baker on 12/26/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

/// A type that can be converted to a python object 
public protocol PythonConvertible: ~Copyable {
    /// Initialize from a `PythonObject`.
    init(_ pythonObject: consuming PythonObject) throws(PythonError)

    /// Get this instance represented as a `PythonObject`.
    ///
    /// ToDo: Change this to a `var pythonObject: PythonObject { consuming get }` whenever that stops giving weird errors when returning self.
    consuming func _toPythonObject() throws(PythonError) -> PythonObject
}

extension PythonObject: PythonConvertible {
    @inlinable
    public init(_ pythonObject: consuming PythonObject) {
        self = pythonObject
    }
    @inlinable
    public borrowing func _toPythonObject() -> PythonObject {
        return copy()
    }
}
extension SharedPythonObject: PythonConvertible {
    @inlinable
    public func _toPythonObject() -> PythonObject {
        return object.copy()
    }
}

extension PythonObject {
    @inlinable
    public init(_ object: consuming some PythonConvertible & ~Copyable) throws(PythonError) {
        self = try object._toPythonObject()
    }
}
