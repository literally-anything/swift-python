/**
 * Bool+PythonConvertible.swift
 * Conformances
 * 
 * Created by Hunter Baker on 12/29/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

import CPython

extension Bool: PythonConvertible {
    /// Convert a `PythonObject` to a `Bool`.
    /// This is the same as calling `bool(object)` in Python.
    /// - Parameter pythonObject: The python object to use. This does not need to be a `bool`.
    /// - Throws: A `PythonError` if the conversion fails
    public init(fromPython pythonObject: borrowing PythonObject) throws(PythonError) {
        let ret: CInt = PyObject_IsTrue(pythonObject.pyObject)
        guard ret >= 0 else {
            try PythonError.check()
            throw PythonError.unknown
        }
        self = ret == 1
    }

    public init(_ pythonObject: borrowing PythonObject) throws(PythonError) {
        // Require a real `bool`
        guard _PyBool_Check(pythonObject.pyObject) else {
            throw PythonError.badType(real: "Bool")
        }

        try self.init(fromPython: pythonObject)
    }

    public borrowing func convertToPythonObject() throws(PythonError) -> PythonObject {
        let integerRepr: CLong
        if self == true { // Weird crash when using just `self` as the condition for if or a ternary.
            integerRepr = 1
        } else {
            integerRepr = 0
        }
        let boolRef: UnsafePyObjectRef? = PyBool_FromLong(integerRepr)
        guard let boolRef else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return PythonObject(unsafeUnretained: boolRef)
    }
}
