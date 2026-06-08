//===----------------------------------------------------------------------===//
//
// This source file is part of the Foundation Models open source project.
//
// Copyright © 2024-2027 Apple Inc. and the Foundation Models project authors.
//
// Licensed under the Apache License v2.0
//
// See LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//
import Foundation
import FoundationModels
@testable import FoundationModelsUtilities
import Testing

extension ChatCompletionsTests {
  @Suite struct SSEEdgeCases {
    init() { MockSSEProtocol.reset() }

    @Test func `skips SSE comment lines`() async throws {
      let sseData = Data(
        [
          ": this is a comment",
          #"data: {"id":"1","model":"mock","choices":[{"delta":{"content":"Hello"}}]}"#,
          "",
          ": another comment",
          #"data: {"id":"1","model":"mock","choices":[{"delta":{"content":" World"}}]}"#,
          "",
          "data: [DONE]",
          ""
        ].joined(separator: "\n").utf8
      )

      MockSSEProtocol.handler = { _ in (200, sseData) }

      let session = LanguageModelSession(model: makeMockModel())
      let _ = try await session.respond(to: "test")

      #expect(session.transcript.responseText == "Hello World")
    }

    @Test func `handles empty lines between SSE events`() async throws {
      let sseData = Data(
        [
          #"data: {"id":"1","model":"mock","choices":[{"delta":{"content":"A"}}]}"#,
          "",
          "",
          "",
          #"data: {"id":"1","model":"mock","choices":[{"delta":{"content":"B"}}]}"#,
          "",
          "data: [DONE]",
          ""
        ].joined(separator: "\n").utf8
      )

      MockSSEProtocol.handler = { _ in (200, sseData) }

      let session = LanguageModelSession(model: makeMockModel())
      let _ = try await session.respond(to: "test")

      #expect(session.transcript.responseText == "AB")
    }

    @Test func `handles DONE with leading whitespace`() async throws {
      let sseData = Data(
        [
          #"data: {"id":"1","model":"mock","choices":[{"delta":{"content":"OK"}}]}"#,
          "",
          "data:  [DONE]",
          ""
        ].joined(separator: "\n").utf8
      )

      MockSSEProtocol.handler = { _ in (200, sseData) }

      let session = LanguageModelSession(model: makeMockModel())
      let _ = try await session.respond(to: "test")

      #expect(session.transcript.responseText == "OK")
    }

    @Test func `ignores non-data SSE field lines`() async throws {
      let sseData = Data(
        [
          "event: message",
          "id: 42",
          "retry: 3000",
          #"data: {"id":"1","model":"mock","choices":[{"delta":{"content":"OK"}}]}"#,
          "",
          "data: [DONE]",
          ""
        ].joined(separator: "\n").utf8
      )

      MockSSEProtocol.handler = { _ in (200, sseData) }

      let session = LanguageModelSession(model: makeMockModel())
      let _ = try await session.respond(to: "test")

      #expect(session.transcript.responseText == "OK")
    }
  }
}
