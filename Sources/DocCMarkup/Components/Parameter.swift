//
//  Parameter.swift
//
//  Copyright © 2024 Noah Kamara.
//

public import Markdown

/// A section that contains a function's parameters.
public struct ParametersSection {
    /// The list of function parameters.
    public let parameters: [Parameter]
}

/// Documentation about a parameter for a symbol.
public struct Parameter: Codable {
    /// The name of the parameter.
    public var name: String
    /// The content that describe the parameter.
    public var contents: [String]

    /// Initialize a value to describe documentation about a parameter for a symbol.
    /// - Parameters:
    ///   - name: The name of this parameter.
    ///   - contents: The content that describe this parameter.
    /// parameters outline.
    public init(
        name: String,
        nameRange: SourceRange? = nil,
        contents: [any Markup],
        range: SourceRange? = nil,
        isStandalone: Bool = false
    ) {
        self.name = name
        self.contents = contents.map { $0.format() }
    }

    /// Initialize a value to describe documentation about a symbol's parameter via a Doxygen
    /// `\param` command.
    ///
    /// - Parameter doxygenParameter: A parsed Doxygen `\param` command.
    public init(_ doxygenParameter: DoxygenParameter) {
        self.name = doxygenParameter.name
        self.contents = Array(doxygenParameter.children).map { $0.format() }
    }
}
