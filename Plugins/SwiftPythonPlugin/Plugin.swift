/**
 * Plugin.swift
 * SwiftPythonPlugin
 * 
 * Created by Hunter Baker on 12/22/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

import Foundation
import PackagePlugin

struct PluginError: Error, CustomStringConvertible {
    var description: String
}

@main
struct SwiftPythonPlugin: CommandPlugin {
    @discardableResult
    func runTool(context: PluginContext, mode: String, arguments: [String] = [], input: Pipe? = nil, output: Pipe? = nil) throws -> Int32 {
        let process = Process()
        process.executableURL = try context.tool(named: "SwiftPythonTool").url
        process.currentDirectoryURL = context.package.directoryURL

        process.arguments = [mode] + arguments
        if let input {
            process.standardInput = input
        }
        if let output {
            process.standardOutput = output
        }

        try process.run()
        process.waitUntilExit()
        return process.terminationStatus
    }

    func performCommand(context: PluginContext, arguments: [String]) throws {
        let encoder = JSONEncoder()

        let products = context.package.products.map(\.name)
        let targetNames = context.package.targets.map(\.name)

        let productsArg = try String(bytes: encoder.encode(products), encoding: .utf8)
        let targetNamesArg = try String(bytes: encoder.encode(targetNames), encoding: .utf8)
        guard let productsArg, let targetNamesArg else {
            throw PluginError(description: "Failed to encode package data")
        }

        // let preparePipe = Pipe()
        // runTool(context: context, mode: "prepare", arguments: [productsArg, targetNamesArg], output: preparePipe)
        // let prepareOutput = String(bytes: preparePipe.fileHandleForReading.availableData, encoding: .utf8)
        // guard let prepareOutput else {
        //     throw PluginError(description: "Tool did not respond when preparing")
        // }
        let targetIndex = targetNames.firstIndex { $0 == "Example" }!
        let target = context.package.targets[targetIndex]
        let outTarget = target

        // let graphDir: URL = try packageManager.getSymbolGraph(
        //     for: target,
        //     options: .init(
        //         minimumAccessLevel: .public,
        //         includeSynthesized: true,
        //         emitExtensionBlocks: true
        //     )
        // ).directoryURL
        let graphDir: URL = URL(filePath: "/Users/hbaker/XcodeProjects/SwiftPython/.build/extracted-symbols")

        try runTool(
            context: context,
            mode: "gen",
            arguments: [
                graphDir.absoluteString,
                "Example",
                target.directoryURL.absoluteString,
                outTarget.directoryURL.absoluteString
            ] + arguments
        )
    }
}
