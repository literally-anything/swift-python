/*
 * Int+PythonConvertible.swift
 * SwiftPython
 * -----
 * Copyright (c) 2025 - 2026 Hunter Baker hunter@literallyanything.net
 * Licensed under the MIT License
 */

@preconcurrency import CPython

@usableFromInline
internal func _pyLongToInt64(_ ref: UnsafePyObjectRef) throws(PythonError) -> Int64? {
    guard _PyLong_Check(ref) else {
        return nil
    }

    var number: Int64 = 0
    let ret: CInt = PyLong_AsInt64(ref, &number)
    guard ret == 0 else {
        try PythonError.check()
        throw PythonError.unknown
    }
    return number
}
@usableFromInline
internal func _pyLongToUInt64(_ ref: UnsafePyObjectRef) throws(PythonError) -> UInt64? {
    guard _PyLong_Check(ref) else {
        return nil
    }

    var number: UInt64 = 0
    let ret: CInt = PyLong_AsUInt64(ref, &number)
    guard ret == 0 else {
        try PythonError.check()
        throw PythonError.unknown
    }
    return number
}

extension FixedWidthInteger where Self: PythonConvertible {
    /// Convert a `PythonObject` to a `FixedWidthInteger`.
    /// This is the same as calling `int(object)` in Python.
    /// - Parameter pythonObject: The python object to use. This does not need to be a `int`.
    /// - Throws: A `PythonError` if the conversion fails
    public init(fromPython pythonObject: borrowing PythonObject) throws(PythonError) {
        let numberRef: UnsafePyObjectRef? = PyNumber_Long(pythonObject.pyObject)
        guard let numberRef else {
            try PythonError.check()
            throw PythonError.unknown
        }
        try self.init(PythonObject(fromOwned: numberRef))
    }
}

extension SignedInteger where Self: FixedWidthInteger & PythonConvertible {
    @inlinable
    public init(_ pythonObject: borrowing PythonObject) throws(PythonError) {
        let number: Int64? = try _pyLongToInt64(pythonObject._unsafePyObjectRef)
        guard let number else {
            throw PythonError.badType(real: "\(Self.self)")
        }

        let validRange: Range<Int64> = Int64(Self.min)..<Int64(Self.max)
        guard validRange.contains(number) else {
            throw PythonError(type: PyExc_OverflowError, message: "\(number) too large to convert to \(Self.self)")
        }

        self = Self(number)
    }
}

extension UnsignedInteger where Self: FixedWidthInteger & PythonConvertible {
    @inlinable
    public init(_ pythonObject: borrowing PythonObject) throws(PythonError) {
        let number: UInt64? = try _pyLongToUInt64(pythonObject._unsafePyObjectRef)
        guard let number else {
            throw PythonError.badType(real: "\(Self.self)")
        }

        let validRange: Range<UInt64> = UInt64(Self.min)..<UInt64(Self.max)
        guard validRange.contains(number) else {
            throw PythonError(type: PyExc_OverflowError, message: "\(number) too large to convert to \(Self.self)")
        }

        self = Self(number)
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
        return PythonObject(fromOwned: ref)
    }
}
extension UInt32: PythonConvertible {
    public borrowing func convertToPythonObject() throws(PythonError) -> PythonObject {
        let ref: UnsafePyObjectRef? = PyLong_FromUInt32(self)
        guard let ref else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return PythonObject(fromOwned: ref)
    }
}

extension Int64: PythonConvertible {
    public borrowing func convertToPythonObject() throws(PythonError) -> PythonObject {
        let ref: UnsafePyObjectRef? = PyLong_FromInt64(self)
        guard let ref else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return PythonObject(fromOwned: ref)
    }
}
extension UInt64: PythonConvertible {
    public borrowing func convertToPythonObject() throws(PythonError) -> PythonObject {
        let ref: UnsafePyObjectRef? = PyLong_FromUInt64(self)
        guard let ref else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return PythonObject(fromOwned: ref)
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
        return PythonObject(fromOwned: ref)
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
        return PythonObject(fromOwned: ref)
    }
}
