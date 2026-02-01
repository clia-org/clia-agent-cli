import Foundation
import Testing

@testable import CLIACoreModels

@Suite struct IncidentDecodingTests {
  @Test("decodes minimal active.json banner")
  func decodesMinimal() throws {
    let json = """
      {"id":"t1","title":"Title","severity":"S2","status":"active","owner":"patch","started":"2025-09-30T00:00:00Z"}
      """.data(using: .utf8)!
    let inc = try JSONDecoder().decode(Incident.self, from: json)
    #expect(inc.id == "t1")
    #expect(inc.title == "Title")
    #expect(inc.severity.string == "S2")
    #expect(inc.status == "active")
    #expect(inc.owner == "patch")
  }

  @Test("decodes unknown severity into .other and preserves raw string")
  func decodesUnknownSeverity() throws {
    let json = """
      {"id":"t2","title":"Title","severity":"low","status":"active","owner":"patch","started":"2025-09-30T00:00:00Z"}
      """.data(using: .utf8)!
    let inc = try JSONDecoder().decode(Incident.self, from: json)
    #expect(inc.severity.string == "low")
  }
}
