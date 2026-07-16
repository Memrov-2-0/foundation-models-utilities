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

    @Test func `preserves provider-selected model in response metadata`() async throws {
      MockSSEProtocol.handler = { _ in
        (
          200,
          Data(
            """
            data: {"id":"1","model":"provider/model-v2","choices":[{"delta":{"content":"Hello"}}]}

            data: [DONE]

            """.utf8
          )
        )
      }

      let session = LanguageModelSession(model: makeMockModel(name: "router/auto"))
      _ = try await session.respond(to: "Hello")

      let response = try #require(session.transcript.compactMap(\.response).last)
      #expect(
        response.metadata[ChatCompletionsLanguageModel.MetadataKey.selectedModel]
          as? String == "provider/model-v2"
      )
    }

    @Test func `preserves URL citations in response metadata`() async throws {
      MockSSEProtocol.handler = { _ in
        (
          200,
          Data(
            """
            data: {"id":"1","model":"provider/model-v2","choices":[{"delta":{"content":"Current answer","annotations":[{"type":"url_citation","url_citation":{"url":"https://example.com/source","title":"Example Source","content":"Supporting text","start_index":0,"end_index":14}}]}}]}

            data: [DONE]

            """.utf8
          )
        )
      }

      let session = LanguageModelSession(model: makeMockModel())
      _ = try await session.respond(to: "What changed?")

      let response = try #require(session.transcript.compactMap(\.response).last)
      let citations =
        response.metadata[ChatCompletionsLanguageModel.MetadataKey.urlCitations]
        as? [ChatCompletionsLanguageModel.URLCitation]
      #expect(citations?.count == 1)
      #expect(citations?.first?.url == "https://example.com/source")
      #expect(citations?.first?.title == "Example Source")
    }

    @Test func `preserves generation finish and router metadata`() async throws {
      MockSSEProtocol.handler = { _ in
        (
          200,
          Data(
            """
            data: {"id":"generation-123","model":"provider/model-v2","choices":[{"delta":{"content":"Done"},"finish_reason":null,"native_finish_reason":null}],"openrouter_metadata":{"requested":"openrouter/auto","strategy":"auto","region":"us-west","summary":"Selected one endpoint","attempt":2,"is_byok":false,"pipeline":[{"type":"plugin","name":"context-compression"}]}}

            data: {"id":"generation-123","model":"provider/model-v2","choices":[{"delta":{},"finish_reason":"stop","native_finish_reason":"stop"}]}

            data: [DONE]

            """.utf8
          )
        )
      }

      let session = LanguageModelSession(model: makeMockModel(name: "openrouter/auto"))
      _ = try await session.respond(to: "Hello")

      let response = try #require(session.transcript.compactMap(\.response).last)
      #expect(
        response.metadata[ChatCompletionsLanguageModel.MetadataKey.generationID]
          as? String == "generation-123"
      )
      #expect(
        response.metadata[ChatCompletionsLanguageModel.MetadataKey.finishReason]
          as? String == "stop"
      )
      #expect(
        response.metadata[ChatCompletionsLanguageModel.MetadataKey.nativeFinishReason]
          as? String == "stop"
      )
      let metadata =
        response.metadata[ChatCompletionsLanguageModel.MetadataKey.routerMetadata]
        as? ChatCompletionsLanguageModel.RouterMetadata
      #expect(metadata?.requested == "openrouter/auto")
      #expect(metadata?.strategy == "auto")
      #expect(metadata?.attempt == 2)
      #expect(metadata?.pipeline.map(\.name) == ["context-compression"])
    }
  }
}
