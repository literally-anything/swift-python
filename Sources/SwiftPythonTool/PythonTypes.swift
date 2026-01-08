/**
 * PythonTypes.swift
 * SwiftPythonTool
 * 
 * Created by Hunter Baker on 12/23/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

import SwiftSyntax

enum PythonTypes {
    typealias TypeInfo = (type: TypeSyntax, name: String)

    static var PyObjectPtr: TypeInfo {
        let name = "Optional<UnsafeMutablePointer<CPython.PyObject>>"
        return ("\(raw: name)", name)
    }
    
    static var PyModuleDef: TypeInfo {
        let name = "CPython.PyModuleDef"
        return ("\(raw: name)", name)
    }
    static var PyModuleDefPtr: TypeInfo {
        let name = "Optional<UnsafeMutablePointer<CPython.PyModuleDef>>"
        return ("\(raw: name)", name)
    }

    static var PySize: TypeInfo {
        let name = "CPython.Py_ssize_t"
        return ("\(raw: name)", name)
    }

    static var PyModuleDef_HEAD_INIT: ExprSyntax {
        return "CPython._get_PyModuleDef_HEAD_INIT()"
    }

    enum ModuleSlots {
        static var Py_mod_exec: ExprSyntax {
            return "CPython.Py_mod_exec"
        }
        static var Py_mod_multiple_interpreters: ExprSyntax {
            return "CPython.Py_mod_multiple_interpreters"
        }
        static var Py_mod_gil: ExprSyntax {
            return "CPython.Py_mod_gil"
        }

        enum Values {
            static var PyCModuleExecSlotFunction: TypeInfo {
                let name = "CPython._PyCModuleExecFunction"
                return ("\(raw: name)", name)
            }

            static var Py_MOD_MULTIPLE_INTERPRETERS_NOT_SUPPORTED: ExprSyntax {
                return makeSlotValue(value: 0)
            }
            static var Py_MOD_MULTIPLE_INTERPRETERS_SUPPORTED: ExprSyntax {
                return makeSlotValue(value: 1)
            }
            static var Py_MOD_PER_INTERPRETER_GIL_SUPPORTED: ExprSyntax {
                return makeSlotValue(value: 2)
            }
            
            static var Py_MOD_GIL_USED: ExprSyntax {
                return makeSlotValue(value: 0)
            }
            static var Py_MOD_GIL_NOT_USED: ExprSyntax {
                return makeSlotValue(value: 1)
            }

            private static func makeSlotValue(value: Int) -> ExprSyntax {
                return "UnsafeMutableRawPointer(bitPattern: \(IntegerLiteralExprSyntax(value)))"
            }
        }
    }

    /// Builds an expression to construct a python PyMethodDef
    static func buildPyMethodDefExpr(
        name: ExprSyntaxProtocol,
        method: ExprSyntaxProtocol,
        flags: ExprSyntaxProtocol,
        doc: ExprSyntaxProtocol
    ) -> FunctionCallExprSyntax {
        return FunctionCallExprSyntax(
            callee: "CPython.PyMethodDef" as ExprSyntax
        ) {
            LabeledExprSyntax(label: "ml_name", expression: name)
            LabeledExprSyntax(label: "ml_meth", expression: method)
            LabeledExprSyntax(label: "ml_flags", expression: flags)
            LabeledExprSyntax(label: "ml_doc", expression: doc)
        }
    }

    /// Builds an expression to construct a python PyModuleDef_Slot
    static func buildPyModuleDefSlotExpr(
        slot: ExprSyntaxProtocol,
        value: ExprSyntaxProtocol
    ) -> FunctionCallExprSyntax {
        return FunctionCallExprSyntax(
            callee: "CPython.PyModuleDef_Slot" as ExprSyntax
        ) {
            LabeledExprSyntax(label: "slot", expression: slot)
            LabeledExprSyntax(label: "value", expression: value)
        }
    }
}

enum PyMethodCallingConvention: ExprSyntax {
    case noArguments = "CPython.METH_NOARGS"
    case singleObject = "CPython.METH_O"
    case fastCall = "CPython.METH_FASTCALL"
    case fastCallKeywords = "CPython.METH_FASTCALL | CPython.METH_KEYWORDS"

    var functionExpr: ExprSyntax {
        rawValue
    }
    var classMethodExpr: ExprSyntax {
        "CPython.METH_CLASS | \(rawValue)"
    }
    var staticMethodExpr: ExprSyntax {
        "CPython.METH_STATIC | \(rawValue)"
    }
    var methodExpr: ExprSyntax {
        "CPython.METH_METHOD | \(rawValue)"
    }

    var isFastCall: Bool {
        self == .fastCall || self == .fastCallKeywords
    }
}

/// Wrap a code block in a do-catch that raises PythonErrors to Python
func pythonCatch(_ block: CodeBlockSyntax, throws: Bool) -> CodeBlockItemSyntax {
    let errorVar: TokenSyntax = .identifier("error")
    return CodeBlockItemSyntax(
        item: CodeBlockItemSyntax.Item.stmt(
            StmtSyntax(
                DoStmtSyntax(
                    throwsClause: `throws` ? ThrowsClauseSyntax(
                        throwsSpecifier: .keyword(.throws),
                        leftParen: .leftParenToken(),
                        type: "SwiftPython.PythonError" as TypeSyntax,
                        rightParen: .rightParenToken()
                    ) : nil,
                    body: block,
                    catchClauses: CatchClauseListSyntax {
                        if `throws` {
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
                    }
                )
            )
        )
    )
}
