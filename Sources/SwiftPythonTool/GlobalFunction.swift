/**
 * GlobalFunction.swift
 * SwiftPythonTool
 * 
 * Created by Hunter Baker on 12/23/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

import SwiftSyntax
import SwiftSyntaxBuilder

typealias GlobalFunctionInfo = (
    func: GlobalFunction, glueName: TokenSyntax, callingConvention: PyMethodCallingConvention
)

func generateGlobalFunctions(pythonModuleName: String, functions: [GlobalFunction]) -> (decls: [FunctionDeclSyntax], info: [GlobalFunctionInfo]) {
    // Generate glue functions for each passed function
    var outDecls: [FunctionDeclSyntax] = []
    var outInfo: [GlobalFunctionInfo] = []
    for function in functions {
        // Determine calling convention
        let callingConvention: PyMethodCallingConvention =
            if function.signature.arguments.isEmpty {
                PyMethodCallingConvention.noArguments
            } else if function.signature.arguments.count == 1 {
                PyMethodCallingConvention.singleObject
            } else if function.signature.arguments.allSatisfy({ $0.label == nil }) {
                // No labels
                PyMethodCallingConvention.fastCall
            } else {
                PyMethodCallingConvention.fastCallKeywords
            }
        
        let selfParam: TokenSyntax = .identifier("self")
        let argsParam: TokenSyntax = .identifier("args")
        let nArgsParam: TokenSyntax = .identifier("nArgs")
        let kwNamesParam: TokenSyntax = .identifier("kwNames")

        // Build the function declaration
        let glueFunc: TokenSyntax = .identifier("_\(pythonModuleName)_\(function.name)")
        var glueFuncDecl = FunctionDeclSyntax(
            name: glueFunc,
            signature: FunctionSignatureSyntax(
                parameters: .init {
                    // Always needs self and args, but only add kwArgs when needed
                    // Everything is a PyObject*
                    FunctionParameterSyntax(
                        firstName: selfParam,
                        secondName: .wildcardToken(),
                        type: PythonTypes.PyObjectPtr.type
                    )
                    FunctionParameterSyntax(
                        firstName: argsParam,
                        // If the calling convention is noArguments, we don't use args, so mark it as unused with an underscore.
                        secondName: callingConvention == .noArguments ? .wildcardToken() : nil,
                        // When using FASTCALL, the args parameter is an array of PyObject pointers.
                        type: callingConvention.isFastCall ? "Optional<UnsafePointer<\(PythonTypes.PyObjectPtr.type)>>" : PythonTypes.PyObjectPtr.type
                    )
                    if callingConvention.isFastCall {
                        FunctionParameterSyntax(firstName: nArgsParam, type: PythonTypes.PySize.type)
                    }
                    if callingConvention == .fastCallKeywords {
                        FunctionParameterSyntax(firstName: kwNamesParam, type: PythonTypes.PyObjectPtr.type)
                    }
                },
                return: PythonTypes.PyObjectPtr.type
            ),
            body: buildGlobalFunctionBody(
                function: function, callingConvention: callingConvention,
                selfParam: selfParam, argsParam: argsParam, nArgsParam: nArgsParam, kwNamesParam: kwNamesParam
            )
        )
        glueFuncDecl.attributes = [.attribute(noDocsAttribute)]
        outDecls.append(glueFuncDecl)
        outInfo.append((function, glueFunc, callingConvention))
    }

    return (outDecls, outInfo)
}

private func buildGlobalFunctionBody(
    function: GlobalFunction, callingConvention: PyMethodCallingConvention,
    selfParam: TokenSyntax, argsParam: TokenSyntax, nArgsParam: TokenSyntax, kwNamesParam: TokenSyntax
) -> CodeBlockSyntax {
    var codeBlock = CodeBlockSyntax(statements: CodeBlockItemListSyntax())

    guard !function.signature.isAsync, function.signature.errorType == nil else {
        fatalError("Async and throwing functions are not yet supported")
    }

    return codeBlock
}
