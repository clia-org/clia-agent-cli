import ArgumentParser
import CLIACore
import Foundation

public struct LineageLintCommand: ParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(
      commandName: "lineage-lint",
      abstract: "Lint triads for inheritance and lineage hygiene (read-only)")
  }

  public init() {}

  @Option(name: .customLong("slug"), help: "Limit to a single agent slug")
  public var slug: String?

  @Option(name: .customLong("path"), help: "Working directory (default: CWD)")
  public var path: String?

  @Flag(name: .customLong("strict"), help: "Exit non-zero on warnings")
  public var strict: Bool = false

  @Flag(name: .customLong("json"), help: "Emit JSON report")
  public var json: Bool = false

  public func run() throws {
    let root = URL(fileURLWithPath: path ?? FileManager.default.currentDirectoryPath)
    let agentsDir = root.appendingPathComponent(".clia/agents")
    let fm = FileManager.default
    var slugs: [String] = []
    if let s = slug {
      slugs = [s]
    } else if let list = try? fm.contentsOfDirectory(atPath: agentsDir.path) {
      slugs = list.filter {
        !$0.hasPrefix("_") && $0 != "templates" && $0 != "cadence" || $0 == "cadence"
      }
    }

    let errors: [String] = []
    var warnings: [String] = []
    let rootDirectives: String
    if let rootList = try? fm.contentsOfDirectory(
      atPath: agentsDir.appendingPathComponent("root").path),
      let agentFile = rootList.first(where: {
        $0.hasSuffix(".agent.triad.json") && !$0.contains(".agency.") && !$0.contains(".agenda.")
      })
    {
      rootDirectives = ".clia/agents/root/\(agentFile)"
    } else {
      rootDirectives = ".clia/agents/root/root@sample.agent.triad.json"
      warnings.append("root directives not found; using fallback \(rootDirectives)")
    }

    var report: [[String: Any]] = []
    for s in slugs {
      let dir = agentsDir.appendingPathComponent(s)
      var r: [String: Any] = ["slug": s]
      var hasAgent = false
      if let urls = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
        if let agentURL = urls.first(where: {
          $0.lastPathComponent.hasSuffix(".agent.triad.json")
            && !$0.lastPathComponent.contains(".agency.")
        }) {
          hasAgent = true
          // Check inherits (top-level)
          if let data = try? Data(contentsOf: agentURL),
            let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
          {
            let inh = (raw["inherits"] as? [String]) ?? []
            if !inh.contains(rootDirectives) {
              warnings.append("missing inherits for slug=\(s)")
              r["missingInherits"] = true
            }
          }
          // Check merged duplicates in guardrails
          let merged = Merger.mergeAgent(slug: s, under: root)
          let setCount = Set(merged.guardrails).count
          if setCount != merged.guardrails.count {
            warnings.append("duplicate guardrails after merge for slug=\(s)")
            r["duplicateGuardrails"] = true
          }
        }
      }
      if !hasAgent { continue }
      report.append(r)
    }

    if json {
      let dict: [String: Any] = [
        "root": root.path,
        "status": (errors.isEmpty && (strict ? warnings.isEmpty : true)) ? "ok" : "degraded",
        "errors": errors,
        "warnings": warnings,
        "report": report,
      ]
      let data = try JSONSerialization.data(
        withJSONObject: dict, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
      print(String(decoding: data, as: UTF8.self))
    } else {
      for w in warnings { fputs("[warn] \(w)\n", stderr) }
      for e in errors { fputs("[error] \(e)\n", stderr) }
      print("linted \(report.count) agents")
    }

    if !errors.isEmpty || (strict && !warnings.isEmpty) { throw ExitCode(1) }
  }
}
