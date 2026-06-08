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
public import FoundationModels

extension LanguageModelSession.DynamicProfile {
  /// Replaces the language model used by this profile, allowing the model
  /// type to change at runtime.
  public func model(
    _ model: any LanguageModel
  ) -> some LanguageModelSession.DynamicProfile {
    self.FoundationModels::model(AnyLanguageModel(model))
  }
}

private struct AnyLanguageModel: LanguageModel {
  var capabilities: LanguageModelCapabilities {
    storage.capabilities
  }

  var executorConfiguration: Executor.Configuration {
    func projectExecutorType<L: LanguageModel>(_ model: L) -> L.Executor.Type {
      L.Executor.self
    }
    return Executor.Configuration(
      storage.executorConfiguration,
      executorType: projectExecutorType(storage)
    )
  }

  private let storage: any LanguageModel

  init(_ storage: any LanguageModel) {
    self.storage = storage
  }
  struct Executor: LanguageModelExecutor {
    fileprivate let storage: any LanguageModelExecutor

    init(configuration: Configuration) throws {
      let executorType = configuration.executorType.swiftType as! any LanguageModelExecutor.Type

      func makeExecutor<E: LanguageModelExecutor>(executorType: E.Type) throws -> E {
        try E.init(configuration: configuration.configuration.base as! E.Configuration)
      }

      self.storage = try makeExecutor(executorType: executorType)
    }

    func respond(
      to request: LanguageModelExecutorGenerationRequest,
      model: AnyLanguageModel,
      streamingInto channel: LanguageModelExecutorGenerationChannel
    ) async throws {
      func projectResponse<E: LanguageModelExecutor>(e: E) async throws {
        let concreteModel = model.storage as! E.Model
        try await e.respond(to: request, model: concreteModel, streamingInto: channel)
      }
      return try await projectResponse(e: storage)
    }

    struct Configuration: Hashable, Equatable, @unchecked Sendable {
      fileprivate let configuration: AnyHashable
      fileprivate let executorType: Metatype
      init(_ configuration: some Hashable, executorType: any LanguageModelExecutor.Type) {
        self.configuration = AnyHashable(configuration)
        self.executorType = Metatype(executorType)
      }
    }

    typealias Model = AnyLanguageModel
  }
}

private struct Metatype: Hashable, Equatable, @unchecked Sendable {
  private let type: UnsafeRawPointer

  init(_ swiftType: Any.Type) {
    type = unsafeBitCast(swiftType, to: UnsafeRawPointer.self)
  }

  var swiftType: Any.Type {
    unsafeBitCast(type, to: (Any.Type).self)
  }
}
