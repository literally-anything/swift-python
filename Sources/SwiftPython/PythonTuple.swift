/**
 * PythonTuple.swift
 * SwiftPython
 * 
 * Created by Hunter Baker on 12/28/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

import CPython
public import BasicContainers

public func pythonTuple(from arguments: consuming RigidArray<PythonObject>) throws(PythonError) -> PythonObject {
    let tupleRef: UnsafePyObjectRef? = PyTuple_New(Py_ssize_t(arguments.count))
    guard let tupleRef else {
        try PythonError.check()
        throw PythonError.unknown
    }
    let tuple = PythonObject(unsafeUnretained: tupleRef)
    for index in arguments.indices {
        let ret: CInt = PyTuple_SetItem(tuple.pyObject, Py_ssize_t(index), arguments[index].pyObject)
        guard ret == 0 else {
            try PythonError.check()
            throw PythonError.unknown
        }
    }
    return tuple
}

@_disfavoredOverload
public func pythonTuple(from arguments: consuming RigidArray<any PythonConvertible & ~Copyable>) throws(PythonError) -> PythonObject {
    let pythonArguments: RigidArray<PythonObject> = try RigidArray<PythonObject>(
        capacity: arguments.count
    ) { (contents) throws(PythonError) -> Void in
        for index in arguments.indices.reversed() {
            let argument = arguments.remove(at: index)
            contents.append(try argument._toPythonObject())
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
            contents.append(try argument._toPythonObject())
        }
    }
    return try pythonTuple(from: argumentsRigidArray)
}

@inlinable
@_disfavoredOverload
public func pythonTuple<each T: PythonConvertible>(_ arguments: repeat each T) throws(PythonError) -> PythonObject {
    var argumentsArray: [any PythonConvertible] = []
    for argument in repeat each arguments {
        argumentsArray.append(argument)
    }
    return try pythonTuple(from: argumentsArray)
}
