/**
 * PythonObject.swift
 * SwiftPython
 * 
 * Created by Hunter Baker on 12/15/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

public import CPython

/// A raw CPython PyObject reference. This type is not managed, so reference counting must be done manually.
public typealias UnsafePyObjectRef = UnsafeMutablePointer<PyObject>

/// Wraps a CPython PyObject and automatically manages python's reference counting.
/// Allows access to the members of the type using dymanic member lookup.
/// For callable types, this is dynamically callable as well.
@safe
@dynamicCallable
@dynamicMemberLookup
public struct PythonObject: @unchecked Sendable, ~Copyable {
    /// The raw CPython PyObject pointer.
    /// - Note: This is only a valid reference while this `PythonObject` stays alive. Use `withExtendedLifetime` to extend it until you are done using `pyObject`.
    @unsafe
    @usableFromInline
    internal let pyObject: UnsafePyObjectRef

    /// Whether the reference count will be decremented on deinit.
    private let managed: Bool

    /// Initialize a `PythonObject` by retaining a CPython PyObject pointer.
    /// This increments the reference count of the provided `pyObject`.
    /// - Parameter pyObject: The CPython PyObject reference to retain.
    @safe
    public init(retaining pyObject: UnsafePyObjectRef) {
        unsafe Py_INCREF(pyObject)
        unsafe self.pyObject = pyObject
        self.managed = true
    }
    /// Initialize a `PythonObject` by retaining a CPython PyObject pointer.
    /// This increments the reference count of the provided `pyObject`.
    /// - Parameter pyObject: The CPython PyObject reference to retain.
    @safe
    public init?(retaining pyObject: UnsafePyObjectRef?) {
        guard let pyObject else {
            return nil
        }
        self.init(retaining: pyObject)
    }

    /// Initialize a `PythonObject` using a CPython PyObject pointer that has already been retained.
    /// This does not increment the reference count of the provided `pyObject`.
    /// - Warning: The `PythonObject` will still decrement the reference count when it goes out of scope, so the reference count must have been incremented before calling this.
    /// - Parameter pyObject: The CPython PyObject reference.
    @unsafe
    public init(unsafeUnretained pyObject: UnsafePyObjectRef) {
        unsafe self.pyObject = pyObject
        self.managed = true
    }
    /// Initialize a `PythonObject` using a CPython PyObject pointer that has already been retained.
    /// This does not increment the reference count of the provided `pyObject`.
    /// - Warning: The `PythonObject` will still decrement the reference count when it goes out of scope, so the reference count must have been incremented before calling this.
    /// - Parameter pyObject: The CPython PyObject reference.
    @unsafe
    public init?(unsafeUnretained pyObject: UnsafePyObjectRef?) {
        guard let pyObject else {
            return nil
        }
        unsafe self.init(unsafeUnretained: pyObject)
    }

    /// Initialize using an already retained PyObject reference without managing the reference count.
    /// - Warning: This does not release the reference on deinit.
    /// - Parameter pyObject: An immortal or borrowed PyObject reference that will not be managed.
    @unsafe
    public init(unsafeUnmanaged pyObject: UnsafePyObjectRef) {
        unsafe self.pyObject = pyObject
        self.managed = false
    }

    deinit {
        if managed {
            unsafe Py_DECREF(pyObject)
        }
    }
}

// General reference management functions
extension PythonObject {
    /// Make a copy of the `PythonObject` refernce and increment it's reference count.
    /// - Note: This only copys the refernce, not the actual data. It still points to the same instance.
    /// - Returns: A retained copy of this reference.
    @safe
    public func copy() -> PythonObject {
        if managed {
            PythonObject(retaining: unsafe pyObject)
        } else {
            unsafe PythonObject(unsafeUnmanaged: pyObject)
        }
    }

    /// Take the raw CPython PyObject reference and consume `self`.
    /// The returned reference is already retained and must be manually released.
    /// - Returns: The PyObject reference held by this `PythonObject`.
    @unsafe
    public consuming func take() -> UnsafePyObjectRef {
        let pyObject: UnsafePyObjectRef = unsafe self.pyObject
        discard self
        return unsafe pyObject
    }

    /// Manually retain a raw PyObject reference.
    @unsafe
    public static func retain(_ pyObject: UnsafePyObjectRef) {
        unsafe Py_INCREF(pyObject)
    }
    // Manually release a raw PyObject reference.
    @unsafe
    public static func release(_ pyObject: UnsafePyObjectRef) {
        unsafe Py_DECREF(pyObject)
    }
}

// Identity
extension PythonObject {
    /// Check if the two `PythonObjects` reference the same underlying object.
    public static func === (lhs: borrowing PythonObject, rhs: borrowing PythonObject) -> Bool {
        unsafe lhs.pyObject == rhs.pyObject
    }
}

// String Conversions
extension PythonObject {//: CustomStringConvertible, CustomDebugStringConvertible { Waiting for [SE-0499]
    /// Get the string representation of the `PythonObject`.
    /// This is equivalent to calling `str()` in python.
    public func str() throws(PythonError) -> String {
        let strObjectRef: UnsafePyObjectRef? = PyObject_Str(pyObject)
        guard let strObjectRef else {
            try PythonError.check()
            throw PythonError.unknown
        }
        let strObject: PythonObject = PythonObject(unsafeUnretained: strObjectRef)

        let cString: UnsafePointer<CChar>? = PyUnicode_AsUTF8AndSize(strObject.pyObject, nil)
        guard let cString else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return String(cString: cString)
    }
    /// Get the string representation of the `PythonObject`.
    /// This is equivalent to calling `repr()` in python.
    public func repr() throws(PythonError) -> String? {
        let strObjectRef: UnsafePyObjectRef? = PyObject_Repr(pyObject)
        guard let strObjectRef else {
            try PythonError.check()
            throw PythonError.unknown
        }
        let strObject: PythonObject = PythonObject(unsafeUnretained: strObjectRef)

        let cString: UnsafePointer<CChar>? = PyUnicode_AsUTF8AndSize(strObject.pyObject, nil)
        guard let cString else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return String(cString: cString)
    }

    public var description: String {
        (try? str()) ?? ""
    }
    public var debugDescription: String {
        (try? repr()) ?? "PythonObject()"
    }

    /// A dictionary of capabilities mapped to whether the object supports them.
    /// The capability keys are `callable`, `sequence`, `mapping`, and `iterable`.
    public var capabilities: Dictionary<String, Bool> {
        return [
            "callable": PyCallable_Check(pyObject) == 1,
            "sequence": PySequence_Check(pyObject) == 1,
            "mapping": PyMapping_Check(pyObject) == 1,
            "iterator": PyIter_Check(pyObject) != 0
        ]
    }
}
// Temporary until [SE-0499]
extension String {
    public init(describing pyObject: borrowing PythonObject) {
        self = pyObject.description
    }
    public init(reflecting pyObject: borrowing PythonObject) {
        self = pyObject.debugDescription
    }
}

// None
extension PythonObject {
    /// Checks if this python object is a reference to `None`.
    public var isNone: Bool {
        unsafe pyObject == Py_GetConstantBorrowed(0) // None constant
    }
    /// Get python `None`.
    public static var none: PythonObject {
        unsafe PythonObject(unsafeUnmanaged: Py_GetConstantBorrowed(0)) // None constant
    }
}

// Polymorphism
extension PythonObject {
    public func isInstance(of other: borrowing PythonObject) throws(PythonError) -> Bool {
        let ret: CInt = PyObject_IsInstance(pyObject, other.pyObject)
        if ret == -1 {
            try PythonError.check()
        }
        return ret == 1
    }

    public func isSubclass(of other: borrowing PythonObject) throws(PythonError) -> Bool {
        let ret: CInt = PyObject_IsSubclass(pyObject, other.pyObject)
        if ret == -1 {
            try PythonError.check()
        }
        return ret == 1
    }
}

// Other standard attributes
extension PythonObject {
    public func dir() throws(PythonError) -> PythonObject {
        let ref: UnsafePyObjectRef? = PyObject_Dir(pyObject)
        guard let ref else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return PythonObject(unsafeUnretained: ref)
    }

    public func hash() throws(PythonError) -> Py_hash_t {
        let hash: Py_hash_t = PyObject_Hash(pyObject)
        guard hash != -1 else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return hash
    }
}
