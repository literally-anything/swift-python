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

#ifdef __cplusplus
extern "C" {
#endif


typedef int (*_PyCModuleExecFunction)(PyObject *module);

SWIFT_INLINE PyModuleDef_Base _get_PyModuleDef_HEAD_INIT() {
    PyModuleDef_Base base = PyModuleDef_HEAD_INIT;
    return base;
}

#ifdef __cplusplus
}
#endif
