/**
 * Array+PythonConvertible.swift
 * Conformances
 * 
 * Created by Hunter Baker on 12/27/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

import CPython

extension Array: PythonConvertible where Element: PythonConvertible {
    public init(_ pythonObject: borrowing PythonObject) throws(PythonError) {
        let length = try pythonObject.length
        var error: PythonError? = nil
        self.init(
            unsafeUninitializedCapacity: Int(length)
        ) { buffer, initializedCount in
            do throws(PythonError) {
                for index in 0..<length {
                    let itemRef: UnsafePyObjectRef? = PySequence_GetItem(pythonObject.pyObject, index)
                    guard let itemRef else {
                        try PythonError.check()
                        throw PythonError.unknown
                    }
                    let item = PythonObject(unsafeUnretained: itemRef)
                    buffer[Int(index)] = try Element(item)
                }
            } catch let e {
                error = e
                return
            }
            initializedCount = Int(length)
        }
        if let error {
            throw error
        }
    }

    public borrowing func _toPythonObject() throws(PythonError) -> PythonObject {
        let listRef: UnsafePyObjectRef? = PyList_New(Py_ssize_t(count))
        guard let listRef else {
            try PythonError.check()
            throw PythonError.unknown
        }
        let list: PythonObject = PythonObject(unsafeUnretained: listRef)

        for (index, item) in enumerated() {
            let pyItem = try item._toPythonObject()
            let ret: CInt = PyList_SetItem(list.pyObject, index, pyItem.pyObject)
            guard ret == 0 else {
                try PythonError.check()
                throw PythonError.unknown
            }
        }

        return list
    }
}
