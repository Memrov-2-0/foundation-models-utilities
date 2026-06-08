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
import Testing
import FoundationModels
@testable import FoundationModelsUtilities

struct SkillBuilderTests {
  private func buildSkills(@SkillsBuilder _ builder: () -> [Skill]) -> [Skill] {
    builder()
  }

  private func skill(named name: String) -> Skill {
    Skill(name: name, description: "A test skill", prompt: "content")
  }

  // MARK: - Single Expression

  @Test func `single skill`() {
    let skills = buildSkills {
      skill(named: "alpha")
    }
    #expect(skills.count == 1)
    #expect(skills[0].name == "alpha")
  }

  // MARK: - Multiple Expressions (buildBlock)

  @Test func `multiple skills`() {
    let skills = buildSkills {
      skill(named: "alpha")
      skill(named: "beta")
      skill(named: "gamma")
    }
    #expect(skills.count == 3)
    #expect(skills[0].name == "alpha")
    #expect(skills[1].name == "beta")
    #expect(skills[2].name == "gamma")
  }

  @Test func `empty block`() {
    let skills = buildSkills {}
    #expect(skills.isEmpty)
  }

  // MARK: - Optional Expressions

  @Test func `optional skill with value`() {
    let optional: Skill? = skill(named: "present")
    let skills = buildSkills {
      optional
    }
    #expect(skills.count == 1)
    #expect(skills[0].name == "present")
  }

  @Test func `optional skill nil`() {
    let optional: Skill? = nil
    let skills = buildSkills {
      optional
    }
    #expect(skills.isEmpty)
  }

  @Test func `mix of optional and non-optional`() {
    let present: Skill? = skill(named: "present")
    let absent: Skill? = nil
    let skills = buildSkills {
      skill(named: "always")
      present
      absent
      skill(named: "also-always")
    }
    #expect(skills.count == 3)
    #expect(skills[0].name == "always")
    #expect(skills[1].name == "present")
    #expect(skills[2].name == "also-always")
  }

  // MARK: - Conditionals (buildEither)

  @Test func `conditional true branch`() {
    let condition = true
    let skills = buildSkills {
      if condition {
        skill(named: "true-branch")
      } else {
        skill(named: "false-branch")
      }
    }
    #expect(skills.count == 1)
    #expect(skills[0].name == "true-branch")
  }

  @Test func `conditional false branch`() {
    let condition = false
    let skills = buildSkills {
      if condition {
        skill(named: "true-branch")
      } else {
        skill(named: "false-branch")
      }
    }
    #expect(skills.count == 1)
    #expect(skills[0].name == "false-branch")
  }

  @Test func `conditional with multiple skills per branch`() {
    let condition = true
    let skills = buildSkills {
      if condition {
        skill(named: "a")
        skill(named: "b")
      } else {
        skill(named: "c")
      }
    }
    #expect(skills.count == 2)
    #expect(skills[0].name == "a")
    #expect(skills[1].name == "b")
  }

  // MARK: - For-In Loops (buildArray)

  @Test func `for-in loop`() {
    let names = ["alpha", "beta", "gamma"]
    let skills = buildSkills {
      for name in names {
        skill(named: name)
      }
    }
    #expect(skills.count == 3)
    #expect(skills[0].name == "alpha")
    #expect(skills[1].name == "beta")
    #expect(skills[2].name == "gamma")
  }

  @Test func `for-in loop over empty collection`() {
    let names: [String] = []
    let skills = buildSkills {
      for name in names {
        skill(named: name)
      }
    }
    #expect(skills.isEmpty)
  }

  // MARK: - Composition

  @Test func `loop combined with static skills`() {
    let dynamicNames = ["dynamic-1", "dynamic-2"]
    let skills = buildSkills {
      skill(named: "static")
      for name in dynamicNames {
        skill(named: name)
      }
    }
    #expect(skills.count == 3)
    #expect(skills[0].name == "static")
    #expect(skills[1].name == "dynamic-1")
    #expect(skills[2].name == "dynamic-2")
  }

  @Test func `conditional with loop`() {
    let includeExtras = true
    let extraNames = ["extra-1", "extra-2"]
    let skills = buildSkills {
      skill(named: "base")
      if includeExtras {
        for name in extraNames {
          skill(named: name)
        }
      } else {
        skill(named: "fallback")
      }
    }
    #expect(skills.count == 3)
    #expect(skills[0].name == "base")
    #expect(skills[1].name == "extra-1")
    #expect(skills[2].name == "extra-2")
  }

  // MARK: - Metadata Preservation

  @Test func `preserves name and description`() {
    let skills = buildSkills {
      Skill(name: "voice", description: "Applies a writing style", prompt: "guidelines")
      Skill(name: "calendar", description: "Manages calendar events", prompt: "rules")
    }
    #expect(skills[0].name == "voice")
    #expect(skills[0].description == "Applies a writing style")
    #expect(skills[1].name == "calendar")
    #expect(skills[1].description == "Manages calendar events")
  }
}
