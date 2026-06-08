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
@testable import FoundationModelsUtilities
import FoundationModels
import Testing

struct SkillTests {
  // MARK: - Prompt Skill (String init)

  @Test func `string init creates prompt skill`() {
    let skill = Skill(name: "voice", description: "Applies a writing style", prompt: "guidelines")
    #expect(skill.name == "voice")
    #expect(skill.description == "Applies a writing style")
    guard case .prompt = skill.storage else {
      Issue.record("Expected .prompt storage")
      return
    }
  }

  // MARK: - Instructions Skill (allowsDeactivation init)

  @Test func `instructions init creates instructions skill`() {
    let skill = Skill(
      name: "calendar",
      description: "Calendar access",
      instructions: "Calendar instructions",
      allowsDeactivation: false,
    )
    #expect(skill.name == "calendar")
    #expect(skill.description == "Calendar access")
    guard case .instructions = skill.storage else {
      Issue.record("Expected .instructions storage")
      return
    }
  }

  @Test func `instructions init respects allowsDeactivation true`() {
    let skill = Skill(
      name: "calendar",
      description: "Calendar access",
      instructions: "Calendar instructions",
      allowsDeactivation: true
    )
    guard case .instructions(let stored) = skill.storage else {
      Issue.record("Expected .instructions storage")
      return
    }
    #expect(stored.allowsDeactivation == true)
  }

  @Test func `instructions init respects allowsDeactivation false`() {
    let skill = Skill(
      name: "calendar",
      description: "Calendar access",
      instructions: "Calendar instructions",
      allowsDeactivation: false
    )
    guard case .instructions(let stored) = skill.storage else {
      Issue.record("Expected .instructions storage")
      return
    }
    #expect(stored.allowsDeactivation == false)
  }

  // MARK: - Instructions Skill (callbacks)

  @Test func `onActivate without allowsDeactivation defaults to false`() {
    let skill = Skill(
      name: "calendar",
      description: "Calendar access",
      instructions: "Calendar instructions",
      onActivate: {}
    )
    guard case .instructions(let stored) = skill.storage else {
      Issue.record("Expected .instructions storage")
      return
    }
    #expect(stored.allowsDeactivation == false)
  }

  @Test func `allowsDeactivation with callbacks`() {
    let skill = Skill(
      name: "calendar",
      description: "Calendar access",
      instructions: "Calendar instructions",
      allowsDeactivation: true,
      onActivate: {},
      onDeactivate: {}
    )
    guard case .instructions(let stored) = skill.storage else {
      Issue.record("Expected .instructions storage")
      return
    }
    #expect(stored.allowsDeactivation == true)
  }
}
