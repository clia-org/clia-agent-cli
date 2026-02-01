import Foundation
import WrkstrmFoundation
import WrkstrmMain

public struct JournalEntry: Codable, Sendable {
  public var date: String
  public var timestamp: String
  public var agentVersion: String?
  public var highlights: [String]
  public var focus: [String]
  public var nextSteps: [String]
  public var signature: String?
  public var x_dirsTouched: [String]?

  enum CodingKeys: String, CodingKey {
    case date, timestamp, agentVersion, highlights, focus, nextSteps, signature
    case x_dirsTouched = "x-dirsTouched"
  }
}

public enum JournalWriter {
  public static func append(
    slug: String,
    workingDirectory: URL,
    agentVersion: String? = nil,
    highlights: [String] = [],
    focus: [String] = [],
    nextSteps: [String] = [],
    signature: String? = "auto",
    dirsTouched: [String]? = nil
  ) throws -> URL {
    let target = try WriteTargetResolver.resolve(
      for: slug, startingAt: workingDirectory, scope: .submodule)
    let fm = FileManager.default

    var resolvedSignature: String? = nil
    if let signature {
      if signature == "auto" {
        resolvedSignature = try loadSignature(slug: slug, agentDir: target.agentDir)
      } else if !signature.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        resolvedSignature = signature
      }
    }

    let now = Date()
    let dayFmt = DateFormatter()
    dayFmt.locale = .init(identifier: "en_US_POSIX")
    dayFmt.timeZone = .init(secondsFromGMT: 0)
    dayFmt.dateFormat = "yyyy-MM-dd"
    let day = dayFmt.string(from: now)
    let iso = ISO8601DateFormatter()
    iso.timeZone = .init(secondsFromGMT: 0)
    let entry = JournalEntry(
      date: day,
      timestamp: iso.string(from: now),
      agentVersion: agentVersion,
      highlights: highlights,
      focus: focus,
      nextSteps: nextSteps,
      signature: resolvedSignature,
      x_dirsTouched: dirsTouched
    )

    let journalDir = target.agentDir.appendingPathComponent("journal", isDirectory: true)
    try fm.createDirectory(at: journalDir, withIntermediateDirectories: true)
    let out = journalDir.appendingPathComponent("\(day).json")
    try JSON.FileWriter.write(entry, to: out, encoder: JSON.Formatting.humanEncoder)

    if let dirs = dirsTouched, !dirs.isEmpty {
      try upsertAgencyDirsTouched(in: target.agentDir, dirs: dirs)
    }
    return out
  }

  private static func loadSignature(slug: String, agentDir: URL) throws -> String? {
    let fm = FileManager.default
    guard
      let url = try fm.contentsOfDirectory(at: agentDir, includingPropertiesForKeys: nil)
        .first(where: {
          $0.lastPathComponent.hasSuffix(".agent.json")
            && !$0.lastPathComponent.contains(".agency.")
        })
    else { return nil }
    let data = try Data(contentsOf: url)
    guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      return nil
    }
    if let ext = obj["extensions"] as? [String: Any] {
      if let sig = ext["journalSignature"] as? String,
        !sig.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      {
        return sig
      }
    }
    return nil
  }

  private static func upsertAgencyDirsTouched(in agentDir: URL, dirs: [String]) throws {
    let fm = FileManager.default
    guard
      let agencyURL = try fm.contentsOfDirectory(at: agentDir, includingPropertiesForKeys: nil)
        .first(where: { $0.lastPathComponent.hasSuffix(".agency.json") })
    else { return }
    guard
      var obj = try JSONSerialization.jsonObject(with: Data(contentsOf: agencyURL))
        as? [String: Any]
    else { return }
    var ext = (obj["extensions"] as? [String: Any]) ?? [:]
    var existing = (ext["x-dirsTouched"] as? [String]) ?? []
    var seen = Set(existing)
    for d in dirs where seen.insert(d).inserted { existing.append(d) }
    ext["x-dirsTouched"] = existing
    obj["extensions"] = ext
    obj["updated"] = ISO8601DateFormatter().string(from: Date())
    try JSON.FileWriter.writeJSONObject(obj, to: agencyURL, options: JSON.Formatting.humanOptions)
  }
}
