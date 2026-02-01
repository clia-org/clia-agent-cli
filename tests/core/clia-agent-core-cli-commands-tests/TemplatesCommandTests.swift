import Foundation
import Testing

@testable import CLIAAgentCoreCLICommands

@Test("Bundled templates are discoverable")
func testTemplatesListing() throws {
  let templates = try TemplatesCommand.templates()
  let names = templates.map(\.name)
  #expect(names.contains("ios-engineer"))
  #expect(names.contains("product-owner"))
  #expect(names.contains("project-manager"))
  #expect(names.contains("swift-architect"))

  for template in templates {
    #expect(!template.files.isEmpty)
    #expect(template.files.allSatisfy { $0.hasSuffix(".json") })
  }
}
