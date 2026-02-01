import CLIACoreModels
import Foundation

public enum HeaderPresenter {
  /// Render header lines via ConversationHeader using the environment-backed workspace header.
  public static func render(
    slug: String = "codex", under root: URL, mode: String? = nil, title: String? = nil
  ) -> ConversationHeader.Lines? {
    ConversationHeader.render(slug: slug, under: root, mode: mode, title: title)
  }

  /// Apply presentation rules (theme + severity coloring) and return printable lines.
  /// - Parameters:
  ///   - root: repository root (to read workspace + incident)
  ///   - lines: raw lines from ConversationHeader.render
  ///   - useTerminalogyTheme: when nil, reads preferences.useTerminalogyTheme from workspace;
  ///     when non-nil, uses the provided override.
  public static func present(
    under root: URL,
    lines: ConversationHeader.Lines,
    useTerminalogyTheme: Bool? = nil
  ) -> [String] {
    // Line 1: optional theme color (suppressed in Xcode)
    let line1Out: String = {
      guard !ProcessInfo.inXcodeEnvironment,
        resolveUseTheme(under: root, override: useTerminalogyTheme)
      else { return lines.line1 }
      if let ws = try? WorkspaceConfig.load(under: root),
        let model = TerminalogyService.loadEffective(under: root, from: ws.terminalogy),
        let hex = model.theme?.primary
      {
        return colorize(hex: hex, text: lines.line1)
      }
      return lines.line1
    }()

    // Line 2: as-is
    let line2Out = lines.line2

    // Line 3: incident banner (severity colored outside Xcode)
    let line3Out: String? = {
      guard let l3 = lines.line3 else { return nil }
      return ProcessInfo.inXcodeEnvironment ? l3 : colorizeSeverityLine(l3)
    }()

    return [line1Out, line2Out] + (line3Out.map { [$0] } ?? [])
  }

  private static func resolveUseTheme(under root: URL, override: Bool?) -> Bool {
    if let o = override { return o }
    if let ws = try? WorkspaceConfig.load(under: root),
      let pref = ws.preferences?.useTerminalogyTheme
    {
      return pref
    }
    return false
  }

  private static func colorizeSeverityLine(_ text: String) -> String {
    let upper = text.uppercased()
    let code: String
    if upper.contains(" S1 ") {
      code = "\u{001B}[31m"
    } else if upper.contains(" S2 ") {
      code = "\u{001B}[33m"
    } else if upper.contains(" S3 ") {
      code = "\u{001B}[36m"
    } else {
      code = "\u{001B}[35m"
    }
    return code + text + "\u{001B}[0m"
  }

  private static func colorize(hex: String, text: String) -> String {
    func hexToRGB(_ s: String) -> (Int, Int, Int)? {
      let cs = s.trimmingCharacters(in: .whitespacesAndNewlines)
      let clean = cs.hasPrefix("#") ? String(cs.dropFirst()) : cs
      guard clean.count == 6, let v = Int(clean, radix: 16) else { return nil }
      return ((v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF)
    }
    guard let (r, g, b) = hexToRGB(hex) else { return text }
    return "\u{001B}[38;2;\(r);\(g);\(b)m" + text + "\u{001B}[0m"
  }
}
