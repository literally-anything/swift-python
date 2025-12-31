/**
 * PythonObject+Callable.swift
 * SwiftPython
 * 
 * Created by Hunter Baker on 12/28/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

import CPython
public import BasicContainers

extension PythonObject {
    @safe
    public struct Callable: ~Escapable {
        /// The PyObject reference for the linked `PythonObject`.
        @unsafe
        @usableFromInline
        internal let pyObject: UnsafePyObjectRef

        /// Make a new `Callable` struct accessing the provided `PythonObject`.
        /// The lifetime of the instance borrows `object`.
        @safe
        @_lifetime(borrow object)
        internal init(_ object: borrowing PythonObject) {
            unsafe self.pyObject = object.pyObject
        }

        /// Whther the referenced object is callable or not.
        ///
        /// If this is `false`, attempts to call it will result in a `PythonError`.
        public var isCallable: Bool {
            PyCallable_Check(pyObject) == 1
        }
    }
}

// No Arguments
extension PythonObject.Callable {
    /// Call the callable without any arguments.
    /// - Throws: `PythonError` if there was an issue calling or if an error occurred during execution.
    /// - Returns: The output `PythonObject` or `nil` if there was none.
    @discardableResult
    public func call() throws(PythonError) -> PythonObject? {
        let returnRef: UnsafePyObjectRef? = PyObject_CallNoArgs(pyObject)
        let returnValue: PythonObject? = PythonObject(unsafeUnretained: returnRef)
        guard let returnValue else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return PythonObject?(optional: returnValue)
    }
}

// One Argument
extension PythonObject.Callable {
    /// Call the callable with one argument.
    /// - Parameter argument: The argument to the callable.
    /// - Throws: `PythonError` if there was an issue calling or if an error occurred during execution.
    /// - Returns: The output `PythonObject` or `nil` if there was none.
    @discardableResult
    public func call(argument: inout PythonObject) throws(PythonError) -> PythonObject? {
        let returnRef: UnsafePyObjectRef? = PyObject_CallOneArg(pyObject, argument.pyObject)
        let returnValue: PythonObject? = PythonObject(unsafeUnretained: returnRef)
        guard let returnValue else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return PythonObject?(optional: returnValue)
    }
    /// Call the callable with one argument.
    /// - Parameter argument: The argument to the callable.
    /// - Throws: `PythonError` if there was an issue calling or if an error occurred during execution.
    /// - Returns: The output `PythonObject` or `nil` if there was none.
    @inlinable
    @discardableResult
    @_disfavoredOverload
    public func call<T: PythonConvertible & ~Copyable>(argument: consuming T) throws(PythonError) -> PythonObject? {
        var pythonArgument = try argument._toPythonObject()
        return try call(argument: &pythonArgument)
    }
    /// Call the callable with one argument.
    /// - Parameter argument: The mutable argument to the callable.
    /// - Throws: `PythonError` if there was an issue calling or if an error occurred during execution.
    /// - Returns: The output `PythonObject` or `nil` if there was none.
    @inlinable
    @discardableResult
    @_disfavoredOverload
    public func call<T: PythonConvertible>(argument: inout T) throws(PythonError) -> PythonObject? {
        var pythonArgument = try argument._toPythonObject()
        let output: PythonObject? = try call(argument: &pythonArgument)

        // Update the argument with any changes
        argument = try! T(pythonArgument)

        return output
    }
}

// Multiple Arguments
extension PythonObject.Callable {
    @discardableResult
    public func call(
        arguments: inout RigidArray<PythonObject>,
        keywordArguments: inout RigidArray<PythonObject>,
        keywords: borrowing Array<String>
    ) throws(PythonError) -> PythonObject? {
        // Retain arguments to the end
        defer {
            withExtendedLifetime(arguments) {}
            withExtendedLifetime(keywordArguments) {}
        }

        // Shortcuts for simple calls
        if keywordArguments.isEmpty {
            if arguments.isEmpty {
                return try call()
            } else if arguments.count == 1 {
                return try call(argument: &arguments[0])
            }
        }

        // Prep arguments
        let keywordsTuple = try pythonTuple(from: keywords)
        let argumentRefs: RigidArray<UnsafePyObjectRef?> = RigidArray<UnsafePyObjectRef?>(
            capacity: arguments.count
        ) { contents in
            for index in arguments.indices {
                contents.append(arguments[index].pyObject)
            }
            for index in keywordArguments.indices {
                contents.append(keywordArguments[index].pyObject)
            }
        }

        let returnRef = argumentRefs.span.withUnsafeBufferPointer { argumentsBuffer in
            PyObject_Vectorcall(pyObject, argumentsBuffer.baseAddress, arguments.count, keywordsTuple.pyObject)
        }
        let returnValue: PythonObject? = PythonObject(unsafeUnretained: returnRef)
        guard let returnValue else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return PythonObject?(optional: returnValue)
    }
    @discardableResult
    public func call(arguments: inout RigidArray<PythonObject>) throws(PythonError) -> PythonObject? {
        var keywordArguments = RigidArray<PythonObject>()
        return try call(arguments: &arguments, keywordArguments: &keywordArguments, keywords: Array<String>())
    }
    @discardableResult
    public func call(keywordArguments: inout RigidArray<PythonObject>, keywords: borrowing Array<String>) throws(PythonError) -> PythonObject? {
        var arguments = RigidArray<PythonObject>()
        return try call(arguments: &arguments, keywordArguments: &keywordArguments, keywords: keywords)
    }

    /// A structure representig the pair of a swift string keyword and a swift argument for calling a python callable.
    /// This is a temporary solution until noncopyable tuples work.
    // public struct SwiftKeywordArgumentPair: ~Copyable {
    //     public let keyword: String
    //     public let argument: any PythonConvertible & ~Copyable

    //     public init(keyword: String, argument: consuming any PythonConvertible & ~Copyable) {
    //         self.keyword = keyword
    //         self.argument = argument
    //     }
    // }

    // @discardableResult
    // public func call(
    //     arguments: consuming RigidArray<any PythonConvertible & ~Copyable>,
    //     keywordArguments: consuming RigidArray<SwiftKeywordArgumentPair>
    // ) throws(PythonError) -> PythonObject? {
    //     var pythonArguments: RigidArray<PythonObject> = try RigidArray<PythonObject>(
    //         capacity: arguments.count
    //     ) { (contents) throws(PythonError) in
    //         for index in arguments.indices {
    //             contents.append(try arguments[index]._toPythonObject())
    //         }
    //     }
    //     var keywords: [String] = Array()
    //     keywords.reserveCapacity(keywordArguments.count)
    //     var pythonKeywordArguments: RigidArray<PythonObject> = try RigidArray<PythonObject>(
    //         capacity: keywordArguments.count
    //     ) { (contents) throws(PythonError) in
    //         for index in keywordArguments.indices {
    //             keywords.append(keywordArguments[index].keyword)
    //             let keywordArgument = keywordArguments[index]
    //             contents.append(try keywordArgument.argument._toPythonObject())
    //         }
    //     }
    //     return try call(arguments: &pythonArguments, keywordArguments: &pythonKeywordArguments, keywords: keywords)
    // }
    // @discardableResult
    // public func call(
    //     arguments: consuming RigidArray<any PythonConvertible & ~Copyable>
    // ) throws(PythonError) -> PythonObject? {
    //     return try call(arguments: arguments, keywordArguments: RigidArray<SwiftKeywordArgumentPair>())
    // }
    // @discardableResult
    // public func call(
    //     keywordArguments: consuming RigidArray<SwiftKeywordArgumentPair>
    // ) throws(PythonError) -> PythonObject? {
    //     return try call(arguments: RigidArray<any PythonConvertible & ~Copyable>(), keywordArguments: keywordArguments)
    // }

    @discardableResult
    public func call(
        arguments: borrowing Array<any PythonConvertible>,
        keywordArguments: borrowing KeyValuePairs<String, any PythonConvertible>
    ) throws(PythonError) -> PythonObject? {
        var pythonArguments: RigidArray<PythonObject> = try RigidArray<PythonObject>(
            capacity: arguments.count
        ) { (contents) throws(PythonError) in
            for index in arguments.indices {
                contents.append(try arguments[index]._toPythonObject())
            }
        }
        var keywords: [String] = Array()
        keywords.reserveCapacity(keywordArguments.count)
        var pythonKeywordArguments: RigidArray<PythonObject> = try RigidArray<PythonObject>(
            capacity: keywordArguments.count
        ) { (contents) throws(PythonError) in
            for index in keywordArguments.indices {
                keywords.append(keywordArguments[index].key)
                contents.append(try keywordArguments[index].value._toPythonObject())
            }
        }
        return try call(arguments: &pythonArguments, keywordArguments: &pythonKeywordArguments, keywords: keywords)
    }
    @discardableResult
    public func call(
        arguments: borrowing Array<any PythonConvertible>
    ) throws(PythonError) -> PythonObject? {
        return try call(arguments: arguments, keywordArguments: [:])
    }
    @discardableResult
    public func call(
        keywordArguments: borrowing KeyValuePairs<String, any PythonConvertible>
    ) throws(PythonError) -> PythonObject? {
        return try call(arguments: [], keywordArguments: keywordArguments)
    }

    @discardableResult
    public func call(
        arguments: borrowing Array<any PythonConvertible>,
        keywordArguments: borrowing Dictionary<String, any PythonConvertible>
    ) throws(PythonError) -> PythonObject? {
        var pythonArguments: RigidArray<PythonObject> = try RigidArray<PythonObject>(
            capacity: arguments.count
        ) { (contents) throws(PythonError) in
            for index in arguments.indices {
                contents.append(try arguments[index]._toPythonObject())
            }
        }
        var keywords: [String] = Array()
        keywords.reserveCapacity(keywordArguments.count)
        var pythonKeywordArguments: RigidArray<PythonObject> = try RigidArray<PythonObject>(
            capacity: keywordArguments.count
        ) { (contents) throws(PythonError) in
            for index in keywordArguments.indices {
                keywords.append(keywordArguments[index].key)
                contents.append(try keywordArguments[index].value._toPythonObject())
            }
        }
        return try call(arguments: &pythonArguments, keywordArguments: &pythonKeywordArguments, keywords: keywords)
    }
    @discardableResult
    public func call(
        keywordArguments: borrowing Dictionary<String, any PythonConvertible>
    ) throws(PythonError) -> PythonObject? {
        return try call(arguments: [], keywordArguments: keywordArguments)
    }
}

// Calling
extension PythonObject {
    /// Access the `PythonObject` as a callable.
    /// This returns a lifetime-dependent value.
    public var callable: Callable {
        Callable(self)
    }

    /// These have to be disabled for dynamicCallable to work

    /// Call this python object as a callable with no arguments.
    // @discardableResult
    // public func callAsFunction() throws(PythonError) -> PythonObject? {
    //     return try callable.call()
    // }

    /// Call this python object as a callable with one argument.
    /// - Parameter argument: The single object argument.
    // @discardableResult
    // public func callAsFunction(_ argument: inout PythonObject) throws(PythonError) -> PythonObject? {
    //     return try callable.call(argument: &argument)
    // }
    /// Call this python object as a callable with one argument.
    /// - Parameter argument: The single object argument.
    // @inlinable
    // @discardableResult
    // public func callAsFunction(_ argument: borrowing some PythonConvertible & Copyable) throws(PythonError) -> PythonObject? {
    //     // Pass any Copyable PythonConvertible using borrowing and a copy
    //     return try callable.call(argument: argument)
    // }
    /// Call this python object as a callable with one argument.
    /// - Parameter argument: The single object argument.
    // @inlinable
    // @discardableResult
    // @_disfavoredOverload
    // public func callAsFunction(_ argument: consuming some PythonConvertible & ~Copyable) throws(PythonError) -> PythonObject? {
    //     // Pass any PythonConvertible by consuming
    //     return try callable.call(argument: argument)
    // }
    /// Call this python object as a callable with one argument.
    /// - Parameter argument: The single object argument.
    // @inlinable
    // @discardableResult
    // public func callAsFunction(_ argument: inout some PythonConvertible & ~Copyable) throws(PythonError) -> PythonObject? {
    //     // Pass any PythonConvertible mutating it
    //     return try callable.call(argument: &argument)
    // }

    @discardableResult
    public func dynamicallyCall(withArguments arguments: [any PythonConvertible]) throws(PythonError) -> PythonObject? {
        return try callable.call(arguments: arguments)
    }
    @discardableResult
    @_disfavoredOverload
    public func dynamicallyCall(withKeywordArguments arguments: KeyValuePairs<String, any PythonConvertible>) throws(PythonError) -> PythonObject? {
        var positionalArguments: [any PythonConvertible] = []
        var keywordArguments: Dictionary<String, any PythonConvertible> = [:]
        for (keyword, argument) in arguments {
            if keyword.isEmpty {
                positionalArguments.append(argument)
            } else {
                keywordArguments[keyword] = argument
            }
        }
        return try callable.call(arguments: positionalArguments, keywordArguments: keywordArguments)
    }
}
