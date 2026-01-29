//
//  Throw.swift
//
//  Copyright © 2024 Noah Kamara.
//

public import Markdown

/// Documentation about a symbol's potential errors.
public struct Throw {
    /// The content that describe potential errors for a symbol.
    public var contents: [String]

    /// Initialize a value to describe documentation about a symbol's potential errors.
    /// - Parameter contents: The content that describe potential errors for this symbol.
    public init(contents: [any Markup]) {
        self.contents = contents.map { $0.format() }
    }

    init(contents: [String]) {
        self.contents = contents
    }
}

extension Throw: Codable {
    public func encode(to encoder: any Encoder) throws {
        try self.contents.encode(to: encoder)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let content = try container.decode([String].self)
        self.init(contents: content)
    }
}
