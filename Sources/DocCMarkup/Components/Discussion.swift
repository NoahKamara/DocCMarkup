//
//  Discussion.swift
//
//  Copyright © 2024 Noah Kamara.
//

public import Markdown

public struct DiscussionSection {
    public var content: [String]

    /// Creates a new discussion section with the given markup content.
    public init(content: [any Markup]) {
        self.content = content.map { $0.format() }
    }

    public func format() -> String {
        self.content.joined(separator: "\n\n")
    }

    init(content: [String]) {
        self.content = content
    }
}

extension DiscussionSection: Codable {
    public func encode(to encoder: any Encoder) throws {
        try content.encode(to: encoder)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let content = try container.decode([String].self)
        self.init(content: content)
    }
}
