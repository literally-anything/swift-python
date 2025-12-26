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
    public struct Attributes: ~Copyable, ~Escapable {
        /// The PyObject reference for the linked `PythonObject`.
        private let pyObject: UnsafePyObjectRef

        /// Make a new `Attributes` struct accessing the provided `PythonObject`.
        /// The lifetime of the instance exclusivly borrows `object`.
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
        @_disfavoredOverload
        public func contains(_ attributeName: String) -> Bool {
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
                let ret: Int32 = unsafe PyObject_GetOptionalAttrString(pyObject, attributeName._cStringStart, &attributeObjectRef)
                guard ret == 0 else {
                    return nil
                }
                // The object ref is a new strong reference, so it is already retained.
                return PythonObject(unsafeUnretained: attributeObjectRef)
            }
        }
        /// Get the `PythonObject` for the specified attribute.
        /// - Parameter attributeName: The name of the attribute to get.
        /// - Returns: A `PythonObject` is the attribute was found. `nil` otherwise.
        @_disfavoredOverload
        public subscript(_ attributeName: String) -> PythonObject? {
            get {
                var attributeObjectRef: UnsafePyObjectRef? = nil
                let ret: Int32 = unsafe attributeName.withCString { attributeNameStr in
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
                // ToDo: Add Error Tracking
                let attributeObjectRef: UnsafePyObjectRef? = unsafe PyObject_GetAttrString(pyObject, attributeName._cStringStart)
                guard let attributeObjectRef else {
                    fatalError("ToDo: Add Error Tracking")
                }
                // The object ref is a new strong reference, so it is already retained.
                return PythonObject(unsafeUnretained: attributeObjectRef)
            }
        }
        /// Get the `PythonObject` for the specified attribute and report an error if not found.
        /// - Parameter attributeName: The name of the attribute to get.
        /// - Returns: A `PythonObject` for that attribute.
        @_disfavoredOverload
        public subscript(required attributeName: String) -> PythonObject {
            get {
                let attributeObjectRef: UnsafePyObjectRef? = unsafe attributeName.withCString { attributeNameStr in
                    // ToDo: Add Error Tracking
                    unsafe PyObject_GetAttrString(pyObject, attributeNameStr)
                }
                guard let attributeObjectRef else {
                    fatalError("ToDo: Add Error Tracking")
                }
                // The object ref is a new strong reference, so it is already retained.
                return PythonObject(unsafeUnretained: attributeObjectRef)
            }
        }
    }
}
