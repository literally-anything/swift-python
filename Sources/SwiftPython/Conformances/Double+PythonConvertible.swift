/**
 * Double+PythonConvertible.swift
 * Conformances
 * 
 * Created by Hunter Baker on 12/27/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

import CPython

extension CFloat16: PythonConvertible {
    public func _toPythonObject() throws(PythonError) -> PythonObject {
        return try CDouble(self)._toPythonObject()
    }
}

extension CFloat: PythonConvertible {
    public func _toPythonObject() throws(PythonError) -> PythonObject {
        return try CDouble(self)._toPythonObject()
    }
}

extension CDouble: PythonConvertible {
    public func _toPythonObject() throws(PythonError) -> PythonObject {
        let ref: UnsafePyObjectRef? = PyFloat_FromDouble(self)
        guard let ref else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return PythonObject(unsafeUnretained: ref)
    }
}
