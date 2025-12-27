/**
 * Array+PythonConvertible.swift
 * Conformances
 * 
 * Created by Hunter Baker on 12/27/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

import CPython

extension Array: PythonConvertible where Element: PythonConvertible {
    public func _toPythonObject() throws(PythonError) -> PythonObject {
        let listRef: UnsafePyObjectRef? = PyList_New(count)
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
