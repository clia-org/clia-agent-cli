import Foundation
import Testing

@testable import CLIACoreModels

@Test("Backlog items decode expected contribution targets")
func testBacklogDecodesExpectedContributions() throws {
  let payload = """
    {
      "title": "S-Type mix",
      "expectedContributions": {
        "types": ["code", "design", "doc"],
        "targets": { "synergyMin": 1.5, "stabilityMin": 1.2 }
      }
    }
    """.data(using: .utf8)!
  let item = try JSONDecoder().decode(BacklogItem.self, from: payload)
  let expected = try #require(item.expectedContributions)
  #expect(expected.types == ["code", "design", "doc"])
  let targets = try #require(expected.targets)
  #expect(targets.synergyMin == 1.5)
  #expect(targets.stabilityMin == 1.2)
}

@Test("Milestones decode expected contribution targets when present")
func testMilestoneDecodesExpectedContributions() throws {
  let payload = """
    {
      "slug": "s-type-cli",
      "title": "Implement S-Type mix-score CLI",
      "expectedContributions": {
        "types": ["code", "design", "doc"],
        "targets": { "synergyMin": 1.5 }
      }
    }
    """.data(using: .utf8)!
  let milestone = try JSONDecoder().decode(Milestone.self, from: payload)
  let expected = try #require(milestone.expectedContributions)
  #expect(expected.types == ["code", "design", "doc"])
  let targets = try #require(expected.targets)
  #expect(targets.synergyMin == 1.5)
  #expect(targets.stabilityMin == nil)
}
