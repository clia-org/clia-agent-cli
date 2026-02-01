import Foundation
import Testing

@testable import CLIAIncidentCoreCommands

@Suite struct IncidentCoreStatusTests {
  @Test("reads active banner JSON when present")
  func readsActiveBanner() throws {
    let fm = FileManager.default
    let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
    let incDir = tmp.appendingPathComponent(".clia/incidents")
    try fm.createDirectory(at: incDir, withIntermediateDirectories: true)
    let active = incDir.appendingPathComponent("active.json")
    let json = """
      {"id":"2025-09-30-test","title":"Test","severity":"S1","status":"active","owner":"patch","started":"2025-09-30T00:00:00Z"}
      """.data(using: .utf8)!
    try json.write(to: active)
    let banner = IncidentCore.readActive(at: tmp)
    #expect(banner?.id == "2025-09-30-test")
    #expect(banner?.title == "Test")
    #expect(banner?.severity.string == "S1")
    #expect(banner?.status == "active")
  }
}
