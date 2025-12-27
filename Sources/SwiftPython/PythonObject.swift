/**
 * PythonObject.swift
 * SwiftPython
 * 
 * Created by Hunter Baker on 12/15/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

public import CPython
public import BasicContainers

/// A raw CPython PyObject reference. This type is not managed, so reference counting must be done manually.
public typealias UnsafePyObjectRef = UnsafeMutablePointer<PyObject>

/// Wraps a CPython PyObject and automatically manages python's reference counting.
/// Allows access to the members of the type using dymanic member lookup.
/// For callable types, this is dynamically callable as well.
@safe
// @dynamicCallable
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
    /// The returned reference is already retained and must be manually.
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

// Attributes
extension PythonObject {
    /// Access the attributes of the `PythonObject`.
    /// This returns a lifetime-dependent value used to temporarily access the attributes.
    public var attributes: Attributes {
        Attributes(self)
    }

    /// Check if the `PythonObject` has an attribute by name.
    /// - Parameter attributeName: The name of the attribute to test for.
    /// - Returns: `True` if the attribute exists on this `PythonObject`.
    public func hasAttribute(_ attributeName: StaticString) -> Bool {
        attributes.contains(attributeName)
    }
    /// Check if the `PythonObject` has an attribute by name.
    /// - Parameter attributeName: The name of the attribute to test for.
    /// - Returns: `True` if the attribute exists on this `PythonObject`.
    @inlinable
    @_disfavoredOverload
    public func hasAttribute(_ attributeName: some StringProtocol) -> Bool {
        attributes.contains(attributeName)
    }

    /// Dynamically lookup an attribute on the underlying python object.
    /// This is used for @dynamicMemberLookup.
    public subscript(dynamicMember member: StaticString) -> PythonObject {
        get {
            attributes[required: member]
        }
        nonmutating set(newValue) {
            attributes[member] = consume newValue
        }
    }
    /// Dynamically lookup an attribute on the underlying python object.
    /// This is used for @dynamicMemberLookup.
    @_disfavoredOverload
    public subscript(dynamicMember member: String) -> PythonObject {
        get {
            attributes[required: member]
        }
        nonmutating set(newValue) {
            attributes[member] = consume newValue
        }
    }
}

// Calling
extension PythonObject {
    /// A structure representig the pair of key and value for calling a python callable.
    /// This is a temporary solution until ~Copyable arrays can be ExpressibleByArrayLiteral.
    public struct TempKeyValuePair: ~Copyable {
        public var key: String?
        public var value: PythonObject
        
        public init(key: String? = nil, value: consuming PythonObject) {
            self.key = key
            self.value = value
        }
    }

    /// Call this python object like a function.
    /// This is a temporary solution. Once ~Copyable arrays can be ExpressibleByArrayLiteral, this will be replaced with @dynamicallyCallable.
    /// - Parameter args: The list of key value pairs for parameters.
    @discardableResult
    public func callAsFunction(_ args: borrowing RigidArray<TempKeyValuePair>) throws(PythonError) -> PythonObject? {
        fatalError("Not Implemented")
    }
    /// Call this python object like a function.
    /// This is a temporary solution. Once ~Copyable arrays can be ExpressibleByArrayLiteral, this will be replaced with @dynamicallyCallable.
    /// - Parameter args: The tuple of `PythonConvertible` arguments to pass.
    @discardableResult
    public func callAsFunction<each O>(_ args: repeat each O) throws(PythonError) -> PythonObject? where repeat each O: PythonConvertible {
        fatalError("Not Implemented")
    }

    /// Call this python object like a function.
    /// This is a temporary solution. Once ~Copyable arrays can be ExpressibleByArrayLiteral, this will be replaced with @dynamicallyCallable.
    /// - Parameter argument: The single object argument.
    @inlinable
    @discardableResult
    public func callAsFunction(_ argument: borrowing some PythonConvertible) throws(PythonError) -> PythonObject? {
        return try self.callAsFunction(argument._toPythonObject())
    }
    /// Call this python object like a function.
    /// This is a temporary solution. Once ~Copyable arrays can be ExpressibleByArrayLiteral, this will be replaced with @dynamicallyCallable.
    /// - Parameter argument: The single object argument.
    @inlinable
    @discardableResult
    public func callAsFunction(_ argument: borrowing PythonObject) throws(PythonError) -> PythonObject? {
        let objectRef: UnsafePyObjectRef? = PyObject_CallOneArg(pyObject, argument.pyObject)
        // Replace with error tracking when moved to dynamic callable
        try PythonError.check()
        let object: PythonObject? = PythonObject(unsafeUnretained: objectRef)
        if let object {
            if !object.isNone {
                return object
            }
        }
        return nil
    }

    /// Call this python object like a function.
    /// This is a temporary solution. Once ~Copyable arrays can be ExpressibleByArrayLiteral, this will be replaced with @dynamicallyCallable.
    @discardableResult
    public func callAsFunction() throws(PythonError) -> PythonObject? {
        let objectRef: UnsafePyObjectRef? = PyObject_CallNoArgs(pyObject)
        // Replace with error tracking when moved to dynamic callable
        try PythonError.check()
        let object: PythonObject? = PythonObject(unsafeUnretained: objectRef)
        if let object {
            if !object.isNone {
                return object
            }
        }
        return nil
    }

    // func dynamicallyCall(withKeywordArguments args: KeyValuePairs<String, PythonObject>) {}
}

// Equality
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
        let cString: UnsafePointer<CChar>? = PyUnicode_AsUTF8AndSize(strObjectRef, nil)
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
        let cString: UnsafePointer<CChar>? = PyUnicode_AsUTF8AndSize(strObjectRef, nil)
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
