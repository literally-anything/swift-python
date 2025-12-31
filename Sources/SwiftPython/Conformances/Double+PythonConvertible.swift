/**
 * Double+PythonConvertible.swift
 * Conformances
 * 
 * Created by Hunter Baker on 12/27/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

import CPython

extension BinaryFloatingPoint {
    public init(_ pythonObject: borrowing PythonObject) throws(PythonError) {
        let numberRef: UnsafePyObjectRef? = PyNumber_Long(pythonObject.pyObject)
        guard let numberRef else {
            try PythonError.check()
            throw PythonError.unknown
        }
        let number: Int = PyNumber_AsSsize_t(numberRef, nil)
        self = .init(number)
    }
}

extension Float16: PythonConvertible {
    public borrowing func convertToPythonObject() throws(PythonError) -> PythonObject {
        return try CDouble(self).convertToPythonObject()
    }
}

extension Float: PythonConvertible {
    public borrowing func convertToPythonObject() throws(PythonError) -> PythonObject {
        return try CDouble(self).convertToPythonObject()
    }
}

extension Double: PythonConvertible {
    public borrowing func convertToPythonObject() throws(PythonError) -> PythonObject {
        let ref: UnsafePyObjectRef? = PyFloat_FromDouble(self)
        guard let ref else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return PythonObject(unsafeUnretained: ref)
    }
}
