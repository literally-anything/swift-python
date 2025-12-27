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
    @usableFromInline
    internal static func ensureInitialized() {
        isInitialized.withLock { isInitialized in
            if isInitialized {
                return
            }

            if Py_IsInitialized() != 0 {
                isInitialized = true
                return
            }

            var config: PyConfig = PyConfig()
            PyConfig_InitIsolatedConfig(&config)
            defer { PyConfig_Clear(&config) }

            Py_InitializeFromConfig(&config)
            isInitialized = true
        }
    }

    /// The mutable interpreter builtins.
    public static var builtins: PythonObject? {
        ensureInitialized()
        let builtinsRef: UnsafePyObjectRef? = PyEval_GetFrameBuiltins()
        try? PythonError.check() // ToDo: Replace with a throwing getter when those work with noncopyable types.
        return PythonObject(unsafeUnretained: builtinsRef)
    }
    /// The mutable interpreter globals.
    public static var globals: PythonObject? {
        ensureInitialized()
        let globalsRef: UnsafePyObjectRef? = PyEval_GetFrameGlobals()
        try? PythonError.check() // ToDo: Replace with a throwing getter when those work with noncopyable types.
        return PythonObject(unsafeUnretained: globalsRef)
    }
    /// The mutable interpreter locals.
    public static var locals: PythonObject? {
        ensureInitialized()
        let localsRef: UnsafePyObjectRef? = PyEval_GetFrameLocals()
        try? PythonError.check() // ToDo: Replace with a throwing getter when those work with noncopyable types.
        return PythonObject(unsafeUnretained: localsRef)
    }

    /// Imports the specified python module and returns its module object.
    public static func `import`(name: String) throws(PythonError) -> PythonObject {
        ensureInitialized()
        let moduleRef: UnsafePyObjectRef? = withGIL {
            unsafe PyImport_ImportModule(name)
        }
        guard let moduleRef else {
            try PythonError.check()
            throw PythonError.unknown
        }
        return unsafe PythonObject(unsafeUnretained: moduleRef)
    }

    /// The mode to use when running a python string.
    internal enum RunMode {
        /// Run as a single expression.
        case expression
        /// Run as a full file.
        case file
    }

    @discardableResult
    internal static func run(_ code: String, mode: RunMode) throws(PythonError) -> PythonObject? {
        ensureInitialized()
        var flags: PyCompilerFlags = PyCompilerFlags(cf_flags: PyCF_ALLOW_TOP_LEVEL_AWAIT | PyCF_TYPE_COMMENTS, cf_feature_version: 0)
        let start: CInt =
            switch mode {
                case .expression:
                    Py_eval_input
                case .file:
                    Py_file_input
            }
        let globalsRef: UnsafePyObjectRef? = globals?.take()
        let localsRef: UnsafePyObjectRef? = locals?.take()
        defer {
            if let globalsRef {
                PythonObject.release(globalsRef)
            }
            if let localsRef {
                PythonObject.release(localsRef)
            }
        }
        let returnRef: UnsafePyObjectRef? = withUnsafeMutablePointer(to: &flags) { flagsPtr in
            // Use the main module dictionary as the globals and locals only if we couldn't find a frame.
            var mainDict: UnsafePyObjectRef? = nil
            if globalsRef == nil || localsRef == nil {
                mainDict = PyModule_GetDict(PyImport_AddModule("__main__"))
            }
            return PyRun_StringFlags(code, start, globalsRef ?? mainDict, localsRef ?? mainDict, flagsPtr)
        }
        guard let returnRef else {
            try PythonError.check()
            throw PythonError.unknown
        }
        let returnValue = PythonObject(unsafeUnretained: returnRef)
        if returnValue.isNone {
            return nil
        } else {
            return returnValue
        }
    }

    public static func run(_ code: String) throws(PythonError) {
        try run(code, mode: .file)
    }

    public static func run(expression: String) throws(PythonError) -> PythonObject? {
        try run(expression, mode: .expression)
    }

    @inlinable
    public static func withGIL<T: ~Copyable, E: Error>(
        _ body: () throws(E) -> T
    ) throws(E) -> T {
        return try withThreadState(body)
    }

    @inlinable
    public static func withGILUnlocked<T: ~Copyable, E: Error>(
        _ body: () throws(E) -> T
    ) throws(E) -> T {
        return try withThreadStateCleared(body)
    }

    @inlinable
    public static func withThreadState<T: ~Copyable, E: Error>(
        _ body: () throws(E) -> T
    ) throws(E) -> T {
        ensureInitialized()

        let alreadyLocked = PyThreadState_GetUnchecked() != nil
        var threadState: UnsafeMutablePointer<PyThreadState>? = nil
        if !alreadyLocked {
            let interpreterState = PyInterpreterState_Get()
            threadState = PyThreadState_New(interpreterState)
            PyThreadState_Swap(threadState)
        }
        defer {
            if !alreadyLocked {
                PyThreadState_Clear(threadState)
                PyThreadState_DeleteCurrent()
            }
        }

        return try body()
    }

    @inlinable
    public static func withThreadStateCleared<T: ~Copyable, E: Error>(
        _ body: () throws(E) -> T
    ) throws(E) -> T {
        ensureInitialized()

        let isLocked = PyThreadState_GetUnchecked() != nil
        var threadState: UnsafeMutablePointer<PyThreadState>? = nil
        if isLocked {
            threadState = PyEval_SaveThread()
        }
        defer {
            if isLocked {
                PyEval_RestoreThread(threadState)
            }
        }

        return try body()
    }
}
