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
  @Suite struct Configuration {
    init() { MockSSEProtocol.reset() }

    @Test func `stores provided properties`() {
      let url = URL(string: "https://api.example.com/v1")!
      let model = ChatCompletionsLanguageModel(
        name: "foo",
        url: url,
        additionalHeaders: ["Authorization": "Bearer test"],
        supportsGuidedGeneration: false,
        serverTools: [.init(type: "provider:web_search")],
        plugins: [.init(id: "context-compression")]
      )
      #expect(model.name == "foo")
      #expect(model.url == url)
      #expect(model.additionalHeaders == ["Authorization": "Bearer test"])
      #expect(model.supportsGuidedGeneration == false)
      #expect(model.serverTools == [.init(type: "provider:web_search")])
      #expect(model.plugins == [.init(id: "context-compression")])
    }

    @Test func `defaults to supporting guided generation`() {
      let model = makeMockModel()
      #expect(model.supportsGuidedGeneration == true)
    }

    @Test func `capabilities include guided generation when supported`() {
      let model = makeMockModel(supportsGuidedGeneration: true)
      #expect(model.capabilities.contains(.vision))
      #expect(model.capabilities.contains(.toolCalling))
      #expect(model.capabilities.contains(.reasoning))
      #expect(model.capabilities.contains(.guidedGeneration))
    }

    @Test func `capabilities exclude guided generation when not supported`() {
      let model = makeMockModel(supportsGuidedGeneration: false)
      #expect(model.capabilities.contains(.vision))
      #expect(model.capabilities.contains(.toolCalling))
      #expect(model.capabilities.contains(.reasoning))
      #expect(!model.capabilities.contains(.guidedGeneration))
    }
  }
}
