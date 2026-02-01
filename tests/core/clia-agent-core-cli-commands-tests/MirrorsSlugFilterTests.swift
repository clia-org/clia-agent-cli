import Foundation
import Testing

@testable import CLIAAgentCore

@Suite("Mirrors slug filter renders only requested agent")
struct MirrorsSlugFilterTests {
  @Test
  func mirrorsOnlyOneSlug() throws {
    let fm = FileManager.default
    let tmp = URL(fileURLWithPath: fm.currentDirectoryPath)
      .appendingPathComponent(".clia/tmp/mirrors-slug-\(UUID().uuidString)")
    try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
    defer { try? fm.removeItem(at: tmp) }

    let agentsRoot = tmp.appendingPathComponent(".clia/agents")
    let a1 = agentsRoot.appendingPathComponent("one")
    let a2 = agentsRoot.appendingPathComponent("two")
    try fm.createDirectory(at: a1, withIntermediateDirectories: true)
    try fm.createDirectory(at: a2, withIntermediateDirectories: true)

    func writeTriads(_ dir: URL, slug: String) throws {
      let base: [String: Any] = [
        "schemaVersion": "0.3.2",
        "slug": slug,
        "title": slug.capitalized,
        "updated": "2025-10-03T00:00:00Z",
        "role": slug,
      ]
      let enc = { (obj: [String: Any]) throws -> Data in
        try JSONSerialization.data(withJSONObject: obj, options: [.sortedKeys])
      }
      try enc(base).write(to: dir.appendingPathComponent("\(slug)@sample.agent.json"))
      try enc(base).write(to: dir.appendingPathComponent("\(slug)@sample.agenda.json"))
      try enc(base).write(to: dir.appendingPathComponent("\(slug)@sample.agency.json"))
    }
    try writeTriads(a1, slug: "one")
    try writeTriads(a2, slug: "two")

    // Act: mirror only slug "one"
    let outputs = try MirrorRenderer.mirrorAgents(at: agentsRoot, slugs: ["one"], dryRun: false)
    #expect(!outputs.isEmpty)
    // Assert that all outputs reside under agent "one" directory
    for url in outputs {
      #expect(url.path.contains("/one/.generated/"))
      #expect(!url.path.contains("/two/.generated/"))
    }
    // Ensure at least one mirror file for the selected slug exists
    let expected = a1.appendingPathComponent(".generated/one.agent.triad.md")
    #expect(fm.fileExists(atPath: expected.path))
  }
}
