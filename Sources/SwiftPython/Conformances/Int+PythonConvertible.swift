/**
 * Int+PythonConvertible.swift
 * Conformances
 * 
 * Created by Hunter Baker on 12/27/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

import CPython

extension FixedWidthInteger {
    public init(_ pythonObject: borrowing PythonObject) throws(PythonError) {
        let numberRef: UnsafePyObjectRef? = PyNumber_Long(pythonObject.pyObject)
        guard let numberRef else {
            try PythonError.check()
            throw PythonError.unknown
        }
        let number: Py_ssize_t = PyNumber_AsSsize_t(numberRef, nil)
        self = .init(number)
    }
}

extension Int8: PythonConvertible {
    public func convertToPythonObject() throws(PythonError) -> PythonObject {
        return try Int32(self).convertToPythonObject()
    }
}
extension UInt8: PythonConvertible {
    public func convertToPythonObject() throws(PythonError) -> PythonObject {
        return try UInt32(self).convertToPythonObject()
    }
}

extension Int16: PythonConvertible {
    public func convertToPythonObject() throws(PythonError) -> PythonObject {
        return try Int32(self).convertToPythonObject()
    }
}
extension UInt16: PythonConvertible {
    public func convertToPythonObject() throws(PythonError) -> PythonObject {
        return try UInt32(self).convertToPythonObject()
    }
}

extension Int32: PythonConvertible {
    public borrowing func convertToPythonObject() throws(PythonError) -> PythonObject {
        let ref: UnsafePyObjectRef? = PyLong_FromInt32(self)
        guard let ref else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return PythonObject(unsafeUnretained: ref)
    }
}
extension UInt32: PythonConvertible {
    public borrowing func convertToPythonObject() throws(PythonError) -> PythonObject {
        let ref: UnsafePyObjectRef? = PyLong_FromUInt32(self)
        guard let ref else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return PythonObject(unsafeUnretained: ref)
    }
}

extension Int64: PythonConvertible {
    public borrowing func convertToPythonObject() throws(PythonError) -> PythonObject {
        let ref: UnsafePyObjectRef? = PyLong_FromInt64(self)
        guard let ref else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return PythonObject(unsafeUnretained: ref)
    }
}
extension UInt64: PythonConvertible {
    public borrowing func convertToPythonObject() throws(PythonError) -> PythonObject {
        let ref: UnsafePyObjectRef? = PyLong_FromUInt64(self)
        guard let ref else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return PythonObject(unsafeUnretained: ref)
    }
}

extension Int: PythonConvertible {
    public func convertToPythonObject() throws(PythonError) -> PythonObject {
        let ref: UnsafePyObjectRef? =
            if MemoryLayout<Int>.size == 8 {
                PyLong_FromInt64(Int64(self))
            } else {
                PyLong_FromInt32(Int32(self))
            }
        guard let ref else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return PythonObject(unsafeUnretained: ref)
    }
}
extension UInt: PythonConvertible {
    public func convertToPythonObject() throws(PythonError) -> PythonObject {
        let ref: UnsafePyObjectRef? =
            if MemoryLayout<UInt>.size == 8 {
                PyLong_FromUInt64(UInt64(self))
            } else {
                PyLong_FromUInt32(UInt32(self))
            }
        guard let ref else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return PythonObject(unsafeUnretained: ref)
    }
}
