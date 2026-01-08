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
    guard !function.signature.isAsync else {
        fatalError("Async functions are not supported yet")
    }
    guard !function.signature.arguments.contains(where: { $0.mutable }) else {
        fatalError("Functions with inout arguments are not supported yet")
    }

    var argumentBlock: [CodeBlockItemSyntax] = []
    var returnBlock: [CodeBlockItemSyntax] = []
    var argumentsThrow: Bool = false

    // Build the basic function call
    var args: [LabeledExprSyntax] = []
    switch callingConvention {
        case .noArguments: break
        case .singleObject:
            let argumentParamVar: TokenSyntax = .identifier("argument")
            argumentBlock.append(
                CodeBlockItemSyntax(item: .decl(DeclSyntax(
                    VariableDeclSyntax(
                        specifier: .let,
                        name: argumentParamVar,
                        type: "SwiftPython.PythonObject" as TypeSyntax,
                        value: "SwiftPython.PythonObject(unsafeUnmanaged: \(argsParam)!)" as ExprSyntax
                    )
                )))
            )
            switch function.signature.arguments.first!.type {
                case .pyObject:
                    args.append(
                        LabeledExprSyntax(
                            label: function.signature.arguments.first!.label,
                            expression: DeclReferenceExprSyntax(baseName: argumentParamVar)
                        )
                    )
                case let .object(name: typeName):
                    argumentsThrow = true
                    args.append(
                        LabeledExprSyntax(
                            label: function.signature.arguments.first!.label,
                            expression: TryExprSyntax(expression: "\(typeName)(\(argumentParamVar))" as ExprSyntax)
                        )
                    )
                default: fatalError("parameter type not supported yet: \(function.signature.arguments.first!.type)")
            }
        default: break
    }
    let callExpr = ExprSyntax(
        FunctionCallExprSyntax(
            calledExpression: DeclReferenceExprSyntax(baseName: function.usedName),
            leftParen: .leftParenToken(),
            arguments: LabeledExprListSyntax(args),
            rightParen: .rightParenToken()
        )
    )
    var callBlockItem: CodeBlockItemSyntax

    // Figure out return value
    if let returnType = function.signature.returnType {
        // If a return value, bind call result to a variable and convert and return it
        let returnValueVar: TokenSyntax = .identifier("returnValue")
        let returnValueDecl = VariableDeclSyntax(
            specifier: .let,
            name: returnValueVar,
            value: callExpr
        )
        callBlockItem = CodeBlockItemSyntax(item: .decl(DeclSyntax(returnValueDecl)))

        buildPythonReturn(block: &returnBlock, returnThrows: &argumentsThrow, returnValueVar: returnValueVar, returnType: returnType, function: function)
    } else {
        // If no return value, just call it and return a borrowed None ref
        callBlockItem = CodeBlockItemSyntax(item: .expr(ExprSyntax(callExpr)))
        let returnStatement = ReturnStmtSyntax(
            expression: "SwiftPython.PythonObject.none.take()" as ExprSyntax  // Python None object
        )
        returnBlock.append(CodeBlockItemSyntax(item: .stmt(StmtSyntax(returnStatement))))
    }

    callBlockItem = pythonCatch(
        CodeBlockSyntax(
            statements: CodeBlockItemListSyntax {
                callBlockItem
                for item in returnBlock {
                    item
                }
            }
        ),
        throws: argumentsThrow
    )
    wrapPythonCall_Throws(callBlockItem: &callBlockItem, signature: function.signature)

    return CodeBlockSyntax(statements: argumentBlock + [callBlockItem])
}

private func buildPythonReturn(block: inout [CodeBlockItemSyntax], returnThrows: inout Bool, returnValueVar: TokenSyntax, returnType: Type, function: GlobalFunction) {
    switch returnType {
        case .object(name: _):
            block.append(
                CodeBlockItemSyntax(item: .stmt(StmtSyntax(
                    ReturnStmtSyntax(expression: buildPythonReturn_Object(returnValueVar: returnValueVar, returnThrows: &returnThrows))
                )))
            )
        // case let .tuple([Type])
        case .function(_, escaping: _):
            fatalError("Function return types are not supported yet")
        case .unsupported(name: _): fallthrough
        default:
            fatalError("Unsupported return type to function `\(function.name)`")
    }
}

private func buildPythonReturn_Object(returnValueVar: TokenSyntax, returnThrows: inout Bool) -> ExprSyntax {
    returnThrows = true
    // Convert to PythonObject and grab the PyObject pointer
    return "try \(returnValueVar).convertToPythonObject().take()" as ExprSyntax
}

private func wrapPythonCall_Throws(callBlockItem: inout CodeBlockItemSyntax, signature: FunctionSignature) {
    if let errorType = signature.errorType {
        let errorVar: TokenSyntax = .identifier("callError")
        let throwsClause = switch errorType {
            case .any: ThrowsClauseSyntax(throwsSpecifier: .keyword(.throws))
            case .pyError:
                ThrowsClauseSyntax(
                    throwsSpecifier: .keyword(.throws),
                    leftParen: .leftParenToken(),
                    type: "SwiftPython.PythonError" as TypeSyntax,
                    rightParen: .rightParenToken()
                )
            case let .typed(type):
                ThrowsClauseSyntax(
                    throwsSpecifier: .keyword(.throws),
                    leftParen: .leftParenToken(),
                    type: "\(type)" as TypeSyntax,
                    rightParen: .rightParenToken()
                )
        }

        callBlockItem = CodeBlockItemSyntax(item: .stmt(StmtSyntax(DoStmtSyntax(
            throwsClause: throwsClause,
            body: CodeBlockSyntax(statements: [callBlockItem]),
            catchClauses: CatchClauseListSyntax {
                CatchClauseSyntax(
                    CatchItemListSyntax {
                        CatchItemSyntax(
                            pattern: ValueBindingPatternSyntax(
                                bindingSpecifier: .keyword(.let),
                                pattern: IdentifierPatternSyntax(identifier: errorVar)
                            )
                        )
                    }
                ) {
                    // Convert to PythonError if needed
                    let pythonErrorVar: TokenSyntax = .identifier("callPyError")
                    let pythonErrorExpr: ExprSyntax = switch errorType {
                        case .pyError:
                            ExprSyntax(DeclReferenceExprSyntax(baseName: errorVar))
                        default:
                            "SwiftPython.PythonError(\(errorVar))"
                    }
                    CodeBlockItemSyntax(item: .decl(DeclSyntax(
                        VariableDeclSyntax(
                            specifier: .let,
                            name: pythonErrorVar,
                            type: "SwiftPython.PythonError" as TypeSyntax,
                            value: pythonErrorExpr
                        )
                    )))

                    // Raise the error to python
                    CodeBlockItemSyntax(item: .expr(ExprSyntax(
                        FunctionCallExprSyntax(
                            calledExpression: "\(errorVar).raise" as ExprSyntax,
                            leftParen: .leftParenToken(),
                            arguments: LabeledExprListSyntax {},
                            rightParen: .rightParenToken()
                        )
                    )))
                    // Return nil to indicate error
                    CodeBlockItemSyntax(item: .stmt(StmtSyntax(
                        ReturnStmtSyntax(expression: NilLiteralExprSyntax())
                    )))
                }
            }
        ))))
    }
}
