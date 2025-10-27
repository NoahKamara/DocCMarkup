//
//  ParsingTests.swift
//
//  Copyright © 2024 Noah Kamara.
//

@testable import DocCMarkup
import InlineSnapshotTesting
import SwiftSyntax
import Testing

@Suite("Parsing")
struct ParsingTests {
    @Test
    func trimsLineCommentMetadata() {
        let trivia: Trivia = [.docLineComment("/// Lorem ipsum dolor sit amet.")]

        assertInlineSnapshot(of: DocumentationMarkup(trivia: trivia), as: .json) {
            """
            {
              "abstract" : [
                "Lorem ipsum dolor sit amet."
              ]
            }
            """
        }
    }

    @Test(arguments: [
        "/**Lorem ipsum dolor sit amet.*/",
        """
        /** 
        Lorem ipsum dolor sit amet.
        */
        """,
    ])
    func trimsBlockCommentMetadata(text: String) {
        let trivia: Trivia = [.docBlockComment(text)]

        assertInlineSnapshot(of: DocumentationMarkup(trivia: trivia), as: .json) {
            """
            {
              "abstract" : [
                "Lorem ipsum dolor sit amet."
              ]
            }
            """
        }
    }

    @Test
    func abstract() {
        let markup = DocumentationMarkup(
            parsing: """
            Lorem ipsum dolor sit amet.
            """
        )

        assertInlineSnapshot(of: markup, as: .json) {
            """
            {
              "abstract" : [
                "Lorem ipsum dolor sit amet."
              ]
            }
            """
        }
    }

    @Test
    func discussion() {
        let markup = DocumentationMarkup(
            parsing: """
            Lorem ipsum dolor sit amet.

            Some Discussion
            """
        )

        assertInlineSnapshot(of: markup, as: .json) {
            """
            {
              "abstract" : [
                "Lorem ipsum dolor sit amet."
              ],
              "discussion" : [
                "Some Discussion"
              ]
            }
            """
        }
    }

    @Test
    func parameters() {
        let markup = DocumentationMarkup(
            parsing: """
            - Parameters:
                - foo: foo parameter.
                - bar: bar parameter.
            """
        )

        assertInlineSnapshot(of: markup, as: .json) {
            """
            {
              "parameters" : [
                {
                  "contents" : [
                    "foo parameter."
                  ],
                  "name" : "foo"
                },
                {
                  "contents" : [
                    "bar parameter."
                  ],
                  "name" : "bar"
                }
              ]
            }
            """
        }
    }

    @Test("Standalone Parameter")
    func standaloneParameter() async throws {
        let documentation = DocumentationMarkup(
            parsing: """
            - Parameter parameterName: a parameter name
            """
        )

        assertInlineSnapshot(of: documentation, as: .json) {
            """
            {
              "parameters" : [
                {
                  "contents" : [
                    "a parameter name"
                  ],
                  "name" : "parameterName"
                }
              ]
            }
            """
        }
    }

    @Test("Standalone Parameter multiple")
    func multipleStandaloneParameter() async throws {
        let documentation = DocumentationMarkup(
            parsing: """
            Lorem ipsum dolor sit amet.
            - Parameter bar: describing bar parameter
            - Parameter baz: describing baz parameter
            """
        )

        assertInlineSnapshot(of: documentation, as: .json) {
            """
            {
              "abstract" : [
                "Lorem ipsum dolor sit amet."
              ],
              "parameters" : [
                {
                  "contents" : [
                    "describing bar parameter"
                  ],
                  "name" : "bar"
                },
                {
                  "contents" : [
                    "describing baz parameter"
                  ],
                  "name" : "baz"
                }
              ]
            }
            """
        }
    }

    @Test("Throws")
    func throwsDescription() async throws {
        let documentation = DocumentationMarkup(
            parsing: """

            - Throws: some error
            """
        )

        assertInlineSnapshot(of: documentation, as: .json) {
            """
            {
              "throws" : [
                [
                  "some error"
                ]
              ]
            }
            """
        }
    }

    @Test("Throws multiple")
    func multipleThrowsDescription() async throws {
        let documentation = DocumentationMarkup(
            parsing: """

            - Throws: some error
            - Throws: some other error
            """
        )

        assertInlineSnapshot(of: documentation, as: .json) {
            """
            {
              "throws" : [
                [
                  "some error"
                ],
                [
                  "some other error"
                ]
              ]
            }
            """
        }
    }

    @Test("Returns")
    func returns() async throws {
        let documentation = DocumentationMarkup(
            parsing: """
            - Returns: some return type
            """
        )

        assertInlineSnapshot(of: documentation, as: .json) {
            """
            {
              "returns" : [
                [
                  "some return type"
                ]
              ]
            }
            """
        }
    }

    @Test("Returns multiple")
    func multipleReturnsStatement() async throws {
        let documentation = DocumentationMarkup(
            parsing: """
            - Returns: some return type
            some more text?
            - Returns: some other return type
            """
        )

        assertInlineSnapshot(of: documentation, as: .json) {
            #"""
            {
              "returns" : [
                [
                  "some return type\nsome more text?"
                ],
                [
                  "some other return type"
                ]
              ]
            }
            """#
        }
    }

    @Test
    func fullExample() async throws {
        let markup = DocumentationMarkup(parsing: """
        /// does something with foo and bar
        /// - Parameter foo: The foo parameter
        /// - Parameter bar: The bar parameter
        /// - Returns: The foobar result
        /// - Throws: An error if the foo couldn't bar
        """)

        assertInlineSnapshot(of: markup, as: .json) {
            """
            {
              "abstract" : [
                "does something with foo and bar"
              ],
              "parameters" : [
                {
                  "contents" : [
                    "The foo parameter"
                  ],
                  "name" : "foo"
                },
                {
                  "contents" : [
                    "The bar parameter"
                  ],
                  "name" : "bar"
                }
              ],
              "returns" : [
                [
                  "The foobar result"
                ]
              ],
              "throws" : [
                [
                  "An error if the foo couldn’t bar"
                ]
              ]
            }
            """
        }
    }
}
