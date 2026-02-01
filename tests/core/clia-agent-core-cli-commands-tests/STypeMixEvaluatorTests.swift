import Foundation
import Testing

@testable import CLIAAgentCoreCLICommands

@Test("Unweighted mix metrics produce expected shares")
func testUnweightedMixMetrics() throws {
  let spec = try loadSpec()
  let metrics = STypeMixEvaluator.evaluate(mix: ["code": 1, "design": 1, "doc": 1], spec: spec)
  #expect(metrics.pairCount == 3)
  #expect(metrics.totalWeight == 3)
  #expect(metrics.synergyMass > 1.9 && metrics.synergyMass < 2.1)
  #expect(metrics.stabilityMass > 0.9 && metrics.stabilityMass < 1.1)
  #expect(metrics.strainMass == 0)
  #expect(metrics.synergyShare > 0.6 && metrics.synergyShare < 0.8)
  #expect(metrics.stabilityShare > 0.2 && metrics.stabilityShare < 0.4)
}

@Test("Weighted mix honours contribution shares")
func testWeightedMixMetrics() throws {
  let spec = try loadSpec()
  let metrics = STypeMixEvaluator.evaluate(mix: ["code": 4, "design": 3, "doc": 2], spec: spec)
  #expect(metrics.totalWeight > 0)
  #expect(metrics.synergyShare > 0.6 && metrics.synergyShare < 0.8)
  #expect(metrics.stabilityShare > 0.2 && metrics.stabilityShare < 0.4)
  #expect(metrics.strainShare == 0)
}

@Test("Recommendations favour stabilizers")
func testRecommendations() throws {
  let spec = try loadSpec()
  let recs = STypeMixEvaluator.recommendations(mix: ["code": 1, "design": 1], spec: spec, top: 5)
  #expect(!recs.isEmpty)
  // Expect doc or review to appear near the top because they stabilize code/design.
  let topNames = recs.prefix(3).map { $0.type }
  #expect(topNames.contains { $0 == "doc" || $0 == "review" })
}

private func loadSpec() throws -> STypeSpec {
  let bundle = Bundle.module
  guard let url = bundle.url(forResource: "clia-collaboration-s-types.v1", withExtension: "json")
  else { throw CocoaError(.fileNoSuchFile) }
  let data = try Data(contentsOf: url)
  return try JSONDecoder().decode(STypeSpec.self, from: data)
}
