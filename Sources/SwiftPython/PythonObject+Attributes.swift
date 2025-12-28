/**
 * PythonObject+Attributes.swift
 * SwiftPython
 * 
 * Created by Hunter Baker on 12/25/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

import CPython

extension PythonObject {
    /// A wrapper around the attributes of a `PythonObject`.
    @safe
    public struct Attributes: ~Escapable {
        /// The PyObject reference for the linked `PythonObject`.
        @unsafe
        @usableFromInline
        internal let pyObject: UnsafePyObjectRef

        /// Make a new `Attributes` struct accessing the provided `PythonObject`.
        /// The lifetime of the instance borrows `object`.
        @safe
        @_lifetime(borrow object)
        internal init(_ object: borrowing PythonObject) {
            unsafe self.pyObject = object.pyObject
        }

        /// Check if the `PythonObject` has an attribute by name.
        /// - Parameter attributeName: The name of the attribute to test for.
        /// - Returns: `True` if the attribute exists on this `PythonObject`.
        public func contains(_ attributeName: StaticString) -> Bool {
            let ret: CInt = unsafe PyObject_HasAttrString(pyObject, attributeName._cStringStart)
            return ret == 1
        }
        /// Check if the `PythonObject` has an attribute by name.
        /// - Parameter attributeName: The name of the attribute to test for.
        /// - Returns: `True` if the attribute exists on this `PythonObject`.
        @inlinable
        @_disfavoredOverload
        public func contains(_ attributeName: some StringProtocol) -> Bool {
            let ret: CInt = unsafe attributeName.withCString { attributeNameStr in
                unsafe PyObject_HasAttrString(pyObject, attributeNameStr)
            }
            return ret == 1
        }

        /// Get the `PythonObject` for the specified attribute.
        /// - Parameter attributeName: The name of the attribute to get.
        /// - Returns: A `PythonObject` is the attribute was found. `nil` otherwise.
        public subscript(_ attributeName: StaticString) -> PythonObject? {
            get {
                var attributeObjectRef: UnsafePyObjectRef? = nil
                let ret: CInt = unsafe PyObject_GetOptionalAttrString(pyObject, attributeName._cStringStart, &attributeObjectRef)
                guard ret == 0 else {
                    return nil
                }
                // The object ref is a new strong reference, so it is already retained.
                return PythonObject(unsafeUnretained: attributeObjectRef)
            }
            nonmutating set(newValue) {
                let ret: CInt
                if let newValue {
                    ret = PyObject_SetAttrString(pyObject, attributeName._cStringStart, newValue.pyObject)
                } else {
                    ret = PyObject_DelAttrString(pyObject, attributeName._cStringStart)
                }
                if ret != 0 {
                    PythonError.checkTracked()
                }
            }
        }
        /// Get the `PythonObject` for the specified attribute.
        /// - Parameter attributeName: The name of the attribute to get.
        /// - Returns: A `PythonObject` is the attribute was found. `nil` otherwise.
        @inlinable
        @_disfavoredOverload
        public subscript(_ attributeName: some StringProtocol) -> PythonObject? {
            get {
                var attributeObjectRef: UnsafePyObjectRef? = nil
                let ret: CInt = unsafe attributeName.withCString { attributeNameStr in
                    unsafe PyObject_GetOptionalAttrString(pyObject, attributeNameStr, &attributeObjectRef)
                }
                guard ret == 0 else {
                    return nil
                }
                // The object ref is a new strong reference, so it is already retained.
                return PythonObject(unsafeUnretained: attributeObjectRef)
            }
        }

        /// Get the `PythonObject` for the specified attribute and report an error if not found.
        /// - Parameter attributeName: The name of the attribute to get.
        /// - Returns: A `PythonObject` for that attribute.
        public subscript(required attributeName: StaticString) -> PythonObject {
            get {
                let attributeObjectRef: UnsafePyObjectRef? = unsafe PyObject_GetAttrString(pyObject, attributeName._cStringStart)
                guard let attributeObjectRef, PythonError.checkTracked() else {
                    return PythonObject.none
                }
                // The object ref is a new strong reference, so it is already retained.
                return PythonObject(unsafeUnretained: attributeObjectRef)
            }
        }
        /// Get the `PythonObject` for the specified attribute and report an error if not found.
        /// - Parameter attributeName: The name of the attribute to get.
        /// - Returns: A `PythonObject` for that attribute.
        @inlinable
        @_disfavoredOverload
        public subscript(required attributeName: some StringProtocol) -> PythonObject {
            get {
                let attributeObjectRef: UnsafePyObjectRef? = unsafe attributeName.withCString { attributeNameStr in
                    unsafe PyObject_GetAttrString(pyObject, attributeNameStr)
                }
                guard let attributeObjectRef, PythonError.checkTracked() else {
                    return PythonObject.none
                }
                // The object ref is a new strong reference, so it is already retained.
                return PythonObject(unsafeUnretained: attributeObjectRef)
            }
        }
    }

    /// A wrapper around the attributes of a `PythonObject`.
    @safe
    public struct MutableAttributes: ~Copyable, ~Escapable {
        /// The PyObject reference for the linked `PythonObject`.
        @unsafe
        @usableFromInline
        internal let pyObject: UnsafePyObjectRef

        /// Make a new `MutableAttributes` struct accessing the provided `PythonObject`.
        /// The lifetime of the instance exclusivly borrows (mutates) `object`.
        @safe
        @_lifetime(&object)
        internal init(_ object: inout PythonObject) {
            unsafe self.pyObject = object.pyObject
        }

        /// Check if the `PythonObject` has an attribute by name.
        /// - Parameter attributeName: The name of the attribute to test for.
        /// - Returns: `True` if the attribute exists on this `PythonObject`.
        public func contains(_ attributeName: StaticString) -> Bool {
            let ret: CInt = unsafe PyObject_HasAttrString(pyObject, attributeName._cStringStart)
            return ret == 1
        }
        /// Check if the `PythonObject` has an attribute by name.
        /// - Parameter attributeName: The name of the attribute to test for.
        /// - Returns: `True` if the attribute exists on this `PythonObject`.
        @inlinable
        @_disfavoredOverload
        public func contains(_ attributeName: some StringProtocol) -> Bool {
            let ret: CInt = unsafe attributeName.withCString { attributeNameStr in
                unsafe PyObject_HasAttrString(pyObject, attributeNameStr)
            }
            return ret == 1
        }

        /// Get the `PythonObject` for the specified attribute.
        /// - Parameter attributeName: The name of the attribute to get.
        /// - Returns: A `PythonObject` is the attribute was found. `nil` otherwise.
        public subscript(_ attributeName: StaticString) -> PythonObject? {
            get {
                var attributeObjectRef: UnsafePyObjectRef? = nil
                let ret: CInt = unsafe PyObject_GetOptionalAttrString(pyObject, attributeName._cStringStart, &attributeObjectRef)
                guard ret == 0 else {
                    return nil
                }
                // The object ref is a new strong reference, so it is already retained.
                return PythonObject(unsafeUnretained: attributeObjectRef)
            }

            @_lifetime(self: copy self)
            set(newValue) {
                let ret: CInt
                if let newValue {
                    ret = PyObject_SetAttrString(pyObject, attributeName._cStringStart, newValue.pyObject)
                } else {
                    ret = PyObject_DelAttrString(pyObject, attributeName._cStringStart)
                }
                if ret != 0 {
                    PythonError.checkTracked()
                }
            }
        }
        /// Get the `PythonObject` for the specified attribute.
        /// - Parameter attributeName: The name of the attribute to get.
        /// - Returns: A `PythonObject` is the attribute was found. `nil` otherwise.
        @inlinable
        @_disfavoredOverload
        public subscript(_ attributeName: some StringProtocol) -> PythonObject? {
            get {
                var attributeObjectRef: UnsafePyObjectRef? = nil
                let ret: CInt = unsafe attributeName.withCString { attributeNameStr in
                    unsafe PyObject_GetOptionalAttrString(pyObject, attributeNameStr, &attributeObjectRef)
                }
                guard ret == 0 else {
                    return nil
                }
                // The object ref is a new strong reference, so it is already retained.
                return PythonObject(unsafeUnretained: attributeObjectRef)
            }

            @_lifetime(self: copy self)
            set(newValue) {
                let ret: CInt
                if let newValue {
                    ret = attributeName.withCString { attributeNameStr in
                        PyObject_SetAttrString(pyObject, attributeNameStr, newValue.pyObject)
                    }
                } else {
                    ret = attributeName.withCString { attributeNameStr in
                        PyObject_DelAttrString(pyObject, attributeNameStr)
                    }
                }
                if ret != 0 {
                    PythonError.checkTracked()
                }
            }
        }

        /// Get the `PythonObject` for the specified attribute and report an error if not found.
        /// - Parameter attributeName: The name of the attribute to get.
        /// - Returns: A `PythonObject` for that attribute.
        public subscript(required attributeName: StaticString) -> PythonObject {
            get {
                let attributeObjectRef: UnsafePyObjectRef? = unsafe PyObject_GetAttrString(pyObject, attributeName._cStringStart)
                guard let attributeObjectRef, PythonError.checkTracked() else {
                    return PythonObject.none
                }
                // The object ref is a new strong reference, so it is already retained.
                return PythonObject(unsafeUnretained: attributeObjectRef)
            }
        }
        /// Get the `PythonObject` for the specified attribute and report an error if not found.
        /// - Parameter attributeName: The name of the attribute to get.
        /// - Returns: A `PythonObject` for that attribute.
        @inlinable
        @_disfavoredOverload
        public subscript(required attributeName: some StringProtocol) -> PythonObject {
            get {
                let attributeObjectRef: UnsafePyObjectRef? = unsafe attributeName.withCString { attributeNameStr in
                    unsafe PyObject_GetAttrString(pyObject, attributeNameStr)
                }
                guard let attributeObjectRef, PythonError.checkTracked() else {
                    return PythonObject.none
                }
                // The object ref is a new strong reference, so it is already retained.
                return PythonObject(unsafeUnretained: attributeObjectRef)
            }
        }
    }
}

// Attributes
extension PythonObject {
    /// Access the attributes of the `PythonObject`.
    /// This returns a lifetime-dependent value used to temporarily access the attributes.
    public var attributes: Attributes {
        Attributes(self)
    }

    /// Mutable access the attributes of the `PythonObject`.
    /// This returns a lifetime-dependent value used to temporarily access the attributes.
    public var mutableAttributes: MutableAttributes {
        @_lifetime(&self)
        mutating get {
            MutableAttributes(&self)
        }
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
        set(newValue) {
            var attrs = mutableAttributes
            attrs[member] = consume newValue
        }
    }
    /// Dynamically lookup an attribute on the underlying python object.
    /// This is used for @dynamicMemberLookup.
    @_disfavoredOverload
    public subscript(dynamicMember member: String) -> PythonObject {
        get {
            attributes[required: member]
        }
        set(newValue) {
            var attrs = mutableAttributes
            attrs[member] = consume newValue
        }
    }
}
