import Foundation
import Testing

@testable import CLIAIncidentResolutionCommands

@Suite struct IncidentResolutionIOTests {
  @Test("new writes markdown report in owner folder")
  func newWritesMarkdown() throws {
    let fm = FileManager.default
    let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
    var cmd = try IncidentsResolutionGroup.New.parseAsRoot([
      "--title", "Example",
      "--owner", "patch",
      "--severity", "S1",
      "--service", "core",
      "--status", "active",
      "--path", tmp.path,
    ])
    try cmd.run()
    let files = try fm.contentsOfDirectory(
      at: tmp.appendingPathComponent(".clia/incidents/patch"), includingPropertiesForKeys: nil)
    #expect(files.contains { $0.lastPathComponent.hasSuffix(".md") })
  }

  @Test("activate writes active.json and clear removes it")
  func activateAndClear() throws {
    let fm = FileManager.default
    let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
    var a = try IncidentsResolutionGroup.Activate.parseAsRoot([
      "--id", "2025-09-30-example",
      "--title", "Example Incident",
      "--severity", "S1",
      "--owner", "patch",
      "--summary", "summary",
      "--affected", ".clia/agents/**",
      "--block", ".clia/agents/**",
      "--path", tmp.path,
    ])
    try a.run()
    let active = tmp.appendingPathComponent(".clia/incidents/active.json")
    #expect(fm.fileExists(atPath: active.path))
    var c = try IncidentsResolutionGroup.Clear.parseAsRoot(["--path", tmp.path])
    try c.run()
    #expect(!fm.fileExists(atPath: active.path))
  }
}
