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
              "abstractSection" : [
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
              "abstractSection" : [
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
              "abstractSection" : [
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
              "abstractSection" : [
                "Lorem ipsum dolor sit amet."
              ],
              "discussionSection" : [
                "Some Discussion"
              ],
              "tags" : {

              }
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
              "discussionSection" : [

              ],
              "tags" : {
                "parameters" : [
                  {
                    "contents" : [
                      "foo parameter."
                    ],
                    "isStandalone" : false,
                    "name" : "foo"
                  },
                  {
                    "contents" : [
                      "bar parameter."
                    ],
                    "isStandalone" : false,
                    "name" : "bar"
                  }
                ]
              }
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
              "discussionSection" : [

              ],
              "tags" : {
                "parameters" : [
                  {
                    "contents" : [
                      "a parameter name"
                    ],
                    "isStandalone" : true,
                    "name" : "parameterName"
                  }
                ]
              }
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
              "abstractSection" : [
                "Lorem ipsum dolor sit amet."
              ],
              "discussionSection" : [

              ],
              "tags" : {
                "parameters" : [
                  {
                    "contents" : [
                      "describing bar parameter"
                    ],
                    "isStandalone" : true,
                    "name" : "bar"
                  },
                  {
                    "contents" : [
                      "describing baz parameter"
                    ],
                    "isStandalone" : true,
                    "name" : "baz"
                  }
                ]
              }
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
              "discussionSection" : [

              ],
              "tags" : {
                "throws" : [
                  [
                    "some error"
                  ]
                ]
              }
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
              "discussionSection" : [

              ],
              "tags" : {
                "throws" : [
                  [
                    "some error"
                  ],
                  [
                    "some other error"
                  ]
                ]
              }
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
              "discussionSection" : [

              ],
              "discussionTags" : {
                "returns" : [
                  [
                    "some return type"
                  ]
                ]
              }
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
              "discussionSection" : [

              ],
              "discussionTags" : {
                "returns" : [
                  [
                    "some return type\nsome more text?"
                  ],
                  [
                    "some other return type"
                  ]
                ]
              }
            }
            """#
        }
    }
}
