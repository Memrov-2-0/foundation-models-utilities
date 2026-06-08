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
  @Suite struct TextResponse {
    init() { MockSSEProtocol.reset() }

    @Test func `generates text from streamed SSE chunks`() async throws {
      MockSSEProtocol.handler = { _ in
        (200, MockSSE.text("Hello", " world", "!"))
      }

      let session = LanguageModelSession(model: makeMockModel())
      let _ = try await session.respond(to: "Say hello")

      let responseText = session.transcript.responseText
      #expect(responseText == "Hello world!")
    }

    @Test func `handles multi-turn conversation`() async throws {
      MockSSEProtocol.handler = { _ in
        (200, MockSSE.text("Response"))
      }

      let session = LanguageModelSession(model: makeMockModel())
      let _ = try await session.respond(to: "first")
      let _ = try await session.respond(to: "second")

      let prompts = session.transcript.compactMap(\.prompt)
      #expect(prompts.count == 2)
    }
  }
}
