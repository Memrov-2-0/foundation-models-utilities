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
public import Observation
import Synchronization

/// A collection of active skill identifiers that tracks which skills
/// have been activated during a language model session.
///
/// Create an instance and pass it to ``Skills`` to provide the backing
/// storage for skill activation state. Because `SkillActivations`
/// conforms to `Observable`, you can use it to drive UI updates or
/// other reactions when the model activates or deactivates skills.
public final class SkillActivations: Sendable {
  private let _registrar = ObservationRegistrar()
  private let _names = Mutex<[String]>([])
  // Observation token — the registrar uses the keyPath only as an
  // identifier, so this value is never meaningfully read or written.
  private nonisolated(unsafe) var _token = 0

  public init() {}

  public func activate(_ name: String) {
    _names.withLock { names in
      guard !names.contains(name) else { return }
      names.append(name)
    }
    _registrar.withMutation(of: self, keyPath: \._token) {}
  }

  public func deactivate(_ name: String) {
    _names.withLock { names in
      names.removeAll(where: { $0 == name })
    }
    _registrar.withMutation(of: self, keyPath: \._token) {}
  }
}

extension SkillActivations: Observable {}

extension SkillActivations: RandomAccessCollection {
  public var startIndex: Int {
    _registrar.access(self, keyPath: \._token)
    return _names.withLock { $0.startIndex }
  }

  public var endIndex: Int {
    _registrar.access(self, keyPath: \._token)
    return _names.withLock { $0.endIndex }
  }

  public subscript(position: Int) -> String {
    _registrar.access(self, keyPath: \._token)
    return _names.withLock { $0[position] }
  }
}
