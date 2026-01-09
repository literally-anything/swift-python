/**
 * Double+PythonConvertible.swift
 * Conformances
 * 
 * Created by Hunter Baker on 12/27/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

import CPython

extension BinaryFloatingPoint {
    /// Convert a `PythonObject` to a `BinaryFloatingPoint`.
    /// This is the same as calling `float(object)` in Python.
    /// - Parameter pythonObject: The python object to use. This does not need to be a `float`.
    /// - Throws: A `PythonError` if the conversion fails
    public init(fromPython pythonObject: borrowing PythonObject) throws(PythonError) {
        let floatRef: UnsafePyObjectRef? = PyNumber_Float(pythonObject.pyObject)
        guard let floatRef else {
            try PythonError.check()
            throw PythonError.unknown
        }
        try self.init(PythonObject(unsafeUnretained: floatRef))
    }

    public init(_ pythonObject: borrowing PythonObject) throws(PythonError) {
        guard _PyFloat_Check(pythonObject.pyObject) else {
            throw PythonError.badType(real: "\(Self.self)")
        }

        let doubleValue: Double = PyFloat_AsDouble(pythonObject.pyObject)
        try PythonError.check()
        self = Self(doubleValue)
    }
}

extension Float16: PythonConvertible {
    public borrowing func convertToPythonObject() throws(PythonError) -> PythonObject {
        return try Double(self).convertToPythonObject()
    }
}

extension Float: PythonConvertible {
    public borrowing func convertToPythonObject() throws(PythonError) -> PythonObject {
        return try Double(self).convertToPythonObject()
    }
}

extension Double: PythonConvertible {
    public borrowing func convertToPythonObject() throws(PythonError) -> PythonObject {
        let floatRef: UnsafePyObjectRef? = PyFloat_FromDouble(self)
        guard let floatRef else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return PythonObject(unsafeUnretained: floatRef)
    }
}
