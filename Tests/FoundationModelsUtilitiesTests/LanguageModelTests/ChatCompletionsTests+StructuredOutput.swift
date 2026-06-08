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
#if canImport(Darwin)
import Foundation
import FoundationModels
@testable import FoundationModelsUtilities
import Testing

extension ChatCompletionsTests {
  @Suite struct StructuredOutput {
    init() { MockSSEProtocol.reset() }

    @Generable
    struct MockWeatherInfo {
      var temperature: Int
      var condition: String
    }

    @Test func `parses structured JSON response into Generable type`() async throws {
      MockSSEProtocol.handler = { _ in
        (
          200,
          MockSSE.text(
            #"{"temperature":"#,
            #"72,"#,
            #""condition":"#,
            #""sunny"}"#
          )
        )
      }

      let session = LanguageModelSession(model: makeMockModel())
      let response = try await session.respond(
        to: "Weather?",
        generating: MockWeatherInfo.self
      )

      #expect(response.content.temperature == 72)
      #expect(response.content.condition == "sunny")
    }

    @Test func `includes response format in request for structured output`() async throws {
      MockSSEProtocol.handler = { _ in
        (200, MockSSE.text(#"{"temperature":65,"condition":"cloudy"}"#))
      }

      let session = LanguageModelSession(model: makeMockModel())
      let _ = try await session.respond(
        to: "Weather?",
        generating: MockWeatherInfo.self
      )

      let body = try requestBody()
      let responseFormat = body["response_format"] as? [String: Any]
      #expect(responseFormat != nil)
      #expect(responseFormat?["type"] as? String == "json_schema")

      let jsonSchema = responseFormat?["json_schema"] as? [String: Any]
      #expect(jsonSchema != nil)
    }

    @Test func `parses structured output from single-character chunks`() async throws {
      let json = #"{"temperature":99,"condition":"hot"}"#

      MockSSEProtocol.handler = { _ in
        var lines = [String]()
        for char in json {
          let chunk = String(char)
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
          lines.append(
            #"data: {"id":"1","model":"mock","choices":[{"delta":{"content":"\#(chunk)"}}]}"#
          )
          lines.append("")
        }
        lines.append("data: [DONE]")
        return (200, Data(lines.joined(separator: "\n").utf8))
      }

      let session = LanguageModelSession(model: makeMockModel())
      let response = try await session.respond(
        to: "Weather?",
        generating: MockWeatherInfo.self
      )

      #expect(response.content.temperature == 99)
      #expect(response.content.condition == "hot")
    }
  }
}
#endif
