/**
 * ModuleDefinition.swift
 * SwiftPythonTool
 * 
 * Created by Hunter Baker on 12/23/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

import SwiftSyntax

func generateModuleDefinition(
    pythonModuleName: String,
    globalFunctions: [GlobalFunctionInfo]
) -> (imports: [ImportDeclSyntax], contents: [CodeBlockItemSyntax]) {
    let imports = [
        ImportDeclSyntax(module: "Synchronization")
    ]
    var contents: [CodeBlockItemSyntax] = []

    let moduleDefStorageVar: TokenSyntax = .identifier("_\(pythonModuleName)_moduleDefinition")
    let entrypointFunc: TokenSyntax = .identifier("_PyInit_\(pythonModuleName)")
    let execFunc: TokenSyntax = .identifier("_\(pythonModuleName)_exec")

    // The storage for the static module definition
    let moduleDefStorageDecl = VariableDeclSyntax(
        attributes: [.attribute(noDocsAttribute)],
        specifier: .let,
        name: moduleDefStorageVar,
        type: "Synchronization.Mutex<\(PythonTypes.PyModuleDefPtr.type)>" as TypeSyntax,
        value: "Synchronization.Mutex(nil)" as ExprSyntax
    )
    contents.append(CodeBlockItemSyntax(item: .decl(.init(moduleDefStorageDecl))))

    // The entrypoint that CPython calls when importing the module.
    // This sets up metadata, global functions, and slots.
    let entrypointFuncDecl = FunctionDeclSyntax(
        attributes: .init {
            noDocsAttribute
            AttributeSyntax("_cdecl") {
                LabeledExprSyntax(expression: StringLiteralExprSyntax(content: "PyInit_\(pythonModuleName)"))
            }
        },
        name: entrypointFunc,
        signature: FunctionSignatureSyntax(
            parameters: FunctionParameterClauseSyntax {},
            return: PythonTypes.PyObjectPtr.type
        )
    ) {
        let modulePtrVar: TokenSyntax = .identifier("pyModulePtr")
        let moduleDefVar: TokenSyntax = .identifier("pyModuleDef")
        // Wait for the mutex so that the definition only gets initialized once.
        // It is normally statically allocated in C, so this is safe with the GIL off and with subinterpreters.
        VariableDeclSyntax(
            specifier: .let,
            name: modulePtrVar,
            type: PythonTypes.PyModuleDefPtr.type,
            value: FunctionCallExprSyntax(
                callee: "\(moduleDefStorageVar).withLock" as ExprSyntax
            ) {
                LabeledExprSyntax(
                    expression: ClosureExprSyntax(
                        signature: ClosureSignatureSyntax(
                            parameterClause: .init {
                                ClosureParameterSyntax(firstName: moduleDefVar)
                            },
                            returnClause: ReturnClauseSyntax(type: PythonTypes.PyModuleDefPtr.type)
                        )
                    ) {
                        // When the module definition is nil, make it first
                        IfExprSyntax(
                            conditions: .init {
                                ConditionElementSyntax(condition: .expression("\(moduleDefVar) == nil"))
                            },
                            body: buildModuleDefinition(
                                pyModuleName: pythonModuleName,
                                moduleDefVar: moduleDefVar,
                                execFunc: execFunc,
                                globalFunctions: globalFunctions
                            )
                        )
                        ReturnStmtSyntax(expression: "\(moduleDefVar)" as ExprSyntax)
                    }
                )
            }
        )
        ReturnStmtSyntax(
            expression: FunctionCallExprSyntax(
                calledExpression: "CPython.PyModuleDef_Init" as ExprSyntax,
                leftParen: .leftParenToken(),
                rightParen: .rightParenToken()
            ) {
                LabeledExprSyntax(expression: DeclReferenceExprSyntax(baseName: modulePtrVar))
            }
        )
    }
    contents.append(CodeBlockItemSyntax(item: .decl(.init(entrypointFuncDecl))))

    let execFuncDecl = FunctionDeclSyntax(
        attributes: .init {
            noDocsAttribute
        },
        name: execFunc,
        signature: FunctionSignatureSyntax(
            parameters: FunctionParameterClauseSyntax {
                FunctionParameterSyntax(firstName: .identifier("module"), type: PythonTypes.PyObjectPtr.type)
            },
            return: "CInt" as TypeSyntax
        )
    ) {
        ReturnStmtSyntax(expression: 0 as IntegerLiteralExprSyntax)
    }
    contents.append(CodeBlockItemSyntax(item: .decl(.init(execFuncDecl))))

    return (imports, contents)
}

/// Build the code block that constructs the module definition structure
private func buildModuleDefinition(
    pyModuleName: String,
    moduleDefVar: TokenSyntax,
    execFunc: TokenSyntax,
    globalFunctions: [GlobalFunctionInfo]
) -> CodeBlockSyntax {
    var codeBlock = CodeBlockSyntax(statements: CodeBlockItemListSyntax())

    // Make a StaticString for the module name so that it has a stable address
    let moduleNameVar: TokenSyntax = .identifier("pyModuleName")
    let moduleNameStorageDecl = VariableDeclSyntax(
        specifier: .let,
        name: moduleNameVar,
        type: "StaticString" as TypeSyntax,
        value: StringLiteralExprSyntax(content: pyModuleName)
    )
    codeBlock.statements.append(CodeBlockItemSyntax(item: .decl(.init(moduleNameStorageDecl))))

    let methodsBufferVar: TokenSyntax = buildMethodsBuffer(codeBlock: &codeBlock, pyModuleName: pyModuleName, globalFunctions: globalFunctions)
    let slotsBufferVar: TokenSyntax = buildSlotsBuffer(codeBlock: &codeBlock, pyModuleName: pyModuleName, execFunc: execFunc, enaleSubinterpreters: true, isThreadSafe: true)

    // Initialize inline to the stack
    let moduleDefInlineVar: TokenSyntax = .identifier("pyModuleDefInline")
    let moduleDefInlineDecl = VariableDeclSyntax(
        specifier: .let,
        name: moduleDefInlineVar,
        type: PythonTypes.PyModuleDef.type,
        value: FunctionCallExprSyntax(
            callee: TypeExprSyntax(type: PythonTypes.PyModuleDef.type)
        ) {
            LabeledExprSyntax(label: "m_base", expression: PythonTypes.PyModuleDef_HEAD_INIT)
            LabeledExprSyntax(label: "m_name", expression: "\(moduleNameVar)._cStringStart" as ExprSyntax)
            LabeledExprSyntax(label: "m_doc", expression: NilLiteralExprSyntax())
            LabeledExprSyntax(label: "m_size", expression: 0 as IntegerLiteralExprSyntax)
            LabeledExprSyntax(label: "m_methods", expression: "\(methodsBufferVar).baseAddress" as ExprSyntax)
            LabeledExprSyntax(label: "m_slots", expression: "\(slotsBufferVar).baseAddress" as ExprSyntax)
            LabeledExprSyntax(label: "m_traverse", expression: NilLiteralExprSyntax())
            LabeledExprSyntax(label: "m_clear", expression: NilLiteralExprSyntax())
            LabeledExprSyntax(label: "m_free", expression: NilLiteralExprSyntax())
        }
    )
    codeBlock.statements.append(CodeBlockItemSyntax(item: .decl(.init(moduleDefInlineDecl))))

    // Allocate a heap block for the module definition to live and move it there
    let moduleDefAllocVar: TokenSyntax = .identifier("pyModuleDefAlloc")
    let moduleDefAllocType: TypeSyntax = "UnsafeMutablePointer<\(PythonTypes.PyModuleDef.type)>"
    let moduleDefAllocDecl = VariableDeclSyntax(
        specifier: .let,
        name: moduleDefAllocVar,
        type: moduleDefAllocType,
        value: FunctionCallExprSyntax(
            callee: "\(moduleDefAllocType).allocate" as ExprSyntax
        ) {
            LabeledExprSyntax(label: "capacity", expression: 1 as IntegerLiteralExprSyntax)
        }
    )
    codeBlock.statements.append(CodeBlockItemSyntax(item: .decl(.init(moduleDefAllocDecl))))
    let moduleDefAllocInitExpr = FunctionCallExprSyntax(
        callee: "\(moduleDefAllocVar).initialize" as ExprSyntax
    ) {
        LabeledExprSyntax(label: "to", expression: DeclReferenceExprSyntax(baseName: moduleDefInlineVar))
    }
    codeBlock.statements.append(CodeBlockItemSyntax(item: .expr(.init(moduleDefAllocInitExpr))))

    // Asign the module definition pointer to the mutex storage
    let moduleDefMutexAssignmentExpr = SequenceExprSyntax {
        DeclReferenceExprSyntax(baseName: moduleDefVar)
        AssignmentExprSyntax()
        DeclReferenceExprSyntax(baseName: moduleDefAllocVar)
    }
    codeBlock.statements.append(CodeBlockItemSyntax(item: .expr(.init(moduleDefMutexAssignmentExpr))))

    return codeBlock
}

private func buildMethodsBuffer(
    codeBlock: inout CodeBlockSyntax,
    pyModuleName: String,
    globalFunctions: [GlobalFunctionInfo]
) -> TokenSyntax {
    let methodsBufferVar: TokenSyntax = .identifier("pyModuleMethods")

    // Make the array of methods using the swift global functions.
    let methodsBufferStorageDecl = VariableDeclSyntax(
        specifier: .let,
        name: methodsBufferVar,
        type: "UnsafeMutableBufferPointer<CPython.PyMethodDef>" as TypeSyntax,
        value: FunctionCallExprSyntax(
            callee: "UnsafeMutableBufferPointer<CPython.PyMethodDef>.allocate" as ExprSyntax
        ) {
            // We need one extra allocated element for the null terminator to mark the end of the array.
            LabeledExprSyntax(label: "capacity", expression: IntegerLiteralExprSyntax(globalFunctions.count + 1))
        }
    )
    codeBlock.statements.append(CodeBlockItemSyntax(item: .decl(.init(methodsBufferStorageDecl))))

    func buildMethodAssignment(index: Int, methodDef: FunctionCallExprSyntax) -> SequenceExprSyntax {
        return SequenceExprSyntax {
            SubscriptCallExprSyntax(
                calledExpression: DeclReferenceExprSyntax(baseName: methodsBufferVar)
            ) {
                LabeledExprSyntax(expression: IntegerLiteralExprSyntax(index))
            }
            AssignmentExprSyntax()
            methodDef
        }
    }

    // Initialize the last element to null so it marks the end properly.
    let assignLastMethodExpr = buildMethodAssignment(
        index: globalFunctions.count,
        methodDef: PythonTypes.buildPyMethodDefExpr(
            name: NilLiteralExprSyntax(),
            method: NilLiteralExprSyntax(),
            flags: 0 as IntegerLiteralExprSyntax,
            doc: NilLiteralExprSyntax()
        )
    )
    codeBlock.statements.append(CodeBlockItemSyntax(item: .expr(.init(assignLastMethodExpr))))
    
    // Setup each global function
    for (index, info) in globalFunctions.enumerated() {
        let methodNameVar: TokenSyntax = .identifier("function_\(info.func.name)_name")
        let methodVar: TokenSyntax = .identifier("function_\(info.func.name)")

        let methodNameDecl = VariableDeclSyntax(
            specifier: .let,
            name: methodNameVar,
            type: "StaticString" as TypeSyntax,
            value: StringLiteralExprSyntax(content: info.func.name)
        )
        codeBlock.statements.append(CodeBlockItemSyntax(item: .decl(.init(methodNameDecl))))

        let methodType: TypeSyntax =
            switch info.callingConvention {
                case .noArguments, .singleObject:
                    "CPython.PyCFunction"
                case .fastCall:
                    "CPython.PyCFunctionFast"
                case .fastCallKeywords:
                    "CPython.PyCFunctionFastWithKeywords"
            }
        let methodDecl = VariableDeclSyntax(
            specifier: .let,
            name: methodVar,
            type: methodType,
            value: DeclReferenceExprSyntax(baseName: info.glueName)
        )
        codeBlock.statements.append(CodeBlockItemSyntax(item: .decl(.init(methodDecl))))

        let methodExpr: ExprSyntax = 
            if info.callingConvention.isFastCall {
                ExprSyntax(buildUnsafeBitCast(source: methodVar, to: "CPython.PyCFunction" as TypeSyntax))
            } else {
                ExprSyntax(DeclReferenceExprSyntax(baseName: methodVar))
            }
        let methodDef = buildMethodAssignment(
            index: index,
            methodDef: PythonTypes.buildPyMethodDefExpr(
                name: "\(methodNameVar)._cStringStart" as ExprSyntax,
                method: methodExpr,
                flags: info.callingConvention.functionExpr,
                doc: NilLiteralExprSyntax()
            )
        )
        codeBlock.statements.append(CodeBlockItemSyntax(item: .expr(.init(methodDef))))
    }

    return methodsBufferVar
}

private func buildSlotsBuffer(
    codeBlock: inout CodeBlockSyntax,
    pyModuleName: String,
    execFunc: TokenSyntax,
    enaleSubinterpreters: Bool,
    isThreadSafe: Bool
) -> TokenSyntax {
    let slotsBufferVar: TokenSyntax = .identifier("pyModuleSlots")

    let slotsCount = 3

    // Make the array of slots.
    let slotsBufferStorageDecl = VariableDeclSyntax(
        specifier: .let,
        name: slotsBufferVar,
        type: "UnsafeMutableBufferPointer<CPython.PyModuleDef_Slot>" as TypeSyntax,
        value: FunctionCallExprSyntax(
            callee: "UnsafeMutableBufferPointer<CPython.PyModuleDef_Slot>.allocate" as ExprSyntax
        ) {
            // We need one extra allocated element for the slot 0 to mark the end of the array.
            LabeledExprSyntax(label: "capacity", expression: IntegerLiteralExprSyntax(slotsCount + 1))
        }
    )
    codeBlock.statements.append(CodeBlockItemSyntax(item: .decl(.init(slotsBufferStorageDecl))))

    func buildSlotAssignment(index: Int, slotDef: FunctionCallExprSyntax) -> SequenceExprSyntax {
        return SequenceExprSyntax {
            SubscriptCallExprSyntax(
                calledExpression: DeclReferenceExprSyntax(baseName: slotsBufferVar)
            ) {
                LabeledExprSyntax(expression: IntegerLiteralExprSyntax(index))
            }
            AssignmentExprSyntax()
            slotDef
        }
    }

    // Initialize the last element to slot 0 so it marks the end properly.
    let assignLastSlotExpr = buildSlotAssignment(
        index: slotsCount,
        slotDef: PythonTypes.buildPyModuleDefSlotExpr(
            slot: 0 as IntegerLiteralExprSyntax,
            value: NilLiteralExprSyntax()
        )
    )
    codeBlock.statements.append(CodeBlockItemSyntax(item: .expr(.init(assignLastSlotExpr))))

    // Setup the module exec function slot
    let execMethodVar: TokenSyntax = .identifier("pyModuleExecSlotMethod")
    let execMethodDecl = VariableDeclSyntax(
        specifier: .let,
        name: execMethodVar,
        type: PythonTypes.ModuleSlots.Values.PyCModuleExecSlotFunction.type,
        value: DeclReferenceExprSyntax(baseName: execFunc)
    )
    codeBlock.statements.append(CodeBlockItemSyntax(item: .decl(.init(execMethodDecl))))
    let assignExecSlotExpr = buildSlotAssignment(
        index: 0,
        slotDef: PythonTypes.buildPyModuleDefSlotExpr(
            slot: PythonTypes.ModuleSlots.Py_mod_exec,
            value: buildUnsafeBitCast(source: execMethodVar, to: "Optional<UnsafeMutableRawPointer>" as TypeSyntax)
        )
    )
    codeBlock.statements.append(CodeBlockItemSyntax(item: .expr(.init(assignExecSlotExpr))))

    // Set the subinterpreters slot
    let subinterpretersMode: ExprSyntax =
        if !enaleSubinterpreters {
            PythonTypes.ModuleSlots.Values.Py_MOD_MULTIPLE_INTERPRETERS_NOT_SUPPORTED
        } else if isThreadSafe {
            PythonTypes.ModuleSlots.Values.Py_MOD_PER_INTERPRETER_GIL_SUPPORTED
        } else {
            PythonTypes.ModuleSlots.Values.Py_MOD_MULTIPLE_INTERPRETERS_SUPPORTED
        }
    let assignSubinterpretersSlotExpr = buildSlotAssignment(
        index: 1,
        slotDef: PythonTypes.buildPyModuleDefSlotExpr(
            slot: PythonTypes.ModuleSlots.Py_mod_multiple_interpreters,
            value: subinterpretersMode
        )
    )
    codeBlock.statements.append(CodeBlockItemSyntax(item: .expr(.init(assignSubinterpretersSlotExpr))))

    // Set GIL used slot
    let assignGILSlotExpr = buildSlotAssignment(
        index: 2,
        slotDef: PythonTypes.buildPyModuleDefSlotExpr(
            slot: PythonTypes.ModuleSlots.Py_mod_gil,
            value: isThreadSafe ? PythonTypes.ModuleSlots.Values.Py_MOD_GIL_USED : PythonTypes.ModuleSlots.Values.Py_MOD_GIL_NOT_USED
        )
    )
    codeBlock.statements.append(CodeBlockItemSyntax(item: .expr(.init(assignGILSlotExpr))))

    return slotsBufferVar
}
