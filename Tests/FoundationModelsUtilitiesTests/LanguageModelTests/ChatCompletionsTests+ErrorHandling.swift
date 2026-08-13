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

    @Test func `preserves OpenRouter receipt from HTTP error`() async throws {
      MockSSEProtocol.responseHeaders = [
        "X-Generation-Id": "gen-http-429",
        "Retry-After": "12",
      ]
      MockSSEProtocol.handler = { _ in
        (
          429,
          Data(
            #"{"error":{"message":"Provider rate limited","code":429,"metadata":{"error_type":"rate_limit_exceeded","provider_code":"quota_exhausted"}},"openrouter_metadata":{"strategy":"latency","attempt":2}}"#.utf8
          )
        )
      }

      let session = LanguageModelSession(model: makeMockModel())
      do {
        _ = try await session.respond(to: "test")
        Issue.record("Expected the OpenRouter HTTP error to be thrown")
      } catch let error as ChatCompletionsLanguageModel.APIError {
        #expect(error.message == "Provider rate limited")
        #expect(error.type == "rate_limit_exceeded")
        #expect(error.code == "429")
        #expect(error.providerCode == "quota_exhausted")
        #expect(error.generationID == "gen-http-429")
        #expect(error.statusCode == 429)
        #expect(error.retryAfterSeconds == 12)
        #expect(error.routerMetadata?.strategy == "latency")
        #expect(error.routerMetadata?.attempt == 2)
      } catch {
        Issue.record("Unexpected error: \(error)")
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
        #expect(error.generationID == "gen-1")
        #expect(error.statusCode == nil)
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
