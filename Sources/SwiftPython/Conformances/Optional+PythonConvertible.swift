/**
 * Optional+PythonConvertible.swift
 * Conformances
 * 
 * Created by Hunter Baker on 12/29/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

import CPython

extension Optional: PythonConvertible where Wrapped: PythonConvertible & ~Copyable {
    public init(_ pythonObject: consuming PythonObject) throws(PythonError) {
        if pythonObject.isNone {
            self = .none
        } else {
            self = .some(try Wrapped(pythonObject))
        }
    }

    public consuming func convertToPythonObject() throws(PythonError) -> PythonObject {
        if let wrapped = self {
            return try wrapped.convertToPythonObject()
        } else {
            return PythonObject.none
        }
    }
}

extension Optional where Wrapped == PythonObject {
    /// Internal helper to convert a python optional "Value | None" to a Swift `Optional`.
    internal init(optional pythonObject: consuming PythonObject) {
        if pythonObject.pyObject == Py_GetConstantBorrowed(0) {
            self = Optional<PythonObject>.none
        } else {
            self = Optional<PythonObject>.some(pythonObject)
        }
    }
}
