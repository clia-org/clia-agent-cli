import CLIACore
import Foundation
import WrkstrmFoundation
import WrkstrmMain

/// Canonical manifest for project manager issue intents.
struct IssuesManifest: Codable, Equatable, Sendable {
  var issues: [ProjectIssue]

  init(issues: [ProjectIssue] = []) {
    self.issues = issues
  }
}

/// Issue intent entry stored in project manager manifests.
struct ProjectIssue: Codable, Equatable, Sendable {
  var identifier: String
  var title: String
  var body: String
  var labels: [String]
  var milestone: String?
  var assignees: [String]
  var projects: [String]
  var triadReference: String?
  var githubIssue: ProjectIssueLink?

  init(
    identifier: String,
    title: String,
    body: String,
    labels: [String] = [],
    milestone: String? = nil,
    assignees: [String] = [],
    projects: [String] = [],
    triadReference: String? = nil,
    githubIssue: ProjectIssueLink? = nil
  ) {
    self.identifier = identifier
    self.title = title
    self.body = body
    self.labels = labels
    self.milestone = milestone
    self.assignees = assignees
    self.projects = projects
    self.triadReference = triadReference
    self.githubIssue = githubIssue
  }
}

/// Linked GitHub issue metadata captured after reconciliation.
struct ProjectIssueLink: Codable, Equatable, Sendable {
  var number: Int
  var url: URL
  var state: String?

  init(number: Int, url: URL, state: String? = nil) {
    self.number = number
    self.url = url
    self.state = state
  }
}

/// Persistence helpers for reading and writing issue manifests.
struct IssuesManifestStore {
  var fileURL: URL

  private let encoder: JSONEncoder = JSON.Formatting.humanEncoder

  private let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    return decoder
  }()

  func load() throws -> IssuesManifest {
    let fm = FileManager.default
    guard fm.fileExists(atPath: fileURL.path) else {
      return IssuesManifest()
    }
    let data = try Data(contentsOf: fileURL)
    return try decoder.decode(IssuesManifest.self, from: data)
  }

  func save(_ manifest: IssuesManifest) throws {
    try JSON.FileWriter.write(manifest, to: fileURL, encoder: encoder)
  }
}

// MARK: - Identifier helpers

struct IssueIdentifierGenerator {
  static func makeIdentifier(from title: String) -> String {
    let lowercased = title.lowercased()
    let scalars = lowercased.unicodeScalars.map { scalar -> Character in
      if CharacterSet.alphanumerics.contains(scalar) { return Character(scalar) }
      return "-"
    }
    var collapsed: [Character] = []
    var previousWasHyphen = false
    for character in scalars {
      if character == "-" {
        if previousWasHyphen { continue }
        previousWasHyphen = true
        collapsed.append(character)
      } else {
        previousWasHyphen = false
        collapsed.append(character)
      }
    }
    let trimmed = String(collapsed).trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    return trimmed.isEmpty ? "issue" : trimmed
  }
}

// MARK: - Manifest resolution

struct IssuesManifestContext: Sendable {
  var agentDirectory: URL
  var issuesDirectory: URL
  var manifestURL: URL
}

enum IssuesManifestResolverError: Error, CustomStringConvertible, Sendable {
  case agentDirectoryNotFound(slug: String)

  var description: String {
    switch self {
    case .agentDirectoryNotFound(let slug):
      return
        "Could not locate agent directory for slug \(slug). Confirm it exists under .clia/agents/."
    }
  }
}

