/**
 * Tool.swift
 * SwiftPythonTool
 * 
 * Created by Hunter Baker on 12/22/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
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
