import CLIACoreModels
import Foundation

public enum TerminalogyService {
  public struct Model: Decodable {
    public var naming: Naming?
    public var theme: Theme?
    public struct Naming: Decodable {
      public var repo: String?
      public var ghost: String?
      public var agent: String?
    }
    public struct Theme: Decodable {
      public var primary: String?
      public var secondary: String?
      public var muted: String?
      public var accent: String?
      public var danger: String?
      public var success: String?
    }
  }

  public static func loadEffective(under root: URL, from cfg: WorkspaceConfig.Terminalogy?)
    -> Model?
  {
    guard let cfg else { return nil }
    var base: Model = .init(naming: nil, theme: nil)
    if let path = cfg.ref {
      let url = root.appendingPathComponent(path)
      if let data = try? Data(contentsOf: url),
        let decoded = try? JSONDecoder().decode(Model.self, from: data)
      {
        base = decoded
      }
    }
    // Apply override (shallow merge)
    if let o = cfg.override {
      var naming = base.naming ?? .init(repo: nil, ghost: nil, agent: nil)
      var theme =
        base.theme
        ?? .init(primary: nil, secondary: nil, muted: nil, accent: nil, danger: nil, success: nil)
      if let nn = o.naming {
        naming.repo = nn.repo ?? naming.repo
        naming.ghost = nn.ghost ?? naming.ghost
        naming.agent = nn.agent ?? naming.agent
      }
      if let th = o.theme {
        theme.primary = th.primary ?? theme.primary
        theme.secondary = th.secondary ?? theme.secondary
        theme.muted = th.muted ?? theme.muted
        theme.accent = th.accent ?? theme.accent
        theme.danger = th.danger ?? theme.danger
        theme.success = th.success ?? theme.success
      }
      return .init(naming: naming, theme: theme)
    }
    return base
  }
}
