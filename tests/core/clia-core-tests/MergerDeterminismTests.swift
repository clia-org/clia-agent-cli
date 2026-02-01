import Foundation
import Testing

@testable import CLIACore

@Test("Deterministic union preserves inherited then local order")
func testDeterministicUnionOrder() throws {
  let fm = FileManager.default
  let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
  try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
  defer { try? fm.removeItem(at: tmp) }
  let agentsRoot = tmp.appendingPathComponent(".clia/agents")
  try fm.createDirectory(at: agentsRoot, withIntermediateDirectories: true)

  // Root directives with guardrails A, B
  let rootDir = agentsRoot.appendingPathComponent("_root")
  try fm.createDirectory(at: rootDir, withIntermediateDirectories: true)
  let rootDoc: [String: Any] = [
    "schemaVersion": "0.4.0",
    "slug": "agent-profile",
    "title": "Agent Directives",
    "updated": ISO8601DateFormatter().string(from: Date()),
    "role": "directives",
    "mentors": [], "tags": [], "links": [],
    "responsibilities": [], "guardrails": ["A", "B"], "checklists": [], "sections": [],
    "notes": [],
  ]
  try JSONSerialization.data(withJSONObject: rootDoc, options: .prettyPrinted)
    .write(to: rootDir.appendingPathComponent("root@sample.agent.json"))

  // Child with guardrails B, C and inheritance
  let slug = "smoke-order"
  let childDir = agentsRoot.appendingPathComponent(slug)
  try fm.createDirectory(at: childDir, withIntermediateDirectories: true)
  let childDoc: [String: Any] = [
    "schemaVersion": "0.4.0",
    "slug": slug,
    "title": "Smoke Order",
    "updated": ISO8601DateFormatter().string(from: Date()),
    "role": slug,
    "mentors": [], "tags": [], "links": [],
    "responsibilities": [], "guardrails": ["B", "C"], "checklists": [], "sections": [],
    "notes": [],
    "inherits": [".clia/agents/root/root@sample.agent.json"],
  ]
  try JSONSerialization.data(withJSONObject: childDoc, options: .prettyPrinted)
    .write(to: childDir.appendingPathComponent("\(slug)@sample.agent.json"))

  let merged = Merger.mergeAgent(slug: slug, under: tmp)
  // Expect A, B, C with single B
  #expect(merged.guardrails == ["A", "B", "C"])
}

@Test("Inheritance cycles do not loop and keep single instance")
func testCycleSafeInheritance() throws {
  let fm = FileManager.default
  let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
  try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
  defer { try? fm.removeItem(at: tmp) }
  let agentsRoot = tmp.appendingPathComponent(".clia/agents")
  try fm.createDirectory(at: agentsRoot, withIntermediateDirectories: true)

  // Two files that inherit each other
  let slug = "cycle"
  let dir = agentsRoot.appendingPathComponent(slug)
  try fm.createDirectory(at: dir, withIntermediateDirectories: true)
  let a = dir.appendingPathComponent("a.agent.json")
  let b = dir.appendingPathComponent("b.agent.json")
  let docA: [String: Any] = [
    "schemaVersion": "0.4.0", "slug": slug, "title": "CycleA",
    "updated": ISO8601DateFormatter().string(from: Date()), "role": slug,
    "mentors": [], "tags": [], "links": [], "responsibilities": [], "guardrails": ["X"],
    "checklists": [], "sections": [],
    "notes": [],
    "inherits": [b.path],
  ]
  let docB: [String: Any] = [
    "schemaVersion": "0.4.0", "slug": slug, "title": "CycleB",
    "updated": ISO8601DateFormatter().string(from: Date()), "role": slug,
    "mentors": [], "tags": [], "links": [], "responsibilities": [], "guardrails": ["Y"],
    "checklists": [], "sections": [],
    "notes": [],
    "inherits": [a.path],
  ]
  try JSONSerialization.data(withJSONObject: docA, options: .prettyPrinted).write(to: a)
  try JSONSerialization.data(withJSONObject: docB, options: .prettyPrinted).write(to: b)

  // The loader looks for a triad file at lineage dirs; place one with standard name referencing A
  try fm.copyItem(at: a, to: dir.appendingPathComponent("\(slug)@sample.agent.json"))
  let merged = Merger.mergeAgent(slug: slug, under: tmp)
  // Both X and Y appear once each
  let g = merged.guardrails
  #expect(g.contains("X") && g.contains("Y"))
  #expect(Set(g).count == g.count)  // no duplicates
}

@Test("Missing inherited paths are ignored (no crash)")
func testMissingInheritedIgnored() throws {
  let fm = FileManager.default
  let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
  try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
  defer { try? fm.removeItem(at: tmp) }
  let agentsRoot = tmp.appendingPathComponent(".clia/agents")
  try fm.createDirectory(at: agentsRoot, withIntermediateDirectories: true)
  let slug = "missing"
  let dir = agentsRoot.appendingPathComponent(slug)
  try fm.createDirectory(at: dir, withIntermediateDirectories: true)
  let doc: [String: Any] = [
    "schemaVersion": "0.4.0", "slug": slug, "title": "Missing",
    "updated": ISO8601DateFormatter().string(from: Date()), "role": slug,
    "mentors": [], "tags": [], "links": [], "responsibilities": [], "guardrails": ["local"],
    "checklists": [], "sections": [],
    "notes": [],
    "inherits": ["/no/such/file.json"],
  ]
  try JSONSerialization.data(withJSONObject: doc, options: .prettyPrinted)
    .write(to: dir.appendingPathComponent("\(slug)@sample.agent.json"))
  let merged = Merger.mergeAgent(slug: slug, under: tmp)
  #expect(merged.guardrails == ["local"])  // still decodes
}
