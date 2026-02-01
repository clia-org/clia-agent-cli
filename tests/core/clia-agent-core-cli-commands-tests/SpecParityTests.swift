import Foundation
import Testing

@testable import CLIAAgentCoreCLICommands

@Test("DocC S-Type spec mirrors canonical spec")
func testSTypeSpecParity() throws {
  let fileURL = URL(fileURLWithPath: #file)
  var current = fileURL
  while current.lastPathComponent.lowercased() != "code" {
    current.deleteLastPathComponent()
    if current.pathComponents.count <= 1 {
      throw CocoaError(
        .fileNoSuchFile, userInfo: [NSLocalizedDescriptionKey: "Could not locate repo root (code)"])
    }
  }
  let codeRoot = current
  let repoRoot = codeRoot.deletingLastPathComponent()
  let canonical = repoRoot.appendingPathComponent(
    ".clia/specs/clia-collaboration-s-types.v1.json")
  let docc = repoRoot.appendingPathComponent(
    ".clia/docc/requests.docc/2025-10-03-clia-collaboration-s-types.docc/resources/clia-collaboration-s-types/spec.v1.json"
  )
  let canonicalData = try Data(contentsOf: canonical)
  let doccData = try Data(contentsOf: docc)
  #expect(canonicalData == doccData)

  let canonicalSpec = try JSONDecoder().decode(STypeSpec.self, from: canonicalData)
  let embeddedSpec = try STypeSpecLoader.load(root: repoRoot)
  #expect(canonicalSpec == embeddedSpec)
}
