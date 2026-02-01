import ArgumentParser
import CLIAAgentCore
import SwiftDirectoryTools
import Foundation
import WrkstrmFoundation

/// Generate a single flat text file for a request or bundle directory.
/// Wraps SwiftDirectoryTools so operators can produce a shareable file for AI/review.
public struct DirectoryFlattenCommand: ParsableCommand {
  public static var configuration: CommandConfiguration {
    .init(
      commandName: "directory-flatten",
      abstract: "Generate a flat text file from a directory (md/json/swift)."
    )
  }

  public init() {}

  @Option(name: .customLong("path"), help: "Directory to flatten (default: CWD)")
  public var path: String?

  @Option(
    name: .customLong("output"),
    help: "Output file path (default: .clia/requests/<dir-slug>.flat.txt)")
  public var outputPath: String?

  @Option(
    name: .customLong("allow-suffix"), parsing: .upToNextOption,
    help: "Only include files ending with these suffixes (default: .md .json .swift)"
  )
  public var allowedSuffixes: [String] = [".md", ".json", ".swift"]

  @Option(
    name: .customLong("ignore-suffix"), parsing: .upToNextOption,
    help: "Ignore files ending with these suffixes (appended to defaults)"
  )
  public var ignoredSuffixes: [String] = []

  public func run() throws {
    let fm = FileManager.default
    let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let start = URL(fileURLWithPath: path ?? cwd.path)
    let repoRoot = WriteTargetResolver.resolveRepoRoot(startingAt: start) ?? cwd
    // Derive default output when not provided
    let outputURL: URL = {
      if let p = outputPath, !p.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        return URL(fileURLWithPath: p)
      }
      let slugSrc = start.lastPathComponent
      let slug = DirectoryFlattenCommand.slugify(slugSrc)
      let outDir = repoRoot.appendingPathComponent(".clia/requests", isDirectory: true)
      try? fm.createDirectory(at: outDir, withIntermediateDirectories: true)
      return outDir.appendingPathComponent("\(slug).flat.txt")
    }()

    let defaultIgnored: [String] = [".h", ".m", "README", "Package.swift", "Tests"]
    let combinedIgnored = defaultIgnored + ignoredSuffixes

    let sources = try SwiftDirectoryTools.relevantSourceFiles(
      in: start,
      ignoringSuffixes: combinedIgnored,
      allowedSuffixes: allowedSuffixes
    )
    try SwiftDirectoryTools.generateSingleFile(
      from: sources,
      to: outputURL,
      style: .string
    )
    print(outputURL.path)
  }
}

extension DirectoryFlattenCommand {
  static func slugify(_ s: String) -> String {
    let lowered = s.lowercased()
    // Replace any non-alphanumeric with hyphen; collapse repeats
    let allowed = CharacterSet.alphanumerics
    var out: String = ""
    var lastWasHyphen = false
    for scalar in lowered.unicodeScalars {
      if allowed.contains(scalar) {
        out.unicodeScalars.append(scalar)
        lastWasHyphen = false
      } else {
        if !lastWasHyphen {
          out.append("-")
          lastWasHyphen = true
        }
      }
    }
    return out.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
  }
}
