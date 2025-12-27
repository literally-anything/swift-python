/**
 * Int+PythonConvertible.swift
 * Conformances
 * 
 * Created by Hunter Baker on 12/27/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

import CPython

extension Int8: PythonConvertible {
    public func _toPythonObject() throws(PythonError) -> PythonObject {
        return try Int32(self)._toPythonObject()
    }
}
extension UInt8: PythonConvertible {
    public func _toPythonObject() throws(PythonError) -> PythonObject {
        return try UInt32(self)._toPythonObject()
    }
}

extension Int16: PythonConvertible {
    public func _toPythonObject() throws(PythonError) -> PythonObject {
        return try Int32(self)._toPythonObject()
    }
}
extension UInt16: PythonConvertible {
    public func _toPythonObject() throws(PythonError) -> PythonObject {
        return try UInt32(self)._toPythonObject()
    }
}

extension Int32: PythonConvertible {
    public func _toPythonObject() throws(PythonError) -> PythonObject {
        let ref: UnsafePyObjectRef? = PyLong_FromInt32(self)
        guard let ref else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return PythonObject(unsafeUnretained: ref)
    }
}
extension UInt32: PythonConvertible {
    public func _toPythonObject() throws(PythonError) -> PythonObject {
        let ref: UnsafePyObjectRef? = PyLong_FromUInt32(self)
        guard let ref else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return PythonObject(unsafeUnretained: ref)
    }
}

extension Int64: PythonConvertible {
    public func _toPythonObject() throws(PythonError) -> PythonObject {
        let ref: UnsafePyObjectRef? = PyLong_FromInt64(self)
        guard let ref else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return PythonObject(unsafeUnretained: ref)
    }
}
extension UInt64: PythonConvertible {
    public func _toPythonObject() throws(PythonError) -> PythonObject {
        let ref: UnsafePyObjectRef? = PyLong_FromUInt64(self)
        guard let ref else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return PythonObject(unsafeUnretained: ref)
    }
}

extension Int: PythonConvertible {
    public func _toPythonObject() throws(PythonError) -> PythonObject {
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
    public func _toPythonObject() throws(PythonError) -> PythonObject {
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
