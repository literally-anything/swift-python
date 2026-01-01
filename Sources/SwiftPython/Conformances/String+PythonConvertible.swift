/**
 * String+PythonConvertible.swift
 * Conformances
 * 
 * Created by Hunter Baker on 12/27/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

import CPython

extension StringProtocol {
    public func convertToPythonObject() throws(PythonError) -> PythonObject {
        let objectRef: UnsafePyObjectRef? = withCString { cString in
            PyUnicode_DecodeUTF8(cString, Py_ssize_t(utf8.count), "strict")
        }
        guard let objectRef else {
            try PythonError.check()
            throw PythonError.unknown
        }

        return PythonObject(unsafeUnretained: objectRef)
    }
}

extension String: PythonConvertible {
    public init(_ pythonObject: borrowing PythonObject) throws(PythonError) {
        self = try pythonObject.str()
    }
}

extension Substring: PythonConvertible {
    public init(_ pythonObject: borrowing PythonObject) throws(PythonError) {
        self = try pythonObject.str()[...]
    }
}

extension StaticString {
    public func convertToPythonObject() throws(PythonError) -> PythonObject {
        let objectRef: UnsafePyObjectRef? = PyUnicode_FromString(_cStringStart)
        guard let objectRef else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return PythonObject(unsafeUnretained: objectRef)
    }
}
