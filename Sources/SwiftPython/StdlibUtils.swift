/**
 * StdlibUtils.swift
 * SwiftPython
 * 
 * Created by Hunter Baker on 12/23/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

extension StaticString {
    @safe
    @_documentation(visibility: private)
    @_transparent
    @_alwaysEmitIntoClient
    public var _cStringStart: UnsafePointer<CChar> {
        UnsafePointer<CChar>(OpaquePointer(utf8Start))
    }
}
