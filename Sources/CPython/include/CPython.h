/*
 * CPython.h
 * include
 * 
 * Created by Hunter Baker on 12/03/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

#pragma once

#define SWIFT_INLINE [[maybe_unused]] static inline __attribute__((__always_inline__))

#define PY_SSIZE_T_CLEAN
#include <Python.h>

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif


typedef int (*_PyCModuleExecFunction)(PyObject * __nullable module);

SWIFT_INLINE PyModuleDef_Base _get_PyModuleDef_HEAD_INIT() {
    PyModuleDef_Base base = PyModuleDef_HEAD_INIT;
    return base;
}

SWIFT_INLINE bool _PyExceptionInstance_Check(PyObject * __nullable object) {
    return PyExceptionInstance_Check(object);
}

SWIFT_INLINE bool _PyBool_Check(PyObject * __nullable object) {
    return PyBool_Check(object);
}
SWIFT_INLINE bool _PyLong_Check(PyObject * __nullable object) {
    return PyLong_Check(object);
}
SWIFT_INLINE bool _PyFloat_Check(PyObject * __nullable object) {
    return PyFloat_Check(object);
}
SWIFT_INLINE bool _PyUnicode_Check(PyObject * __nullable object) {
    return PyUnicode_Check(object);
}
SWIFT_INLINE bool _PyList_Check(PyObject * __nullable object) {
    return PyList_Check(object);
}

#ifdef __cplusplus
}
#endif
