import ArgumentParser
import CLIACore
import CLIACoreModels
import Foundation
import WrkstrmFoundation
import WrkstrmMain

public struct ProfileCommand: ParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(
      commandName: "profile",
      abstract: "Print a merged view of a triad (agent|agenda|agency) with optional lineage context"
    )
  }

  public init() {}

  @Option(name: .customLong("slug"), help: "Agent slug")
  public var slug: String

  @Option(name: .customLong("kind"), help: "Triad kind: agent|agenda|agency")
  public var kind: String = "agent"

  @Option(name: .customLong("path"), help: "Working directory (default: CWD)")
  public var path: String?

  @Flag(name: .customLong("root-chain"), help: "Include lineage directory chain in output")
  public var rootChain: Bool = false

  @Flag(
    name: .customLong("observance-date"),
    help: "Print only origin.firstObservedAt (observance date) and exit")
  public var observanceDate: Bool = false

  public func run() throws {
    let root = URL(fileURLWithPath: path ?? FileManager.default.currentDirectoryPath)
    let enc = JSON.Formatting.humanEncoder

    switch kind {
    case "agent":
      var view = Merger.mergeAgent(slug: slug, under: root)
      if rootChain { view.contextChain = lineageChain(slug: slug, root: root) }
      if observanceDate {
        if let ts = view.origin?.firstObservedAt { print(ts) }
        return
      }
      let data = try enc.encode(view)
      print(String(decoding: data, as: UTF8.self))
    case "agenda":
      var view = Merger.mergeAgenda(slug: slug, under: root)
      if rootChain { view.contextChain = lineageChain(slug: slug, root: root) }
      if observanceDate {
        if let ts = view.origin?.firstObservedAt { print(ts) }
        return
      }
      let data = try enc.encode(view)
      print(String(decoding: data, as: UTF8.self))
    case "agency":
      var view = Merger.mergeAgency(slug: slug, under: root)
      if rootChain { view.contextChain = lineageChain(slug: slug, root: root) }
      if observanceDate {
        if let ts = view.origin?.firstObservedAt { print(ts) }
        return
      }
      let data = try enc.encode(view)
      print(String(decoding: data, as: UTF8.self))
    default:
      throw ValidationError("--kind must be one of: agent, agenda, agency")
    }
  }

  private func lineageChain(slug: String, root: URL) -> [ContextEntry] {
    let items = LineageResolver.findAgentDirs(for: slug, under: root)
    return items.map { ContextEntry(prefix: $0.prefix, path: $0.dir.path) }
  }
}
