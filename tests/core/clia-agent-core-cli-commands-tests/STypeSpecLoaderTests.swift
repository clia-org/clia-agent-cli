import Foundation
import Testing

@testable import CLIAAgentCoreCLICommands

@Test("Embedded S-Type spec loads")
func testEmbeddedSTypeSpecLoads() throws {
  let spec = try STypeSpecLoader.load(root: nil)
  #expect(!spec.types.isEmpty)
  #expect(spec.types.keys.contains("code"))
}
