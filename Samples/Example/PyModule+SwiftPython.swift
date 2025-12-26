/**
 * PyModule+SwiftPython.swift
 * Example
 * 
 * Created by Hunter Baker on 12/25/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */
import SwiftPython
import CPython
import Synchronization
@_documentation(visibility: private) let _example_moduleDefinition: Synchronization.Mutex<Optional<UnsafeMutablePointer<CPython.PyModuleDef>>> = Synchronization.Mutex(nil)
@_documentation(visibility: private) @_cdecl("PyInit_example") func _PyInit_example() -> Optional<UnsafeMutablePointer<CPython.PyObject>> {
    let pyModulePtr: Optional<UnsafeMutablePointer<CPython.PyModuleDef>> = _example_moduleDefinition.withLock({ (pyModuleDef) -> Optional<UnsafeMutablePointer<CPython.PyModuleDef>> in
            if pyModuleDef == nil {
                let pyModuleName: StaticString = "example"
                let pyModuleMethods: UnsafeMutableBufferPointer<CPython.PyMethodDef> = UnsafeMutableBufferPointer<CPython.PyMethodDef>.allocate(capacity: 2)
                pyModuleMethods[1] = CPython.PyMethodDef(ml_name: nil, ml_meth: nil, ml_flags: 0, ml_doc: nil)
                let function_hello_name: StaticString = "hello"
                let function_hello: CPython.PyCFunction = _example_hello
                pyModuleMethods[0] = CPython.PyMethodDef(ml_name: function_hello_name._cStringStart, ml_meth: function_hello, ml_flags: CPython.METH_O, ml_doc: nil)
                let pyModuleSlots: UnsafeMutableBufferPointer<CPython.PyModuleDef_Slot> = UnsafeMutableBufferPointer<CPython.PyModuleDef_Slot>.allocate(capacity: 4)
                pyModuleSlots[3] = CPython.PyModuleDef_Slot(slot: 0, value: nil)
                let pyModuleExecSlotMethod: CPython._PyCModuleExecFunction = _example_exec
                pyModuleSlots[0] = CPython.PyModuleDef_Slot(slot: CPython.Py_mod_exec, value: unsafeBitCast(pyModuleExecSlotMethod, to: Optional<UnsafeMutableRawPointer>.self))
                pyModuleSlots[1] = CPython.PyModuleDef_Slot(slot: CPython.Py_mod_multiple_interpreters, value: UnsafeMutableRawPointer(bitPattern: 2))
                pyModuleSlots[2] = CPython.PyModuleDef_Slot(slot: CPython.Py_mod_gil, value: UnsafeMutableRawPointer(bitPattern: 0))
                let pyModuleDefInline: CPython.PyModuleDef = CPython.PyModuleDef(m_base: CPython._get_PyModuleDef_HEAD_INIT(), m_name: pyModuleName._cStringStart, m_doc: nil, m_size: 0, m_methods: pyModuleMethods.baseAddress, m_slots: pyModuleSlots.baseAddress, m_traverse: nil, m_clear: nil, m_free: nil)
                let pyModuleDefAlloc: UnsafeMutablePointer<CPython.PyModuleDef> = UnsafeMutablePointer<CPython.PyModuleDef>.allocate(capacity: 1)
                pyModuleDefAlloc.initialize(to: pyModuleDefInline)
                pyModuleDef = pyModuleDefAlloc
            }
            return pyModuleDef
        })
    return CPython.PyModuleDef_Init(pyModulePtr)
}
@_documentation(visibility: private) func _example_exec(module: Optional<UnsafeMutablePointer<CPython.PyObject>>) -> CInt {
    return 0
}