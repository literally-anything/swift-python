/**
 * Bool+PythonConvertible.swift
 * Conformances
 * 
 * Created by Hunter Baker on 12/29/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

import CPython

extension Bool: PythonConvertible {
    public init(_ pythonObject: borrowing PythonObject) throws(PythonError) {
        let ret: CInt = PyObject_IsTrue(pythonObject.pyObject)
        guard ret >= 0 else {
            try PythonError.check()
            throw PythonError.unknown
        }
        self = ret == 1
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
