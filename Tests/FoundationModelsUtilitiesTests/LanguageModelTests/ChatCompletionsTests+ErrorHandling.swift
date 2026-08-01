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
  @Suite struct ErrorHandling {
    init() { MockSSEProtocol.reset() }

    @Test func `throws on HTTP error`() async throws {
      MockSSEProtocol.handler = { _ in
        (429, Data("Rate limited".utf8))
      }

      let session = LanguageModelSession(model: makeMockModel())
      await #expect(throws: (any Error).self) {
        try await session.respond(to: "test")
      }
    }

    @Test func `throws on API error embedded in SSE stream`() async throws {
      MockSSEProtocol.handler = { _ in
        (200, MockSSE.apiError(message: "Rate limit exceeded"))
      }

      let session = LanguageModelSession(model: makeMockModel())
      await #expect(throws: (any Error).self) {
        try await session.respond(to: "test")
      }
    }

    @Test func `throws typed OpenRouter error embedded in a completion chunk`() async throws {
      MockSSEProtocol.handler = { _ in
        (
          200,
          MockSSE.openRouterMidStreamError(
            message: "Rate limit exceeded",
            errorType: "rate_limit_exceeded"
          )
        )
      }

      let session = LanguageModelSession(model: makeMockModel())
      do {
        _ = try await session.respond(to: "test")
        Issue.record("Expected the OpenRouter streaming error to be thrown")
      } catch let error as ChatCompletionsLanguageModel.APIError {
        #expect(error.message == "Rate limit exceeded")
        #expect(error.type == "rate_limit_exceeded")
      } catch {
        Issue.record("Unexpected error: \(error)")
      }
    }

    @Test func `API error exposes the provider message`() {
      let error = ChatCompletionsLanguageModel.APIError(
        message: "Provider unavailable",
        type: "provider_unavailable"
      )

      #expect(error.errorDescription == "Provider unavailable")
    }
  }
}
