/**
 * PythonObject+Operators.swift
 * SwiftPython
 * 
 * Created by Hunter Baker on 12/26/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

import CPython

// Equality
extension PythonObject { // : Equatable { Waiting for [SE-0499]
    public static func == (lhs: borrowing PythonObject, rhs: borrowing PythonObject) -> Bool {
        let ret: CInt = PyObject_RichCompareBool(lhs.pyObject, rhs.pyObject, Py_EQ)
        guard ret >= 0 || PythonError.checkTracked() else {
            return false
        }
        return ret == 1
    }
    public static func != (lhs: borrowing PythonObject, rhs: borrowing PythonObject) -> Bool {
        let ret: CInt = PyObject_RichCompareBool(lhs.pyObject, rhs.pyObject, Py_NE)
        guard ret >= 0 || PythonError.checkTracked() else {
            return false
        }
        return ret == 1
    }
}

// Comparisons
extension PythonObject {
    public static func > (lhs: borrowing PythonObject, rhs: borrowing PythonObject) -> Bool {
        let ret: CInt = PyObject_RichCompareBool(lhs.pyObject, rhs.pyObject, Py_GT)
        guard ret >= 0 || PythonError.checkTracked() else {
            return false
        }
        return ret == 1
    }
    public static func >= (lhs: borrowing PythonObject, rhs: borrowing PythonObject) -> Bool {
        let ret: CInt = PyObject_RichCompareBool(lhs.pyObject, rhs.pyObject, Py_GE)
        guard ret >= 0 || PythonError.checkTracked() else {
            return false
        }
        return ret == 1
    }
    public static func < (lhs: borrowing PythonObject, rhs: borrowing PythonObject) -> Bool {
        let ret: CInt = PyObject_RichCompareBool(lhs.pyObject, rhs.pyObject, Py_LT)
        guard ret >= 0 || PythonError.checkTracked() else {
            return false
        }
        return ret == 1
    }
    public static func <= (lhs: borrowing PythonObject, rhs: borrowing PythonObject) -> Bool {
        let ret: CInt = PyObject_RichCompareBool(lhs.pyObject, rhs.pyObject, Py_LE)
        guard ret >= 0 || PythonError.checkTracked() else {
            return false
        }
        return ret == 1
    }
}

// Arithmatic
extension PythonObject {
    public static func + (lhs: borrowing PythonObject, rhs: borrowing PythonObject) -> PythonObject {
        let outputRef: UnsafePyObjectRef? = PyNumber_Add(lhs.pyObject, rhs.pyObject)
        guard let outputRef else {
            PythonError.checkTracked()
            return .none
        }
        return PythonObject(unsafeUnretained: outputRef)
    }
    public static func - (lhs: borrowing PythonObject, rhs: borrowing PythonObject) -> PythonObject {
        let outputRef: UnsafePyObjectRef? = PyNumber_Subtract(lhs.pyObject, rhs.pyObject)
        guard let outputRef else {
            PythonError.checkTracked()
            return .none
        }
        return PythonObject(unsafeUnretained: outputRef)
    }
    public static func * (lhs: borrowing PythonObject, rhs: borrowing PythonObject) -> PythonObject {
        let outputRef: UnsafePyObjectRef? = PyNumber_Multiply(lhs.pyObject, rhs.pyObject)
        guard let outputRef else {
            PythonError.checkTracked()
            return .none
        }
        return PythonObject(unsafeUnretained: outputRef)
    }
    public static func matMult(lhs: borrowing PythonObject, rhs: borrowing PythonObject) -> PythonObject {
        let outputRef: UnsafePyObjectRef? = PyNumber_MatrixMultiply(lhs.pyObject, rhs.pyObject)
        guard let outputRef else {
            PythonError.checkTracked()
            return .none
        }
        return PythonObject(unsafeUnretained: outputRef)
    }
    public static func / (lhs: borrowing PythonObject, rhs: borrowing PythonObject) -> PythonObject {
        let outputRef: UnsafePyObjectRef? = PyNumber_TrueDivide(lhs.pyObject, rhs.pyObject)
        guard let outputRef else {
            PythonError.checkTracked()
            return .none
        }
        return PythonObject(unsafeUnretained: outputRef)
    }
    public static func % (lhs: borrowing PythonObject, rhs: borrowing PythonObject) -> PythonObject {
        let outputRef: UnsafePyObjectRef? = PyNumber_Remainder(lhs.pyObject, rhs.pyObject)
        guard let outputRef else {
            PythonError.checkTracked()
            return .none
        }
        return PythonObject(unsafeUnretained: outputRef)
    }
}

// Negation
extension PythonObject {
    public static prefix func + (object: borrowing PythonObject) -> PythonObject {
        let outputRef: UnsafePyObjectRef? = PyNumber_Positive(object.pyObject)
        guard let outputRef else {
            PythonError.checkTracked()
            return .none
        }
        return PythonObject(unsafeUnretained: outputRef)
    }
    public static prefix func - (object: borrowing PythonObject) -> PythonObject {
        let outputRef: UnsafePyObjectRef? = PyNumber_Negative(object.pyObject)
        guard let outputRef else {
            PythonError.checkTracked()
            return .none
        }
        return PythonObject(unsafeUnretained: outputRef)
    }
}

// Bitwise
extension PythonObject {
    public static prefix func ~ (object: borrowing PythonObject) -> PythonObject {
        let outputRef: UnsafePyObjectRef? = PyNumber_Invert(object.pyObject)
        guard let outputRef else {
            PythonError.checkTracked()
            return .none
        }
        return PythonObject(unsafeUnretained: outputRef)
    }
    public static func << (lhs: borrowing PythonObject, rhs: borrowing PythonObject) -> PythonObject {
        let outputRef: UnsafePyObjectRef? = PyNumber_Lshift(lhs.pyObject, rhs.pyObject)
        guard let outputRef else {
            PythonError.checkTracked()
            return .none
        }
        return PythonObject(unsafeUnretained: outputRef)
    }
    public static func >> (lhs: borrowing PythonObject, rhs: borrowing PythonObject) -> PythonObject {
        let outputRef: UnsafePyObjectRef? = PyNumber_Rshift(lhs.pyObject, rhs.pyObject)
        guard let outputRef else {
            PythonError.checkTracked()
            return .none
        }
        return PythonObject(unsafeUnretained: outputRef)
    }
    public static func & (lhs: borrowing PythonObject, rhs: borrowing PythonObject) -> PythonObject {
        let outputRef: UnsafePyObjectRef? = PyNumber_And(lhs.pyObject, rhs.pyObject)
        guard let outputRef else {
            PythonError.checkTracked()
            return .none
        }
        return PythonObject(unsafeUnretained: outputRef)
    }
    public static func | (lhs: borrowing PythonObject, rhs: borrowing PythonObject) -> PythonObject {
        let outputRef: UnsafePyObjectRef? = PyNumber_Or(lhs.pyObject, rhs.pyObject)
        guard let outputRef else {
            PythonError.checkTracked()
            return .none
        }
        return PythonObject(unsafeUnretained: outputRef)
    }
    public static func ^ (lhs: borrowing PythonObject, rhs: borrowing PythonObject) -> PythonObject {
        let outputRef: UnsafePyObjectRef? = PyNumber_Xor(lhs.pyObject, rhs.pyObject)
        guard let outputRef else {
            PythonError.checkTracked()
            return .none
        }
        return PythonObject(unsafeUnretained: outputRef)
    }
}

// In-place arithmatic
extension PythonObject {
    public static func += (lhs: inout PythonObject, rhs: borrowing PythonObject) {
        let outputRef: UnsafePyObjectRef? = PyNumber_InPlaceAdd(lhs.pyObject, rhs.pyObject)
        guard let outputRef else {
            PythonError.checkTracked()
            return
        }
        lhs = PythonObject(unsafeUnretained: outputRef)
    }
    public static func -= (lhs: inout PythonObject, rhs: borrowing PythonObject) {
        let outputRef: UnsafePyObjectRef? = PyNumber_InPlaceSubtract(lhs.pyObject, rhs.pyObject)
        guard let outputRef else {
            PythonError.checkTracked()
            return
        }
        lhs = PythonObject(unsafeUnretained: outputRef)
    }
    public static func *= (lhs: inout PythonObject, rhs: borrowing PythonObject) {
        let outputRef: UnsafePyObjectRef? = PyNumber_InPlaceMultiply(lhs.pyObject, rhs.pyObject)
        guard let outputRef else {
            PythonError.checkTracked()
            return
        }
        lhs = PythonObject(unsafeUnretained: outputRef)
    }
    public static func /= (lhs: inout PythonObject, rhs: borrowing PythonObject) {
        let outputRef: UnsafePyObjectRef? = PyNumber_InPlaceTrueDivide(lhs.pyObject, rhs.pyObject)
        guard let outputRef else {
            PythonError.checkTracked()
            return
        }
        lhs = PythonObject(unsafeUnretained: outputRef)
    }
}

// Sequence
extension PythonObject {
    public var length: Py_ssize_t {
        get throws(PythonError) {
            let ret: Py_ssize_t = PyObject_Length(pyObject)
            guard ret >= 0 else {
                try PythonError.check()
                throw PythonError.unknown
            }
            return ret
        }
    }

    public func asList() throws(PythonError) -> PythonObject {
        let ref: UnsafePyObjectRef? = PySequence_List(pyObject)
        guard let ref else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return PythonObject(unsafeUnretained: ref)
    }
    public func asTuple() throws(PythonError) -> PythonObject {
        let ref: UnsafePyObjectRef? = PySequence_Tuple(pyObject)
        guard let ref else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return PythonObject(unsafeUnretained: ref)
    }

    public func contains(_ item: borrowing PythonObject) throws(PythonError) -> Bool {
        let ret: CInt = PySequence_Contains(pyObject, item.pyObject)
        guard ret >= 0 else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return ret == 1
    }

    public func index(of item: borrowing PythonObject) throws(PythonError) -> Py_ssize_t {
        let index: Py_ssize_t = PySequence_Index(pyObject, item.pyObject)
        guard index >= 0 else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return index
    }

    public func count(of item: borrowing PythonObject) throws(PythonError) -> Py_ssize_t {
        let count: Py_ssize_t = PySequence_Count(pyObject, item.pyObject)
        guard count >= 0 else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return count
    }

    subscript(_ index: Py_ssize_t) -> PythonObject {
        get {
            let itemRef: UnsafePyObjectRef? = PySequence_GetItem(pyObject, index)
            guard let itemRef else {
                PythonError.checkTracked()
                return .none
            }
            return PythonObject(unsafeUnretained: itemRef)
        }
    }
    subscript(_ index: Py_ssize_t) -> PythonObject? {
        @available(*, unavailable)
        get { fatalError("Unreachable") }
        set(newValue) {
            let ret: CInt
            if let newValue {
                ret = PySequence_SetItem(pyObject, index, newValue.pyObject)
            } else {
                ret = PySequence_DelItem(pyObject, index)
            }
            guard ret == 0 else {
                PythonError.checkTracked()
                return
            }
        }
    }

    public var indices: Range<Int> {
        let length: Py_ssize_t = PyObject_Length(pyObject)
        guard length >= 0 else {
            PythonError.checkTracked()
            return Range(uncheckedBounds: (lower: 0, upper: 0))
        }
        return Range(uncheckedBounds: (lower: 0, upper: Int(length)))
    }

    @usableFromInline
    internal subscript(listSlice sliceRange: Range<Int>) -> PythonObject {
        get {
            let itemRef: UnsafePyObjectRef? = PySequence_GetSlice(pyObject, sliceRange.lowerBound, sliceRange.upperBound)
            guard let itemRef else {
                PythonError.checkTracked()
                return .none
            }
            return PythonObject(unsafeUnretained: itemRef)
        }
        set(newValue) {
            let ret: CInt = PySequence_SetSlice(pyObject, sliceRange.lowerBound, sliceRange.upperBound, newValue.pyObject)
            guard ret == 0 else {
                PythonError.checkTracked()
                return
            }
        }
    }

    @inlinable
    public subscript(_ slice: some RangeExpression<Int>) -> PythonObject {
        get {
            let sliceRange = slice.relative(to: indices)
            return self[listSlice: sliceRange]
        }
        set(newValue) {
            let sliceRange = slice.relative(to: indices)
            self[listSlice: sliceRange] = newValue
        }
    }

    @inlinable
    public subscript<T: PythonConvertible & ~Copyable>(_ slice: some RangeExpression<Int>) -> T? {
        get {
            let sliceRange = slice.relative(to: indices)
            let pythonObject = self[listSlice: sliceRange]

            do {
                return try T(pythonObject)
            } catch let error {
                _ = PythonError.toTracked { () throws(PythonError) in throw error }
                return nil
            }
        }
    }
    @inlinable
    public subscript<T: PythonConvertible>(_ slice: some RangeExpression<Int>) -> T {
        @available(*, unavailable)
        get { fatalError("Unreachable") }
        set(newValue) {
            let sliceRange = slice.relative(to: indices)

            // ToDo: Make this work with ~Copyable types
            let pythonObject = PythonError.toTracked { () throws(PythonError) in try newValue._toPythonObject() }
            guard let pythonObject else { return }
            self[listSlice: sliceRange] = pythonObject
        }
    }
}

// Mapping
extension PythonObject {
    public func hasValue(for key: String) -> Bool {
        hasValue(key: key)
    }
    public func hasValue(for key: some StringProtocol) -> Bool {
        hasValue(key: key)
    }
    private func hasValue(key: some StringProtocol) -> Bool {
        let ret: CInt = key.withCString { keyCString in
            PyMapping_HasKeyString(pyObject, keyCString)
        }
        return ret == 1
    }

    public func keys() throws(PythonError) -> PythonObject {
        let ref: UnsafePyObjectRef? = PyMapping_Keys(pyObject)
        guard let ref else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return PythonObject(unsafeUnretained: ref)
    }
    public func values() throws(PythonError) -> PythonObject {
        let ref: UnsafePyObjectRef? = PyMapping_Values(pyObject)
        guard let ref else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return PythonObject(unsafeUnretained: ref)
    }
    public func items() throws(PythonError) -> PythonObject {
        let ref: UnsafePyObjectRef? = PyMapping_Items(pyObject)
        guard let ref else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return PythonObject(unsafeUnretained: ref)
    }

    public subscript(_ key: String) -> PythonObject? {
        self[key: key]
    }
    @inlinable
    public subscript(_ key: some StringProtocol) -> PythonObject? {
        self[key: key]
    }

    @inlinable
    internal subscript(key key: some StringProtocol) -> PythonObject? {
        get {
            var resultRef: UnsafePyObjectRef? = nil
            let ret: CInt = key.withCString { keyCString in
                PyMapping_GetOptionalItemString(pyObject, keyCString, &resultRef)
            }
            guard ret >= 0 else {
                PythonError.checkTracked()
                return PythonObject.none
            }
            return PythonObject(unsafeUnretained: resultRef)
        }
        set(newValue) {
            let ret: CInt
            if let newValue {
                ret = key.withCString { keyCString in
                    PyMapping_SetItemString(pyObject, keyCString, newValue.pyObject)
                }
            } else {
                ret = key.withCString { keyCString in
                    PyObject_DelItemString(pyObject, keyCString)
                }
            }
            guard ret == 0 else {
                PythonError.checkTracked()
                return
            }
        }
    }

    @inlinable
    public subscript<T: PythonConvertible>(_ key: String) -> T? {
        get {
            return self[key: key]
        }
        set(newValue) {
            self[key: key] = newValue
        }
    }
    @inlinable
    public subscript<T: PythonConvertible>(_ key: some StringProtocol) -> T? {
        get {
            return self[key: key]
        }
        set(newValue) {
            self[key: key] = newValue
        }
    }

    @inlinable
    internal subscript<T: PythonConvertible>(key key: some StringProtocol) -> T? {
        get {
            let pythonObject = self[key: key]
            guard let pythonObject else {
                return nil
            }

            do {
                return try T(pythonObject)
            } catch let error {
                _ = PythonError.toTracked { () throws(PythonError) in throw error }
                return nil
            }
        }
        set(newValue) {
            // ToDo: Make this work with ~Copyable types
            let pythonObject = PythonError.toTracked { () throws(PythonError) in try newValue._toPythonObject() }
            guard let pythonObject else { return }
            self[key: key] = consume pythonObject
        }
    }
}
