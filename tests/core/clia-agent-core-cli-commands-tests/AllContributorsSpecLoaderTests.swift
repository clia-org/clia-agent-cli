import Foundation
import Testing

@testable import CLIAAgentCoreCLICommands

@Test("Embedded All Contributors spec loads")
func testEmbeddedSpecLoads() throws {
  let spec = try AllContributorsSpecLoader.loadSpec(root: nil)
  #expect(!spec.isEmpty)
  let doc = try #require(spec["doc"])
  #expect(doc.emoji == "📖")
  #expect((doc.synonyms ?? []).contains("documentation"))
}
