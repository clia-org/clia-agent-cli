import ArgumentParser
import ConsoleKitTerminal
import Foundation
import SwiftFigletKit

enum SwiftFigletIntro {
  enum BannerColorTheme: String, ExpressibleByArgument {
    case none, info, success, warning, accent, random
  }

  enum BannerGradientStyle: String, ExpressibleByArgument { case off, lines }

  private static func colorize(_ text: String, theme: BannerColorTheme) -> String {
    if ProcessInfo.inXcodeEnvironment || theme == .none { return text }
    let start: String
    switch theme {
    case .none: return text
    case .random:
      let options = [
        "\u{001B}[36m", "\u{001B}[32m", "\u{001B}[33m", "\u{001B}[35m", "\u{001B}[34m",
        "\u{001B}[31m",
      ]
      let start = options.randomElement() ?? "\u{001B}[36m"
      return start + text + "\u{001B}[0m"
    case .info: start = "\u{001B}[36m"
    case .success: start = "\u{001B}[32m"
    case .warning: start = "\u{001B}[33m"
    case .accent: start = "\u{001B}[35m"
    }
    return start + text + "\u{001B}[0m"
  }

  static func show(
    on terminal: inout Terminal,
    text: String = "C.L.I.A.",
    color: BannerColorTheme = .none,
    gradient: BannerGradientStyle = .off,
    fontName: String? = nil
  ) {
    if gradient == .lines {
      let out =
        SFKRenderer.renderGradientLines(
          text: text,
          fontName: fontName ?? "random",
          palette: nil,
          randomizePalette: color == .random,
          forceColor: false,
          disableColorInXcode: true,
        ) ?? (text + "\n")
      terminal.output(ConsoleText(stringLiteral: out))
      return
    }
    let ansi: SFKRenderer.ANSIColor = {
      switch color {
      case .none: return .none
      case .info: return .cyan
      case .success: return .green
      case .warning: return .yellow
      case .accent: return .magenta
      case .random:
        let opts: [SFKRenderer.ANSIColor] = [.cyan, .green, .yellow, .magenta, .blue, .red, .white]
        return opts.randomElement() ?? .cyan
      }
    }()
    let rendered =
      SFKRenderer.render(
        text: text,
        fontName: fontName ?? "random",
        color: ansi
      ) ?? (text + "\n")
    terminal.output(ConsoleText(stringLiteral: rendered))
  }
}
