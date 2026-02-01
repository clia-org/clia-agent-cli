import CLIACore
import CLIACoreModels
import Foundation

// Presents an agent avatar in compatible terminals (iTerm2/Kitty). Falls back to
// printing the relative path when inline graphics are not supported.
public enum AvatarPresenter {
  public static func show(slug: String, under root: URL) {
    // Resolve merged agent view to read avatarPath and title
    let view = Merger.mergeAgent(slug: slug, under: root)
    guard let path = view.avatarPath else { return }
    // Compute URL (repo-relative by default)
    let url: URL = {
      let p = path.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
      if p.hasPrefix("/") || p.contains("://") { return URL(fileURLWithPath: p) }
      return root.appendingPathComponent(p)
    }()
    guard let data = try? Data(contentsOf: url), !data.isEmpty else {
      fputs("[avatar] not found: \(url.path)\n", stderr)
      return
    }

    let env = ProcessInfo.processInfo.environment
    if let termProg = env["TERM_PROGRAM"], termProg.lowercased().contains("iterm") {
      // iTerm2 inline image (OSC 1337)
      let esc = "\u{001B}"
      let bel = "\u{0007}"
      let nameB64 = url.lastPathComponent.data(using: .utf8)?.base64EncodedString() ?? ""
      let payload = data.base64EncodedString()
      let seq =
        "\(esc)]1337;File=inline=1;preserveAspectRatio=1;width=auto;height=auto;name=\(nameB64):\(payload)\(bel)"
      print(seq)
      return
    }
    if env["TERM"]?.contains("kitty") == true || env["KITTY_WINDOW_ID"] != nil {
      // Kitty graphics protocol (simplified): ESC_G ... ESC\
      let esc = "\u{001B}"
      let st = "\u{001B}\\"
      let payload = data.base64EncodedString()
      let seq = "\(esc)_Gf=100,a=T,t=d;\(payload)\(st)"  // f=100 (PNG/JPG auto), transmit, base64 data
      print(seq)
      return
    }
    // Fallback: show path when terminal doesn't support inline images
    print("avatar: \(url.path)")
  }
}
