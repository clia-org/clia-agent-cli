import CLIACoreModels
import Foundation

public enum OriginDeriver {
  public static func derive(for slug: String, under root: URL) -> Origin? {
    let fm = FileManager.default
    var provenance: [OriginProvenance] = []
    var visitedAgents = Set<String>()  // absolute agent .agent.json paths

    func add(_ rec: OriginProvenance) {
      provenance.append(rec)
    }

    func processAgent(at agentURL: URL, inheritedFrom: String?) {
      let key = agentURL.standardizedFileURL.path
      guard visitedAgents.insert(key).inserted else { return }
      let dir = agentURL.deletingLastPathComponent()
      // Evidence from this directory's triads
      // 1) Agency entries
      if let agencyURL = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
        .first(where: { $0.lastPathComponent.contains(".agency.json") })
      {
        if let data = try? Data(contentsOf: agencyURL),
          let doc = try? JSONDecoder().decode(AgencyDoc.self, from: data)
        {
          // Consider profile 'updated' as best-effort evidence
          if !doc.updated.isEmpty {
            add(
              .init(
                source: "updated:agency", path: rel(agencyURL, root: root), value: doc.updated,
                inheritedFrom: inheritedFrom))
          }
          for e in doc.entries {
            add(
              .init(
                source: "agencyEntry", path: rel(agencyURL, root: root), value: e.timestamp,
                inheritedFrom: inheritedFrom))
          }
          // Also consider note timestamps
          for n in doc.notes {
            if let ts = n.timestamp, !ts.isEmpty {
              add(
                .init(
                  source: "note", path: rel(agencyURL, root: root), value: ts,
                  inheritedFrom: inheritedFrom))
            }
          }
        }
      }
      // 2) Agent notes
      if let data = try? Data(contentsOf: agentURL),
        let agentDoc = try? JSONDecoder().decode(AgentDoc.self, from: data)
      {
        if !agentDoc.updated.isEmpty {
          add(
            .init(
              source: "updated:agent", path: rel(agentURL, root: root), value: agentDoc.updated,
              inheritedFrom: inheritedFrom))
        }
        for n in agentDoc.notes {
          if let ts = n.timestamp, !ts.isEmpty {
            add(
              .init(
                source: "note", path: rel(agentURL, root: root), value: ts,
                inheritedFrom: inheritedFrom))
          }
        }
      }
      // 3) Agenda notes
      if let agendaURL = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
        .first(where: { $0.lastPathComponent.contains(".agenda.json") })
      {
        if let data = try? Data(contentsOf: agendaURL),
          let doc = try? JSONDecoder().decode(AgendaDoc.self, from: data)
        {
          if !doc.updated.isEmpty {
            add(
              .init(
                source: "updated:agenda", path: rel(agendaURL, root: root), value: doc.updated,
                inheritedFrom: inheritedFrom))
          }
          for n in doc.notes {
            if let ts = n.timestamp, !ts.isEmpty {
              add(
                .init(
                  source: "note", path: rel(agendaURL, root: root), value: ts,
                  inheritedFrom: inheritedFrom))
            }
          }
        }
      }
      // Recurse inherits
      if let raw = try? Data(contentsOf: agentURL),
        let obj = try? JSONSerialization.jsonObject(with: raw) as? [String: Any]
      {
        if let inh = obj["inherits"] as? [String] {
          for ref in inh {
            if ref.hasPrefix("http://") || ref.hasPrefix("https://") { continue }
            let child = root.appendingPathComponent(ref).standardizedFileURL
            let childSlug = Self.slug(from: child)
            if fm.fileExists(atPath: child.path) {
              processAgent(at: child, inheritedFrom: childSlug)
            }
          }
        }
      }
    }

    // Entry points across lineage contexts
    let items = LineageResolver.findAgentDirs(for: slug, under: root)
    for item in items {
      let agentURL = item.agentURL
      processAgent(at: agentURL, inheritedFrom: nil)
    }

    guard !provenance.isEmpty else { return Origin(firstObservedAt: nil, provenance: []) }
    // Oldest→newest
    provenance.sort { parseDate($0.value) < parseDate($1.value) }
    let first = provenance.first?.value
    return Origin(firstObservedAt: first, provenance: provenance)
  }

  private static func parseDate(_ s: String) -> Date {
    let f = ISO8601DateFormatter()
    if let d = f.date(from: s) { return d }
    // As a fallback, try lossy parsing without fractional seconds
    let fmt = ISO8601DateFormatter()
    fmt.formatOptions = [.withInternetDateTime]
    return fmt.date(from: s) ?? Date.distantFuture
  }

  private static func rel(_ url: URL, root: URL) -> String {
    let p = url.standardizedFileURL.path
    let r = root.standardizedFileURL.path
    if p.hasPrefix(r + "/") { return String(p.dropFirst(r.count + 1)) }
    return url.lastPathComponent
  }

  private static func slug(from agentURL: URL) -> String? {
    let comps = agentURL.pathComponents
    if let idx = comps.firstIndex(of: "agents"), idx + 1 < comps.count { return comps[idx + 1] }
    return nil
  }
}
