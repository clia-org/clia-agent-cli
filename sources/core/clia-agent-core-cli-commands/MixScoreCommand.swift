import ArgumentParser
import Foundation

public struct MixScoreCommand: ParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(
      commandName: "mix-score",
      abstract: "Score a contribution mix using the embedded S-Type matrix"
    )
  }

  @Option(
    name: .customLong("types"), help: "Comma-separated S-Type contributions (e.g., code,design,doc)"
  )
  public var types: String

  @Option(
    name: .customLong("weights"), parsing: .upToNextOption,
    help: "Optional weights (type=value), e.g., --weights code=4 design=3"
  )
  public var weightPairs: [String] = []

  public enum Format: String, ExpressibleByArgument, CaseIterable { case text, json, md }

  @Option(
    name: .customLong("format"),
    help: "Output format: \(Format.allCases.map { $0.rawValue }.joined(separator: ", "))")
  public var format: Format = .text

  @Option(name: .customLong("top"), help: "Number of recommendations to show (default: 3)")
  public var top: Int = 3

  public init() {}

  public func run() throws {
    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let repoRoot = locateRepoRoot(start: root) ?? root

    let spec = try STypeSpecLoader.load(root: repoRoot)
    let orderedTypes = parseTypes()
    guard !orderedTypes.isEmpty else {
      throw ValidationError("No types provided. Pass --types code,design,doc")
    }

    let weights = try parseWeights(for: orderedTypes)
    let mixDict = Dictionary(
      uniqueKeysWithValues: zip(orderedTypes, orderedTypes.map { weights[$0] ?? 1 }))

    let invalid = orderedTypes.filter { spec.types[$0] == nil }
    guard invalid.isEmpty else {
      throw ValidationError("Unknown S-Type(s): \(invalid.joined(separator: ", "))")
    }

    let metrics = STypeMixEvaluator.evaluate(mix: mixDict, spec: spec)
    let recommendations = STypeMixEvaluator.recommendations(
      mix: mixDict, spec: spec, top: max(top, 0))

    switch format {
    case .text:
      print(renderText(metrics: metrics, recommendations: recommendations, weights: mixDict))
    case .md:
      print(renderMarkdown(metrics: metrics, recommendations: recommendations, weights: mixDict))
    case .json:
      let payload = jsonPayload(
        metrics: metrics, recommendations: recommendations, weights: mixDict)
      let data = try JSONSerialization.data(
        withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
      if let string = String(data: data, encoding: .utf8) { print(string) }
    }
  }

  private func locateRepoRoot(start: URL) -> URL? {
    var current = start
    let fm = FileManager.default
    while true {
      if fm.fileExists(atPath: current.appendingPathComponent("AGENCY.md").path) {
        return current
      }
      let next = current.deletingLastPathComponent()
      if next.path == current.path { return nil }
      current = next
    }
  }

  private func parseTypes() -> [String] {
    types
      .split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .reduce(into: [String]()) { acc, value in
        if !acc.contains(value) { acc.append(value) }
      }
  }

  private func parseWeights(for types: [String]) throws -> [String: Double] {
    var result: [String: Double] = [:]
    for pair in weightPairs {
      let trimmed = pair.trimmingCharacters(in: .whitespacesAndNewlines)
      guard let eq = trimmed.firstIndex(of: "=") else {
        throw ValidationError("Invalid weight entry: \(pair). Use type=value")
      }
      let key = String(trimmed[..<eq]).trimmingCharacters(in: .whitespacesAndNewlines)
      let valueString = String(trimmed[trimmed.index(after: eq)...]).trimmingCharacters(
        in: .whitespacesAndNewlines)
      guard !key.isEmpty, let value = Double(valueString), value > 0 else {
        throw ValidationError("Invalid weight entry: \(pair). Expected positive numeric value")
      }
      result[key] = value
    }

    for type in types where result[type] == nil { result[type] = 1 }
    return result
  }

  private func renderText(
    metrics: STypeMixMetrics,
    recommendations: [STypeRecommendation],
    weights: [String: Double]
  ) -> String {
    var lines: [String] = []
    lines.append("Mix: \(metrics.types.joined(separator: ", "))")
    let weightLine = metrics.types.map { "\($0)=\(formatNumber(weights[$0] ?? 1))" }.joined(
      separator: ", ")
    lines.append("Weights: \(weightLine)")
    lines.append("")
    lines.append("Pairs: \(metrics.pairCount) (total weight: \(formatNumber(metrics.totalWeight)))")
    lines.append("Mass:")
    lines.append(
      "  synergy : \(formatNumber(metrics.synergyMass)) (\(formatPercent(metrics.synergyShare)))")
    lines.append(
      "  stability: \(formatNumber(metrics.stabilityMass)) (\(formatPercent(metrics.stabilityShare)))"
    )
    lines.append(
      "  strain  : \(formatNumber(metrics.strainMass)) (\(formatPercent(metrics.strainShare)))")
    if metrics.neutralMass > 0 {
      lines.append(
        "  neutral : \(formatNumber(metrics.neutralMass)) (\(formatPercent(metrics.totalWeight > 0 ? metrics.neutralMass / metrics.totalWeight : 0)))"
      )
    }
    lines.append("Average multiplier: \(formatNumber(metrics.averageMultiplier))")
    if !recommendations.isEmpty {
      lines.append("")
      lines.append("Recommendations (top \(recommendations.count)):")
      for (index, rec) in recommendations.enumerated() {
        lines.append(
          "\(index + 1). \(rec.type)  Δsynergy=\(formatPercent(rec.deltaSynergyShare))  Δstability=\(formatPercent(rec.deltaStabilityShare))  Δstrain=\(formatPercent(rec.deltaStrainShare))  score=\(formatPercent(rec.composite))"
        )
      }
    }
    return lines.joined(separator: "\n")
  }

  private func renderMarkdown(
    metrics: STypeMixMetrics,
    recommendations: [STypeRecommendation],
    weights: [String: Double]
  ) -> String {
    var sections: [String] = []
    sections.append("| Mix | Weights |")
    let weightLine = metrics.types.map { "\($0)=\(formatNumber(weights[$0] ?? 1))" }.joined(
      separator: ", ")
    sections.append("| --- | --- |")
    sections.append("| \(metrics.types.joined(separator: ", ")) | \(weightLine) |")
    sections.append("")
    sections.append("| Relation | Mass | Share |")
    sections.append("| --- | ---: | ---: |")
    sections.append(
      "| Synergy | \(formatNumber(metrics.synergyMass)) | \(formatPercent(metrics.synergyShare)) |")
    sections.append(
      "| Stability | \(formatNumber(metrics.stabilityMass)) | \(formatPercent(metrics.stabilityShare)) |"
    )
    sections.append(
      "| Strain | \(formatNumber(metrics.strainMass)) | \(formatPercent(metrics.strainShare)) |")
    if metrics.neutralMass > 0 {
      sections.append(
        "| Neutral | \(formatNumber(metrics.neutralMass)) | \(formatPercent(metrics.totalWeight > 0 ? metrics.neutralMass / metrics.totalWeight : 0)) |"
      )
    }
    sections.append("| Average multiplier | | \(formatNumber(metrics.averageMultiplier)) |")
    if !recommendations.isEmpty {
      sections.append("")
      sections.append("| Rank | Type | ΔSynergy | ΔStability | ΔStrain | Composite |")
      sections.append("| ---: | --- | ---: | ---: | ---: | ---: |")
      for (index, rec) in recommendations.enumerated() {
        sections.append(
          "| \(index + 1) | \(rec.type) | \(formatPercent(rec.deltaSynergyShare)) | \(formatPercent(rec.deltaStabilityShare)) | \(formatPercent(rec.deltaStrainShare)) | \(formatPercent(rec.composite)) |"
        )
      }
    }
    return sections.joined(separator: "\n")
  }

  private func jsonPayload(
    metrics: STypeMixMetrics,
    recommendations: [STypeRecommendation],
    weights: [String: Double]
  ) -> [String: Any] {
    let metricsDict: [String: Any] = [
      "pairCount": metrics.pairCount,
      "totalWeight": metrics.totalWeight,
      "mass": [
        "synergy": metrics.synergyMass,
        "stability": metrics.stabilityMass,
        "strain": metrics.strainMass,
        "neutral": metrics.neutralMass,
      ],
      "share": [
        "synergy": metrics.synergyShare,
        "stability": metrics.stabilityShare,
        "strain": metrics.strainShare,
      ],
      "averageMultiplier": metrics.averageMultiplier,
    ]

    let recs = recommendations.map { rec -> [String: Any] in
      [
        "type": rec.type,
        "deltaSynergy": rec.deltaSynergyShare,
        "deltaStability": rec.deltaStabilityShare,
        "deltaStrain": rec.deltaStrainShare,
        "composite": rec.composite,
      ]
    }

    let weightsDict = Dictionary(uniqueKeysWithValues: metrics.types.map { ($0, weights[$0] ?? 1) })
    return [
      "mix": metrics.types,
      "weights": weightsDict,
      "metrics": metricsDict,
      "recommendations": recs,
    ]
  }

  private func formatNumber(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 3
    formatter.minimumFractionDigits = 0
    return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.3f", value)
  }

  private func formatPercent(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .percent
    formatter.maximumFractionDigits = 1
    formatter.minimumFractionDigits = 0
    return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.1f%%", value * 100)
  }
}