struct IssuesManifestResolver {
  func resolve(
    slug: String,
    manifestName: String,
    workingDirectory: URL,
    createIssuesDirectoryIfNeeded: Bool
  ) throws -> IssuesManifestContext {
    let agentDirectory = try resolveAgentDirectory(slug: slug, startingFrom: workingDirectory)
    let issuesDirectory = agentDirectory.appendingPathComponent("issues", isDirectory: true)
    let fileManager = FileManager.default
    var isDirectory: ObjCBool = false
    if fileManager.fileExists(atPath: issuesDirectory.path, isDirectory: &isDirectory) {
      if !isDirectory.boolValue {
        throw NSError(
          domain: "IssuesManifestResolver", code: 1,
          userInfo: [NSLocalizedDescriptionKey: "Expected directory at \(issuesDirectory.path)"]
        )
      }
    } else if createIssuesDirectoryIfNeeded {
      try fileManager.createDirectory(at: issuesDirectory, withIntermediateDirectories: true)
    }

    let manifestURL = issuesDirectory.appendingPathComponent(manifestName)
    return IssuesManifestContext(
      agentDirectory: agentDirectory,
      issuesDirectory: issuesDirectory,
      manifestURL: manifestURL
    )
  }

  private func resolveAgentDirectory(slug: String, startingFrom cwd: URL) throws -> URL {
    let contexts = LineageResolver.findAgentDirs(for: slug, under: cwd)
    if let context = contexts.last { return context.dir }

    var current = cwd
    let fileManager = FileManager.default
    while true {
      let candidate = current.appendingPathComponent(
        ".clia/agents/\(slug)", isDirectory: true)
      var isDirectory: ObjCBool = false
      if fileManager.fileExists(atPath: candidate.path, isDirectory: &isDirectory),
        isDirectory.boolValue
      {
        return candidate
      }
      let parent = current.deletingLastPathComponent()
      if parent.path == current.path { break }
      current = parent
    }

    throw IssuesManifestResolverError.agentDirectoryNotFound(slug: slug)
  }
}

// MARK: - Status analysis

enum ProjectIssueStatus: String, Codable, CaseIterable, Sendable {
  case pending
  case synced
  case stale
  case invalid
}

struct IssueAnalysis: Sendable {
  var issue: ProjectIssue
  var status: ProjectIssueStatus
  var notes: [String]

  init(issue: ProjectIssue, status: ProjectIssueStatus, notes: [String] = []) {
    self.issue = issue
    self.status = status
    self.notes = notes
  }
}

struct IssuesAuditResult: Sendable {
  var entries: [IssueAnalysis]
  var duplicateIdentifiers: [String]

  var pendingEntries: [IssueAnalysis] { entries.filter { $0.status == .pending } }
  var syncedEntries: [IssueAnalysis] { entries.filter { $0.status == .synced } }
  var staleEntries: [IssueAnalysis] { entries.filter { $0.status == .stale } }
  var invalidEntries: [IssueAnalysis] { entries.filter { $0.status == .invalid } }
}

struct IssuesManifestAnalyzer {
  func analyze(manifest: IssuesManifest) -> IssuesAuditResult {
    var entries: [IssueAnalysis] = manifest.issues.map { issue in
      var notes: [String] = []
      let trimmedTitle = issue.title.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmedTitle.isEmpty { notes.append("missing title") }
      let trimmedBody = issue.body.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmedBody.isEmpty { notes.append("missing body") }

      let baseStatus: ProjectIssueStatus
      if issue.githubIssue == nil {
        baseStatus = .pending
      } else if issue.githubIssue?.state?.lowercased() == "closed" {
        baseStatus = .stale
      } else {
        baseStatus = .synced
      }

      let status: ProjectIssueStatus = notes.isEmpty ? baseStatus : .invalid
      return IssueAnalysis(issue: issue, status: status, notes: notes)
    }

    var identifierCounts: [String: Int] = [:]
    for entry in entries { identifierCounts[entry.issue.identifier, default: 0] += 1 }

    var duplicateIdentifiers: [String] = []
    for index in entries.indices {
      let identifier = entries[index].issue.identifier
      if let count = identifierCounts[identifier], count > 1 {
        if !duplicateIdentifiers.contains(identifier) { duplicateIdentifiers.append(identifier) }
        entries[index].status = .invalid
        if !entries[index].notes.contains("duplicate identifier") {
          entries[index].notes.append("duplicate identifier")
        }
      }
    }

    return IssuesAuditResult(entries: entries, duplicateIdentifiers: duplicateIdentifiers.sorted())
  }
}
