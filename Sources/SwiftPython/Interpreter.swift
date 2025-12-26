/**
 * Interpreter.swift
 * SwiftPython
 * 
 * Created by Hunter Baker on 12/25/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

import Synchronization
import CPython

public struct PythonInterpreter: SendableMetatype {
    /// Stores whether the interpreter is initialized yet.
    internal static let isInitialized: Mutex<Bool> = Mutex(false)
    /// Ensures that the interpreter has been initialized.
    internal static func ensureInitialized() {
        isInitialized.withLock { isInitialized in
            if isInitialized {
                return
            }

            if Py_IsInitialized() != 0 {
                isInitialized = true
                return
            }

            Py_Initialize()
            isInitialized = true

            // Fixes from https://github.com/pvieito/PythonKit/blob/master/PythonKit/Python.swift#L682
            PyRun_SimpleString("""
                import sys
                import os

                # Some Python modules expect to have at least one argument in `sys.argv`:
                sys.argv = [""]

                # Some Python modules require `sys.executable` to return the path
                # to the Python interpreter executable. In Darwin, Python 3 returns the
                # main process executable path instead:
                if sys.version_info.major == 3 and sys.platform == "darwin":
                    executable_name = "python{}.{}".format(sys.version_info.major, sys.version_info.minor)
                    sys.executable = os.path.join(sys.exec_prefix, "bin", executable_name)
            """)
        }
    }

    /// The mutable interpreter builtins.
    public static var builtins: PythonObject {
        unsafe PythonObject(unsafeUnretained: PyEval_GetFrameBuiltins())
    }
    /// The mutable interpreter globals.
    public static var globals: PythonObject {
        unsafe PythonObject(unsafeUnretained: PyEval_GetFrameGlobals())
    }
    /// The mutable interpreter locals.
    public static var locals: PythonObject {
        unsafe PythonObject(unsafeUnretained: PyEval_GetFrameLocals())
    }

    /// Imports the specified python module and returns its module object.
    public static func `import`(name: String) throws(PythonError) -> PythonObject {
        let moduleRef: UnsafePyObjectRef? = unsafe PyImport_ImportModule(name)
        guard let moduleRef else {
            try PythonError.check()
            throw PythonError.getUnknownError()
        }
        return unsafe PythonObject(unsafeUnretained: moduleRef)
    }

    /// The mode to use when running a python string.
    public enum RunMode {
        /// Run as a single expression.
        case expression
        /// Run as a full file.
        case file
    }

    @discardableResult
    public static func run(_ code: String, mode: RunMode) throws(PythonError) -> PythonObject? {
        var flags: PyCompilerFlags = PyCompilerFlags(cf_flags: PyCF_ALLOW_TOP_LEVEL_AWAIT | PyCF_TYPE_COMMENTS, cf_feature_version: 0)
        let start: CInt =
            switch mode {
                case .expression:
                    Py_eval_input
                case .file:
                    Py_file_input
            }
        let globalsRef: UnsafePyObjectRef = globals.take()
        let localsRef: UnsafePyObjectRef = locals.take()
        defer {
            PythonObject.release(globalsRef)
            PythonObject.release(localsRef)
        }
        let returnRef: UnsafePyObjectRef? = withUnsafeMutablePointer(to: &flags) { flagsPtr in
            PyRun_StringFlags(code, start, globalsRef, localsRef, flagsPtr)
        }
        if returnRef == nil {
            try PythonError.check()
        }
        return PythonObject(unsafeUnretained: returnRef)
    }

    public static func run(_ code: String) throws(PythonError) {
        try run(code, mode: .file)
    }

    public static func run(expression: String) throws(PythonError) -> PythonObject? {
        try run(expression, mode: .expression)
    }
}
