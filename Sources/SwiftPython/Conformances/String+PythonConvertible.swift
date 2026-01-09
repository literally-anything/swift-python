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
    /// Convert a `PythonObject` to a `String`.
    /// This is the same as calling `str(object)` in Python.
    /// - Parameter pythonObject: The python object to use. This does not need to be a `str`.
    /// - Throws: A `PythonError` if the conversion fails
    public init(fromPython pythonObject: borrowing PythonObject) throws(PythonError) {
        self = try pythonObject.str()
    }

    public init(_ pythonObject: borrowing PythonObject) throws(PythonError) {
        guard _PyUnicode_Check(pythonObject.pyObject) else {
            throw PythonError.badType(real: "String")
        }

        let cString: UnsafePointer<CChar>? = PyUnicode_AsUTF8AndSize(pythonObject.pyObject, nil)
        guard let cString else {
            try PythonError.check()
            throw PythonError.unknown
        }
        self.init(cString: cString)
    }
}

extension Substring: PythonConvertible {
    public init(_ pythonObject: borrowing PythonObject) throws(PythonError) {
        self = try String(pythonObject)[...]
    }
}

// Special case because it cannot be initialized from a PythonObject, but it can convert into one.
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
