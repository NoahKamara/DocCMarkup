//
//  DocumentationMarkup+Codable.swift
//
//  Copyright © 2024 Noah Kamara.
//

extension DocumentationMarkup: Encodable {
    enum CodingKeys: String, CodingKey {
        case abstractSection = "abstract"
        case discussionSection = "discussion"
        case parameters
        case httpResponses
        case httpParameters
        case httpBody
        case returns
        case `throws`
        case otherTags
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        if let abstract = abstractSection?.content, !abstract.isEmpty {
            try container.encode(abstract, forKey: .abstractSection)
        }

        if let discussion = discussionSection?.content, !discussion.isEmpty {
            try container.encode(discussion, forKey: .discussionSection)
        }

        guard let tags else { return }

        if !tags.parameters.isEmpty {
            try container.encode(tags.parameters, forKey: .parameters)
        }
        if !tags.httpResponses.isEmpty {
            try container.encode(tags.httpResponses, forKey: .httpResponses)
        }
        if !tags.httpParameters.isEmpty {
            try container.encode(tags.httpParameters, forKey: .httpParameters)
        }
        if let httpBody = tags.httpBody {
            try container.encode(httpBody, forKey: .httpBody)
        }
        if !tags.returns.isEmpty {
            try container.encode(tags.returns, forKey: .returns)
        }
        if !tags.throws.isEmpty {
            try container.encode(tags.throws, forKey: .throws)
        }
        if !tags.otherTags.isEmpty {
            try container.encode(tags.otherTags, forKey: .otherTags)
        }
    }
}
