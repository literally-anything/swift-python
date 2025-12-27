/**
 * PythonConvertible.swift
 * SwiftPython
 * 
 * Created by Hunter Baker on 12/26/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

/// A type that can be converted to a python object 
public protocol PythonConvertible: ~Copyable {
    /// Get this instance represented as a `PythonObject`.
    ///
    /// ToDo: Change this to a `var pythonObject: PythonObject { consuming get }` whenever that stops giving weird errors when returning self.
    func _toPythonObject() throws(PythonError) -> PythonObject
}

extension PythonObject: PythonConvertible {
    @inlinable
    public func _toPythonObject() -> PythonObject {
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
    public init(_ object: borrowing some PythonConvertible) throws(PythonError) {
        self = try object._toPythonObject()
    }
}
