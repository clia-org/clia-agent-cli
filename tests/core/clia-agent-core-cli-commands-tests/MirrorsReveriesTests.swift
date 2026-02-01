import Foundation
import Testing

@testable import CLIAAgentCore

@Suite("Mirrors render Persona + Reveries when paths present")
struct MirrorsReveriesTests {
  @Test
  func rendersPersonaAndReveries() throws {
    let fm = FileManager.default
    let tmp = URL(fileURLWithPath: fm.currentDirectoryPath)
      .appendingPathComponent(".clia/tmp/mirrors-test-\(UUID().uuidString)")
    try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
    defer { try? fm.removeItem(at: tmp) }

    // Agents root with one agent
    let agentsRoot = tmp.appendingPathComponent(".clia/agents")
    let agentDir = agentsRoot.appendingPathComponent("demo")
    try fm.createDirectory(at: agentDir, withIntermediateDirectories: true)

    // Persona + reveries files (repo- or agent-relative paths)
    let persona = agentDir.appendingPathComponent("demo@sample.persona.agent.triad.md")
    let reveries = agentDir.appendingPathComponent("demo@sample.reveries.agent.triad.md")
    try "Persona line".write(to: persona, atomically: true, encoding: .utf8)
    try "- tiny hook".write(to: reveries, atomically: true, encoding: .utf8)

    // Minimal agent triad with persona paths
    let triad = agentDir.appendingPathComponent("demo@sample.agent.json")
    let json: [String: Any] = [
      "schemaVersion": "0.3.2",
      "slug": "demo",
      "title": "Demo",
      "updated": "2025-10-03T00:00:00Z",
      "role": "demo",
      "persona": [
        "profilePath": persona.path,
        "reveriesPath": reveries.path,
      ],
    ]
    let data = try JSONSerialization.data(withJSONObject: json, options: [.sortedKeys])
    try data.write(to: triad)

    // Act: render mirrors
    let outputs = try MirrorRenderer.mirrorAgents(at: agentsRoot, dryRun: false)
    #expect(!outputs.isEmpty)

    let out = agentDir.appendingPathComponent(".generated/demo.agent.triad.md")
    #expect(fm.fileExists(atPath: out.path))
    let md = try String(contentsOf: out, encoding: .utf8)
    #expect(md.contains("## Persona"))
    #expect(md.contains("Persona line"))
    #expect(md.contains("## Reveries"))
    #expect(md.contains("tiny hook"))
  }
}
