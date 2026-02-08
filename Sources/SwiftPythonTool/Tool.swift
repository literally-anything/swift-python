/*
 * Tool.swift
 * SwiftPython
 * -----
 * Copyright (c) 2025 - 2026 Hunter Baker hunter@literallyanything.net
 * Licensed under the MIT License
 */

import ArgumentParser

struct ToolError: Error, CustomStringConvertible {
    var description: String
}

@main
struct SwiftPythonTool: ParsableCommand {
    static let configuration = CommandConfiguration(
        subcommands: [Gen.self]
    )
}
