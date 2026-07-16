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
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import FoundationModels
@testable import FoundationModelsUtilities
import Testing

extension ChatCompletionsTests {
  @Suite struct RequestFormat {
    init() { MockSSEProtocol.reset() }

    @Test func `server tools use the provider wire format`() async throws {
      MockSSEProtocol.handler = { _ in (200, MockSSE.text("Done")) }
      var model = makeMockModel()
      model.serverTools = [.init(type: "openrouter:web_search")]
      let session = LanguageModelSession(model: model)

      _ = try await session.respond(to: "What changed today?")

      let body = try requestBody()
      let tools = try #require(body["tools"] as? [[String: Any]])
      let serverTool = try #require(
        tools.first { $0["type"] as? String == "openrouter:web_search" }
      )
      #expect(serverTool["function"] == nil)
    }

    @Test func `sends model name in request body`() async throws {
      MockSSEProtocol.handler = { _ in (200, MockSSE.text("OK")) }

      let session = LanguageModelSession(model: makeMockModel(name: "foo-mini"))
      let _ = try await session.respond(to: "test")

      let body = try requestBody()
      #expect(body["model"] as? String == "foo-mini")
    }

    @Test func `sends provider session identifier in request body`() async throws {
      MockSSEProtocol.handler = { _ in (200, MockSSE.text("OK")) }

      let session = LanguageModelSession(
        model: makeMockModel(sessionID: "conversation-123")
      )
      _ = try await session.respond(to: "test")

      let body = try requestBody()
      #expect(body["session_id"] as? String == "conversation-123")
    }

    @Test func `enables streaming in request`() async throws {
      MockSSEProtocol.handler = { _ in (200, MockSSE.text("OK")) }

      let session = LanguageModelSession(model: makeMockModel())
      let _ = try await session.respond(to: "test")

      let body = try requestBody()
      #expect(body["stream"] as? Bool == true)
    }

    @Test func `includes messages in request`() async throws {
      MockSSEProtocol.handler = { _ in (200, MockSSE.text("OK")) }

      let model = makeMockModel()
      let instructions = Instructions { "Always respond in rhyme" }
      let session = LanguageModelSession(model: model, instructions: instructions)
      let _ = try await session.respond(to: "Hello!")

      let body = try requestBody()
      let messages = body["messages"] as? [[String: Any]]
      #expect(messages != nil)
      #expect((messages?.count ?? 0) >= 2)

      #expect(messages?.first?["role"] as? String == "system")
      #expect(messages?.last?["role"] as? String == "user")
    }

    @Test func `merges custom headers with defaults`() async throws {
      MockSSEProtocol.handler = { _ in (200, MockSSE.text("OK")) }

      let model = makeMockModel(
        headers: ["X-Custom": "value", "Authorization": "Bearer key"]
      )
      let session = LanguageModelSession(model: model)
      let _ = try await session.respond(to: "test")

      let request = try capturedRequest()
      #expect(request.value(forHTTPHeaderField: "X-Custom") == "value")
      #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer key")
      #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test func `appends chat completions endpoint to base URL`() async throws {
      MockSSEProtocol.handler = { _ in (200, MockSSE.text("OK")) }

      let session = LanguageModelSession(model: makeMockModel())
      let _ = try await session.respond(to: "test")

      let request = try capturedRequest()
      #expect(request.url?.path.hasSuffix("/chat/completions") == true)
    }
  }
}
