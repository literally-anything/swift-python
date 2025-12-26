/**
 * Graph.swift
 * SwiftPythonTool
 * 
 * Created by Hunter Baker on 12/23/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

enum PrimitiveType {
    case none
    case bool
    case int(signed: Bool, bitWidth: IntBitWidth)
    case float(FloatType)
    case complex
    case string
    case bytes(mutable: Bool)

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
        case longDouble
    }
}

struct FunctionSignature {
    var arguments: [(label: String?, type: Type)]
    var returnType: Type?
    var errorType: ErrorType? = nil
    var isAsync: Bool = false

    enum ErrorType {
        case any
        case typed(Type)
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
    var name: String
    var signature: FunctionSignature

    init(name: String, signature: FunctionSignature) {
        self.name = name
        self.signature = signature
    }
}

indirect enum Type {
    case primitive(PrimitiveType)
    case tuple([Type])
    case sequence(Type)
    case dict(key: Type, value: Type)
    case function(FunctionSignature, escaping: Bool = true)
}
