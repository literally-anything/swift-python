/**
 * PythonObject+Conversions.swift
 * SwiftPython
 * 
 * Created by Hunter Baker on 12/26/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

import CPython

extension Bool {
    public init(_ pythonObject: borrowing PythonObject) {
        self = PyObject_IsTrue(pythonObject.pyObject) == 1
    }
}

extension String {
    public init(_ pythonObject: borrowing PythonObject) throws(PythonError) {
        self = try pythonObject.str()
    }
}

extension FixedWidthInteger {
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
