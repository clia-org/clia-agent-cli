import CLIACoreModels
import Foundation
import Testing

@testable import CLIAAgentCoreCLICommands

@Test("Workspace triad schemas load")
func testEmbeddedTriadSchemasLoad() throws {
  let root = try findWorkspaceRoot(startingAt: URL(fileURLWithPath: #filePath))
  for schema in TriadSchema.allCases {
    let data = try TriadSchemaLoader.load(schema: schema, root: root)
    #expect(!data.isEmpty)
    // Cheap validation: ensure JSON object decodes
    let obj = try JSONSerialization.jsonObject(with: data)
    #expect(obj is [String: Any])
  }
}

@Test("Agent/agenda/agency schemas advertise 0.4.0")
func testSchemaVersionConst() throws {
  let root = try findWorkspaceRoot(startingAt: URL(fileURLWithPath: #filePath))
  for kind in [TriadSchemaKind.agent, .agency, .agenda] {
    let info = try TriadSchemaInspector.info(for: kind, root: root)
    #expect(info.allowedSchemaVersions == Set([TriadSchemaVersion.current]))
  }
}

private func findWorkspaceRoot(startingAt file: URL) throws -> URL {
  var candidate = file.deletingLastPathComponent()

  for _ in 0..<30 {
    let triadsDir = candidate.appendingPathComponent(".clia/schemas/triads")
    if FileManager.default.fileExists(atPath: triadsDir.path) {
      return candidate
    }
    let parent = candidate.deletingLastPathComponent()
    if parent.path == candidate.path { break }
    candidate = parent
  }

  throw CocoaError(
    .fileNoSuchFile,
    userInfo: [
      NSLocalizedDescriptionKey:
        "Could not locate workspace root containing .clia/schemas/triads when walking up from \(file.path)."
    ]
  )
}
