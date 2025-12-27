/**
 * String+PythonConvertible.swift
 * Conformances
 * 
 * Created by Hunter Baker on 12/27/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

import CPython

extension String: PythonConvertible {
    public func _toPythonObject() throws(PythonError) -> PythonObject {
        let objectRef: UnsafePyObjectRef? = withCString { cString in
            PyUnicode_FromString(cString)
        }
        guard let objectRef else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return PythonObject(unsafeUnretained: objectRef)
    }
}

extension Substring: PythonConvertible {
    public func _toPythonObject() throws(PythonError) -> PythonObject {
        let objectRef: UnsafePyObjectRef? = withCString { cString in
            PyUnicode_FromString(cString)
        }
        guard let objectRef else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return PythonObject(unsafeUnretained: objectRef)
    }
}

extension StaticString: PythonConvertible {
    public func _toPythonObject() throws(PythonError) -> PythonObject {
        let objectRef: UnsafePyObjectRef? = PyUnicode_FromString(_cStringStart)
        guard let objectRef else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return PythonObject(unsafeUnretained: objectRef)
    }
}
