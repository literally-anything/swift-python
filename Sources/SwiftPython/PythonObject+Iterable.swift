/**
 * PythonObject+Iterable.swift
 * SwiftPython
 * 
 * Created by Hunter Baker on 12/31/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

@preconcurrency import CPython

/// An iterator to allow `PythonObject`s to be iterated in a for loop.
/// This is accessed through the `object.iterable` api on a `PythonObject`.
public struct PythonObjectIterator<Element: PythonConvertible & Copyable>: IteratorProtocol {
    // ToDo: This could be made ~Escapable when IteratorProtocol and Sequence allow them.

    /// Stores a noncopyable `PythonObject` in a heap-allocated ref-counted box for iteration.
    @usableFromInline
    internal final class IterableBox {
        /// The contained `PythonObject` that is iterable.
        private let iterable: PythonObject

        /// Create a new `IterableBox` by consuming a `PythonObject`.
        /// This is assumed to already be compatible with Python's iterator protocol.
        init(_ iterable: consuming PythonObject) {
            self.iterable = iterable
        }

        /// Get the next element in the sequence.
        @usableFromInline
        internal func next() throws(PythonError) -> PythonObject? {
            var nextRef: UnsafePyObjectRef? = nil
            let ret: CInt = PyIter_NextItem(iterable.pyObject, &nextRef)
            if ret < 0 {
                try PythonError.check()
            }

            let nextObject = PythonObject(unsafeUnretained: nextRef)
            if ret == 1, let nextObject {
                return nextObject
            }

            return nil
        }
    }

    /// The heap box that holds the noncopyable reference to allow copys.
    @usableFromInline
    internal var box: IterableBox

    /// Initialize a `PythonObjectIterator` for the passed iterable.
    @usableFromInline
    internal init(_ iterable: borrowing PythonObject) throws(PythonError) {
        let isIterator: Bool = PyIter_Check(iterable.pyObject) != 0
        if isIterator {
            self.box = IterableBox(iterable.copy())
        } else {
            let iteratorRef: UnsafePyObjectRef? = PyObject_GetIter(iterable.pyObject)
            let iterator: PythonObject? = PythonObject(unsafeUnretained: iteratorRef)
            guard let iterator else {
                try PythonError.check()
                throw PythonError(type: PyExc_TypeError, message: "The PythonObject is not iterable")
            }
            self.box = IterableBox(iterator)
        }
    }

    @inlinable
    public func next() -> Element? {
        do throws(PythonError) {
            let pythonObject = try box.next()
            if let pythonObject {
                return try Element(pythonObject)
            }
        } catch let error {
            PythonError.trackError(error: error)
        }
        return nil
    }
}

@available(*, unavailable)
extension PythonObjectIterator: Sendable {}

extension PythonObject {
    /// Gets an iterable view of the `PythonObject` as a sequence.
    /// This allows python collections to be used in for loops.
    /// - Parameter type: The element type.
    /// - Throws: `PythonError` if the object does not support the iterator protocol.
    /// - Returns: An opaque `Sequence` that allows iteration.
    @inlinable
    public func iterable<Element: PythonConvertible & Copyable>(
        type: Element.Type
    ) throws(PythonError) -> some Sequence {
        return IteratorSequence(
            try PythonObjectIterator<Element>(self)
        )
    }
}
