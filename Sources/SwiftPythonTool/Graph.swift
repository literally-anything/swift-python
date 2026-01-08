/**
 * Graph.swift
 * SwiftPythonTool
 * 
 * Created by Hunter Baker on 12/23/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

import SwiftSyntax

enum PrimitiveType {
    case bool
    case int(signed: Bool, bitWidth: IntBitWidth)
    case float(FloatType)
    // case complex
    case string
    // case bytes(mutable: Bool)

    enum IntBitWidth: Int {
        case `64` = 64
        case `32` = 32
        case `16` = 16
        case `8` = 8
    }

    enum FloatType {
        case float16
        case float
        case double
    }
}

struct FunctionSignature {
    var arguments: [(label: String?, type: Type, mutable: Bool)]
    var returnType: Type?
    var errorType: ErrorType? = nil
    var isAsync: Bool = false

    enum ErrorType {
        case any
        case typed(TokenSyntax)
        case pyError
    }

    var argumentsType: ArgumentsType {
        if arguments.isEmpty {
            .none
        } else if arguments.contains(where: { $0.label != nil }) {
            .keyword
        } else {
            .positional
        }
    }

    enum ArgumentsType {
        case none
        case positional
        case keyword
    }
}

class GlobalFunction {
    var module: TokenSyntax?
    var name: TokenSyntax
    var signature: FunctionSignature

    init(module: TokenSyntax?, name: TokenSyntax, signature: FunctionSignature) {
        self.module = module
        self.name = name
        self.signature = signature
    }

    var usedName: TokenSyntax {
        if let module {
            "\(module).\(name)"
        } else {
            name
        }
    }
}

indirect enum Type {
    case pyObject
    case object(name: TokenSyntax)
    case opaque(conformsTo: [TokenSyntax])
    case tuple([Type])
    case function(FunctionSignature, escaping: Bool = true)
    case unsupported(name: String)
}
