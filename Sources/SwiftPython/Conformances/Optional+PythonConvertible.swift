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

    public consuming func _toPythonObject() throws(PythonError) -> PythonObject {
        if let wrapped = self {
            return try wrapped._toPythonObject()
        } else {
            return PythonObject.none
        }
    }
}
