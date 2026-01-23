/**
 * PythonTuple.swift
 * SwiftPython
 * 
 * Created by Hunter Baker on 12/28/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunter@literallyanything.net
 */

import CPython
public import BasicContainers

public func pythonTuple(from arguments: consuming RigidArray<PythonObject>) throws(PythonError) -> PythonObject {
    let tupleRef: UnsafePyObjectRef? = PyTuple_New(Py_ssize_t(arguments.count))
    guard let tupleRef else {
        try PythonError.check()
        throw PythonError.unknown
    }
    let tuple = PythonObject(fromOwned: tupleRef)
    for index in arguments.indices.reversed() {
        let argument = arguments.remove(at: index)
        // PyTuple_SetItem steals the argument reference, so we take it here to avoid deallocating
        let ret: CInt = PyTuple_SetItem(tuple.pyObject, Py_ssize_t(index), argument.take())
        guard ret == 0 else {
            try PythonError.check()
            throw PythonError.unknown
        }
    }
    return tuple
}

@_disfavoredOverload
public func pythonTuple(from arguments: consuming RigidArray<any ~Copyable & PythonConvertible>) throws(PythonError) -> PythonObject {
    let pythonArguments: RigidArray<PythonObject> = try RigidArray<PythonObject>(
        capacity: arguments.count
    ) { (contents) throws(PythonError) -> Void in
        for index in arguments.indices.reversed() {
            let argument = arguments.remove(at: index)
            contents.append(try argument.convertToPythonObject())
        }
    }
    return try pythonTuple(from: pythonArguments)
}

@_disfavoredOverload
public func pythonTuple(from arguments: [any PythonConvertible]) throws(PythonError) -> PythonObject {
    let argumentsRigidArray: RigidArray<PythonObject> = try RigidArray<PythonObject>(
        capacity: arguments.count
    ) { (contents) throws(PythonError) -> Void in
        for argument in arguments {
            contents.append(try argument.convertToPythonObject())
        }
    }
    return try pythonTuple(from: argumentsRigidArray)
}

@inlinable
public func pythonTuple<each T: Copyable & PythonConvertible>(_ arguments: (repeat each T)) throws(PythonError) -> PythonObject {
    // ToDo: Find a way to determine the size of the parameter pack without reflection
    var argumentsArray = UniqueArray<PythonObject>()
    for argument in repeat each arguments {
        argumentsArray.append(try argument.convertToPythonObject())
    }
    return try pythonTuple(from: RigidArray(consuming: argumentsArray))
}

@inlinable
public func pythonTuple<each T: Copyable & PythonConvertible>(_ arguments: repeat each T) throws(PythonError) -> PythonObject {
    return try pythonTuple((repeat each arguments))
}
