/**
 * GenTool.swift
 * SwiftPythonTool
 * 
 * Created by Hunter Baker on 12/22/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

import Foundation
import ArgumentParser
import SymbolKit
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftBasicFormat

struct Gen: ParsableCommand {
    @Argument var symbolGraphDirURL: String
    @Argument var moduleName: String
    @Argument var inputDirURL: String
    @Argument var outputDirURL: String

    @Argument(
        help: ArgumentHelp(
            "The name of the python module to export",
            valueName: "python-module",
            argumentType: String.self
        )
    )
    var pythonModuleName: String

    mutating func run() throws {
        // let decoder = JSONDecoder()

        let symbolGraphDir = URL(string: symbolGraphDirURL)
        let inputDir = URL(string: inputDirURL)
        let outputDir = URL(string: outputDirURL)
        guard let symbolGraphDir, let inputDir, let outputDir else {
            throw ToolError(description: "Invalid arguments")
        }

        // let collector = GraphCollector()
        // for file in try FileManager.default.contentsOfDirectory(atPath: symbolGraphDir.path) {
        //     if file.hasSuffix(".json") {
        //         let graphUrl = symbolGraphDir.appending(path: file)
        //         let data = try String(contentsOf: graphUrl, encoding: .utf8).data(using: .utf8)
        //         guard let data else {
        //             throw ToolError(description: "Failed to load symbolgraph: \(file)")
        //         }
        //         let graph = try decoder.decode(SymbolGraph.self, from: data)
        //         collector.mergeSymbolGraph(graph, at: graphUrl)
        //     }
        // }
        // let unifiedGraphs = collector.finishLoading().unifiedGraphs
        // guard unifiedGraphs.keys.contains(moduleName) else {
        //     throw ToolError(description: "Module \"\(moduleName)\" not found; Known Modules: \(unifiedGraphs.keys.map(\.self))")
        // }
        // let graph: UnifiedSymbolGraph = unifiedGraphs[moduleName]!

        let globalFunctions = [
            GlobalFunction(
                name: "hello",
                signature: FunctionSignature(
                    arguments: [(label: "text", type: .primitive(.string))],
                    returnType: .primitive(.int(signed: true, bitWidth: .init(rawValue: Int.bitWidth)!))
                )
            )
        ]
        
        let imports: [ImportDeclSyntax] = [
            ImportDeclSyntax(module: "SwiftPython"),
            ImportDeclSyntax(module: "CPython")
        ]

        // Make a file for the global function glue
        let (globalFunctionDecls, globalFunctionInfo) = generateGlobalFunctions(
            pythonModuleName: pythonModuleName,
            functions: globalFunctions
        )
        let globalFunctionsFile = getFileURL(root: outputDir, name: "GlobalFunctions")
        try writeFile(
            file: globalFunctionsFile,
            imports: imports,
            contents: globalFunctionDecls.map { decl in
                // Build a CodeBlockItem from the function decl
                CodeBlockItemSyntax(
                    item: .decl(.init(decl))
                )
            }
        )

        // Make a file for the module definition
        let moduleDefinition = generateModuleDefinition(
            pythonModuleName: pythonModuleName,
            globalFunctions: globalFunctionInfo
        )
        let pythonModuleFile = getFileURL(root: outputDir, name: "PyModule")
        try writeFile(file: pythonModuleFile, imports: imports + moduleDefinition.imports, contents: moduleDefinition.contents)
    }
}

func getFileURL(root: URL, name: String) -> URL {
    return root.appending(component: "\(name)+SwiftPython.swift")
}

func writeFile(file: URL, imports: [ImportDeclSyntax], contents: [CodeBlockItemSyntax]) throws {
    var sourceFileSyntax = SourceFileSyntax(statements: [])

    // Add imports and contents, and format the file
    sourceFileSyntax.statements.append(
        contentsOf: imports.map {
            CodeBlockItemSyntax(item: .decl(DeclSyntax($0)))
        }
    )
    sourceFileSyntax.statements.append(contentsOf: contents)
    let formattedFile = sourceFileSyntax.formatted()

    // Write file
    var fileText = String()
    formattedFile.write(to: &fileText)
    try fileText.write(to: file, atomically: true, encoding: .utf8)
}
