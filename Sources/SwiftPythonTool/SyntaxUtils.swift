/**
 * SyntaxUtils.swift
 * SwiftPythonTool
 * 
 * Created by Hunter Baker on 12/24/2025
 * Copyright (C) 2025-2025, by Hunter Baker hunterbaker@me.com
 */

import SwiftSyntax
import SwiftSyntaxBuilder

// Disable documentation generation so the generated symbols don't appear in the symbolgraph
// as the symbolgraph is what is used to determine what to generate.
let noDocsAttribute = AttributeSyntax("_documentation") {
    LabeledExprSyntax(label: "visibility", expression: "private" as ExprSyntax)
}

func buildUnsafeBitCast(source: TokenSyntax, to outType: TypeSyntaxProtocol) -> FunctionCallExprSyntax {
    return FunctionCallExprSyntax(
        callee: DeclReferenceExprSyntax(baseName: .identifier("unsafeBitCast"))
    ) {
        LabeledExprSyntax(expression: DeclReferenceExprSyntax(baseName: source))
        LabeledExprSyntax(label: "to", expression: MemberAccessExprSyntax(base: TypeExprSyntax(type: outType), name: .keyword(.`self`)))
    }
}

extension ImportDeclSyntax {
    init(module: String) {
        self.init(path: [.init(name: .identifier(module))])
    }
}

extension FunctionSignatureSyntax {
    init(
        parameters: FunctionParameterClauseSyntax,
        async isAsync: Bool = false,
        throws throwsClause: ThrowsClauseSyntax? = nil,
        return returnType: (any TypeSyntaxProtocol)? = nil
    ) {
        var effectSpecifiers: FunctionEffectSpecifiersSyntax? = nil
        if isAsync || throwsClause != nil {
            effectSpecifiers = FunctionEffectSpecifiersSyntax(
                asyncSpecifier: isAsync ? .keyword(.async) : nil,
                throwsClause: throwsClause
            )
        }
        self.init(
            parameterClause: parameters,
            effectSpecifiers: effectSpecifiers,
            returnClause: returnType.map { ReturnClauseSyntax(type: $0) }
        )
    }
}

extension VariableDeclSyntax {
    init(
        attributes: AttributeListSyntax = [],
        specifier: Keyword,
        name: TokenSyntax,
        type: TypeSyntaxProtocol,
        value: any ExprSyntaxProtocol
    ) {
        let bindings = PatternBindingListSyntax {
            PatternBindingSyntax(
                pattern: IdentifierPatternSyntax(identifier: name),
                typeAnnotation: TypeAnnotationSyntax(type: type),
                initializer: InitializerClauseSyntax(value: value)
            )
        }
        self.init(attributes: attributes, bindingSpecifier: .keyword(specifier), bindings: bindings)
    }
}

extension ClosureSignatureSyntax.ParameterClause {
    init(@ClosureParameterListBuilder itemsBuilder: () throws -> ClosureParameterListSyntax) rethrows {
        try self.init(
            ClosureParameterClauseSyntax(
                parameters: ClosureParameterListSyntax(itemsBuilder: itemsBuilder)
            )
        )
    }
}
