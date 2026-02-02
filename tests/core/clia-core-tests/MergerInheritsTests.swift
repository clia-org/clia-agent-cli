import Foundation
import Testing

@testable import CLIACore

@Test("Merger loads inherits from root directives and unions guardrails")
func testMergerInheritsGuardrails() throws {
  let fm = FileManager.default
  let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
  try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
  defer { try? fm.removeItem(at: tmp) }

  let agentsRoot = tmp.appendingPathComponent(".clia/agents")
  try fm.createDirectory(at: agentsRoot, withIntermediateDirectories: true)

  // Write root directives
  let rootDir = agentsRoot.appendingPathComponent("_root")
  try fm.createDirectory(at: rootDir, withIntermediateDirectories: true)
  let rootDoc =
    [
      "schemaVersion": "0.4.0",
      "slug": "agent-profile",
      "title": "Agent Directives",
      "updated": ISO8601DateFormatter().string(from: Date()),
      "role": "directives",
      "mentors": [],
      "tags": [],
      "links": [],
      "purpose": "root",
      "responsibilities": [],
      "guardrails": ["root-policy"],
      "checklists": [],
      "sections": [],
      "notes": [],
      "extensions": [:] as [String: Any],
    ] as [String: Any]
  let rootData = try JSONSerialization.data(
    withJSONObject: rootDoc, options: [.prettyPrinted, .sortedKeys])
  try rootData.write(to: rootDir.appendingPathComponent("root@sample.agent.triad.json"))

  // Write child agent that inherits root
  let slug = "smokey"
  let childDir = agentsRoot.appendingPathComponent(slug)
  try fm.createDirectory(at: childDir, withIntermediateDirectories: true)
  let childDoc =
    [
      "schemaVersion": "0.4.0",
      "slug": slug,
      "title": "Smokey",
      "updated": ISO8601DateFormatter().string(from: Date()),
      "role": slug,
      "mentors": [],
      "tags": [],
      "links": [],
      "purpose": "child",
      "responsibilities": [],
      "guardrails": ["child-policy"],
      "checklists": [],
      "sections": [],
      "notes": [],
      "inherits": [".clia/agents/root/root@sample.agent.triad.json"],
    ] as [String: Any]
  let childData = try JSONSerialization.data(
    withJSONObject: childDoc, options: [.prettyPrinted, .sortedKeys])
  try childData.write(to: childDir.appendingPathComponent("\(slug)@sample.agent.triad.json"))

  let merged = Merger.mergeAgent(slug: slug, under: tmp)
  #expect(merged.slug == slug)
  #expect(merged.guardrails.contains("root-policy"))
  #expect(merged.guardrails.contains("child-policy"))
}
