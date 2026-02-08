/*
 * StdlibUtils.swift
 * SwiftPython
 * -----
 * Copyright (c) 2025 - 2026 Hunter Baker hunter@literallyanything.net
 * Licensed under the MIT License
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
