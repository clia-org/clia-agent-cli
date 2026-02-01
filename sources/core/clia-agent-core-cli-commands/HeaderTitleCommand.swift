import ArgumentParser
import CLIAAgentCore
import CLIACoreModels
import Foundation

/// Manage the conversation header title override (ephemeral, git-ignored).
/// Storage: `.clia/tmp/header-title.txt` under the repo root.
public enum HeaderTitleCommand {
  struct Common {
    static func repoRoot(from path: String?) throws -> URL {
      let cwd = URL(fileURLWithPath: path ?? FileManager.default.currentDirectoryPath)
      if let root = WriteTargetResolver.resolveRepoRoot(startingAt: cwd) { return root }
      throw ValidationError("Could not resolve repository root (no .git found above \(cwd.path)).")
    }
    static func overrideURL(under root: URL) -> URL {
      root.appendingPathComponent(".clia/tmp/header-title.txt")
    }
  }

  public struct Set: ParsableCommand {
    public static var configuration: CommandConfiguration {
      .init(
        commandName: "set",
        abstract: "Set a dynamic header title (overrides workspace defaults)")
    }
    public init() {}

    @Option(name: .customLong("path"), help: "Working directory (default: CWD)")
    public var path: String?

    @Option(name: .customLong("title"), help: "Header title to set")
    public var title: String

    @Flag(name: .customLong("yes"), help: "Proceed without interactive confirmation")
    public var yes: Bool = false

    public func run() throws {
      let root = try Common.repoRoot(from: path)
      let url = Common.overrideURL(under: root)
      let text = title.trimmingCharacters(in: .whitespacesAndNewlines)
      if text.isEmpty { throw ValidationError("--title must not be empty") }

      if !yes {
        // Print intent and require explicit confirmation via --yes
        fputs("About to set header title to: '\(text)'\n", stderr)
        fputs("Add --yes to proceed. No writes performed.\n", stderr)
        throw ExitCode.failure
      }

      // Ensure parent directory exists
      let fm = FileManager.default
      try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
      try (text + "\n").data(using: .utf8)!.write(to: url)
      // Echo the first two header lines via ShowEnvironment to provide feedback would be heavy; print the value and path instead.
      print("header-title set: \(text)")
      print("path: \(url.path)")
    }
  }

  public struct Clear: ParsableCommand {
    public static var configuration: CommandConfiguration {
      .init(
        commandName: "clear",
        abstract: "Clear the dynamic header title override")
    }
    public init() {}

    @Option(name: .customLong("path"), help: "Working directory (default: CWD)")
    public var path: String?

    @Flag(name: .customLong("yes"), help: "Proceed without interactive confirmation")
    public var yes: Bool = false

    public func run() throws {
      let root = try Common.repoRoot(from: path)
      let url = Common.overrideURL(under: root)
      let fm = FileManager.default
      if !fm.fileExists(atPath: url.path) {
        print("header-title already clear")
        return
      }
      if !yes {
        fputs("About to clear header title override at: \(url.path)\n", stderr)
        fputs("Add --yes to proceed. No writes performed.\n", stderr)
        throw ExitCode.failure
      }
      try fm.removeItem(at: url)
      print("header-title cleared")
    }
  }

  public struct Show: ParsableCommand {
    public static var configuration: CommandConfiguration {
      .init(commandName: "show", abstract: "Show the current header title and source")
    }
    public init() {}

    @Option(name: .customLong("path"), help: "Working directory (default: CWD)")
    public var path: String?

    public func run() throws {
      let root = try Common.repoRoot(from: path)
      let fm = FileManager.default
      let overridePath = Common.overrideURL(under: root)
      if let data = fm.contents(atPath: overridePath.path),
        let s = String(data: data, encoding: .utf8)?.trimmingCharacters(
          in: .whitespacesAndNewlines),
        !s.isEmpty
      {
        print("title: \(s)")
        print("source: override (.clia/tmp/header-title.txt)")
        return
      }
      // Fallback to workspace defaults for visibility
      let ws = try WorkspaceConfig.load(under: root)
      let def = ws.header?.defaults?.title ?? "Untitled"
      print("title: \(def)")
      print("source: workspace (.clia/workspace.clia.json)")
    }
  }
}

public struct HeaderTitle: ParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(
      commandName: "header-title",
      abstract: "Manage the conversation header title (ephemeral override)",
      subcommands: [
        HeaderTitleCommand.Set.self, HeaderTitleCommand.Clear.self, HeaderTitleCommand.Show.self,
      ]
    )
  }
  public init() {}
}
