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
import FoundationModels

extension Transcript.Entry {
  var prompt: Transcript.Prompt? {
    if case .prompt(let prompt) = self { return prompt }
    return nil
  }

  var toolCalls: Transcript.ToolCalls? {
    if case .toolCalls(let calls) = self { return calls }
    return nil
  }

  var toolOutput: Transcript.ToolOutput? {
    if case .toolOutput(let output) = self { return output }
    return nil
  }

  var response: Transcript.Response? {
    if case .response(let response) = self { return response }
    return nil
  }

  var reasoning: Transcript.Reasoning? {
    if case .reasoning(let reasoning) = self { return reasoning }
    return nil
  }
}
