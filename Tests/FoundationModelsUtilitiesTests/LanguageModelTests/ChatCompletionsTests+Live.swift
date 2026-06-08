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
  /// Live integration test against a real chat-completions endpoint.
  ///
  /// Configure with environment variables:
  ///   - FMU_TEST_ENDPOINT (required) — base URL, e.g. https://api.openai.com/v1
  ///   - FMU_TEST_MODEL   (optional) — model name (default: gpt-4o-mini)
  ///   - FMU_TEST_API_KEY (optional) — sent as `Authorization: Bearer <key>`
  ///   - FMU_TEST_PROMPT  (optional) — prompt to send
  ///
  /// Example:
  ///   FMU_TEST_ENDPOINT=https://api.openai.com/v1 \
  ///   FMU_TEST_API_KEY=sk-... \
  ///   swift test --filter ChatCompletionsTests.Live
  @Suite(
    "Live",
    .enabled(
      if: ProcessInfo.processInfo.environment["FMU_TEST_ENDPOINT"] != nil,
      "Set FMU_TEST_ENDPOINT to run."
    )
  )
  struct Live {
    @Test func `responds to a real chat completions endpoint`() async throws {
      let env = ProcessInfo.processInfo.environment
      let urlString = try #require(env["FMU_TEST_ENDPOINT"])
      let url = try #require(URL(string: urlString))
      let modelName = env["FMU_TEST_MODEL"] ?? "gpt-4o-mini"
      let prompt =
        env["FMU_TEST_PROMPT"] ?? """
          I'm planning a dinner party for 8 people next Saturday. Three guests \
          are vegetarian, one is gluten-free, and one has a peanut allergy. \
          Suggest a 3-course menu (appetizer, main, dessert) that everyone can \
          eat safely. For each course, give:
            - the dish name,
            - 3-5 key ingredients,
            - approximate prep time.

          Keep the total response under 200 words and don't apologize or \
          editorialize — just give the menu.
          """

      var headers: [String: String] = [:]
      if let key = env["FMU_TEST_API_KEY"] {
        headers["Authorization"] = "Bearer \(key)"
      }

      let model = ChatCompletionsLanguageModel(
        name: modelName,
        url: url,
        additionalHeaders: headers,
        supportsGuidedGeneration: false
      )

      let session = LanguageModelSession(model: model)
      let response = try await session.respond(to: prompt)

      let text = session.transcript.responseText
      print("[Live] endpoint: \(urlString)")
      print("[Live] model:    \(modelName)")
      print("[Live] prompt:   \(prompt)")
      print("[Live] response: \(response.content)")
      print("[Live] transcript text: \(text)")

      #expect(!text.isEmpty, "Expected a non-empty response from the endpoint.")
      #expect(text.count > 50, "Expected a substantive response (>50 chars), got \(text.count).")
    }
  }
}
