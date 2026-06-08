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

    @Test func `reports prompt and completion token counts from usage chunk`() async throws {
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

      #expect(response.usage.input.totalTokenCount == 12)
      #expect(response.usage.output.totalTokenCount == 7)
    }

    @Test func `reports cached and reasoning token counts when present`() async throws {
      MockSSEProtocol.handler = { _ in
        (
          200,
          MockSSE.chunks([
            MockSSE.Chunk(text: "Done"),
            MockSSE.Chunk(
              usage: MockSSE.Chunk.Usage(
                promptTokens: 30,
                completionTokens: 15,
                cachedTokens: 20,
                reasoningTokens: 4
              )
            )
          ])
        )
      }

      let session = LanguageModelSession(model: makeMockModel())
      let response = try await session.respond(to: "Think carefully")

      #expect(response.usage.input.totalTokenCount == 30)
      #expect(response.usage.input.cachedTokenCount == 20)
      #expect(response.usage.output.totalTokenCount == 15)
      #expect(response.usage.output.reasoningTokenCount == 4)
    }

    @Test func `defaults cached and reasoning tokens to zero when omitted`() async throws {
      MockSSEProtocol.handler = { _ in
        (
          200,
          MockSSE.chunks(
            [
              MockSSE.Chunk(text: "Hi"),
              MockSSE.Chunk(
                usage: MockSSE.Chunk.Usage(promptTokens: 5, completionTokens: 2)
              )
            ]
          )
        )
      }

      let session = LanguageModelSession(model: makeMockModel())
      let response = try await session.respond(to: "test")

      #expect(response.usage.input.cachedTokenCount == 0)
      #expect(response.usage.output.reasoningTokenCount == 0)
    }

    @Test func `reports final cumulative tokens when usage streams with each chunk`() async throws {
      // Some servers emit a `usage` snapshot on every chunk with running
      // cumulative totals. The framework treats updateUsage as wholesale
      // replacement, so the final reported usage should reflect the last
      // cumulative value.
      MockSSEProtocol.handler = { _ in
        (
          200,
          MockSSE.chunks([
            MockSSE.Chunk(
              text: "Hello",
              usage: MockSSE.Chunk.Usage(promptTokens: 8, completionTokens: 1)
            ),
            MockSSE.Chunk(
              text: " there",
              usage: MockSSE.Chunk.Usage(promptTokens: 8, completionTokens: 2)
            ),
            MockSSE.Chunk(
              text: "!",
              usage: MockSSE.Chunk.Usage(promptTokens: 8, completionTokens: 3)
            )
          ])
        )
      }

      let session = LanguageModelSession(model: makeMockModel())
      let response = try await session.respond(to: "Greet me")

      #expect(response.content == "Hello there!")
      #expect(response.usage.input.totalTokenCount == 8)
      #expect(response.usage.output.totalTokenCount == 3)
    }

    @Test func `accepts text and usage in the same chunk`() async throws {
      // Verifies that a single chunk carrying both `delta.content` and
      // `usage` is processed without dropping either piece — the text is
      // streamed and the usage is reported.
      MockSSEProtocol.handler = { _ in
        (
          200,
          MockSSE.chunks([
            MockSSE.Chunk(
              text: "Done",
              usage: MockSSE.Chunk.Usage(promptTokens: 4, completionTokens: 1)
            )
          ])
        )
      }

      let session = LanguageModelSession(model: makeMockModel())
      let response = try await session.respond(to: "ping")

      #expect(response.content == "Done")
      #expect(response.usage.input.totalTokenCount == 4)
      #expect(response.usage.output.totalTokenCount == 1)
    }
  }
}
