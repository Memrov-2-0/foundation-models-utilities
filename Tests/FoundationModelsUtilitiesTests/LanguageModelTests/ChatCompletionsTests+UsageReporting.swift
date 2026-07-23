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
  @Suite struct UsageReporting {
    init() { MockSSEProtocol.reset() }

    @Test func `requests usage in stream options`() async throws {
      MockSSEProtocol.handler = { _ in (200, MockSSE.text("OK")) }

      let session = LanguageModelSession(model: makeMockModel())
      let _ = try await session.respond(to: "test")

      let body = try requestBody()
      let streamOptions = body["stream_options"] as? [String: Any]
      #expect(streamOptions != nil)
      #expect(streamOptions?["include_usage"] as? Bool == true)
    }

    @Test func `ignores usage chunks without dropping streamed content`() async throws {
      MockSSEProtocol.handler = { _ in
        (
          200,
          MockSSE.chunks(
            [
              MockSSE.Chunk(text: "Hello"),
              MockSSE.Chunk(text: " world"),
              MockSSE.Chunk(
                usage: MockSSE.Chunk.Usage(
                  promptTokens: 12,
                  completionTokens: 7
                )
              )
            ]
          )
        )
      }

      let session = LanguageModelSession(model: makeMockModel())
      let response = try await session.respond(to: "Say hello")

      #expect(response.content == "Hello world")
    }
  }
}
