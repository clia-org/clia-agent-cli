import ArgumentParser
import CLIAAgentCore
import Foundation

public struct MirrorsCommand: ParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(
      commandName: "mirrors",
      abstract: "Render Markdown mirrors from JSON triads under .clia/agents"
    )
  }

  @Option(
    name: .customLong("agents-dir"), help: "Agents root directory (default: .clia/agents)")
  public var agentsDir: String = ".clia/agents"

  @Option(
    name: .customLong("slug"),
    help: "Only mirror the specified agent slug(s). Repeat to pass multiple."
  )
  public var slugs: [String] = []

  @Flag(name: .customLong("dry-run"), help: "Print planned writes, do not modify files")
  public var dryRun: Bool = false

  public init() {}

  public func run() throws {
    let rootURL = URL(fileURLWithPath: agentsDir)
    let fm = FileManager.default
    guard fm.fileExists(atPath: rootURL.path) else {
      throw ValidationError("Agents directory not found: \(rootURL.path)")
    }
    let outputs = try MirrorRenderer.mirrorAgents(
      at: rootURL,
      slugs: slugs.isEmpty ? nil : Set(slugs),
      dryRun: dryRun
    )
    if dryRun {
      for u in outputs { print("would write \(u.path)") }
    } else {
      for u in outputs { print("wrote \(u.path)") }
    }
  }
}
