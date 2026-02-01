import ArgumentParser
import ConsoleKitTerminal
import Foundation
import SwiftFigletKit

extension Clia {
  struct Doctor: AsyncParsableCommand {
    static let configuration: CommandConfiguration = .init(
      abstract: "Check provider configuration and connectivity.",
    )

    @ArgumentParser.Option(name: .long, help: "Provider to check: openai or gemini")
    var provider: ProviderOption = .openai

    @ArgumentParser.Flag(name: .long, help: "Attempt to list models (2s timeout)")
    var listModels: Bool = false

    @ArgumentParser.Option(name: .long, help: "API key override")
    var apiKey: String?

    @ArgumentParser.Option(name: .long, help: "OpenAI org id (optional)")
    var org: String?

    @ArgumentParser.Flag(
      name: .customLong("no-banner"), help: "Suppress the Figlet banner (useful for scripts)",
    )
    var noBanner: Bool = false

    @ArgumentParser.Option(
      name: .customLong("banner-color"),
      help: "Banner color: none|info|success|warning|accent|random (default: none)",
    )
    var bannerColor: SwiftFigletIntro.BannerColorTheme = .none
    @ArgumentParser.Option(
      name: .customLong("banner-gradient"), help: "Banner gradient: off|lines (default: off)",
    )
    var bannerGradient: SwiftFigletIntro.BannerGradientStyle = .off

    func run() async throws {
      if !noBanner {
        var term = Terminal()
        SwiftFigletIntro.show(
          on: &term, text: "C.L.I.A.", color: bannerColor, gradient: bannerGradient,
        )
      }
      print("Clia Doctor\n-----------")
      let openAIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
      print("OpenAI key: \(openAIKey == nil ? "not set" : "present")")
      let geminiKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"]
      print("Gemini key: \(geminiKey == nil ? "not set" : "present")")
      if listModels {
        do {
          let svc: any AIProvider = try ProviderFactory.makeProvider(
            option: provider,
            apiKeyFlag: apiKey,
            orgFlag: org,
          )
          let start = Date()
          let models = await (try? svc.listModels()) ?? []
          let elapsed = Date().timeIntervalSince(start)
          let note = models.isEmpty || elapsed > 1.9 ? "(none or timeout)" : String(models.count)
          print("Provider: \(provider) — models: \(note)")
          if !models.isEmpty { print(models.prefix(10).joined(separator: ", ")) }
        } catch {
          print("Provider error: \(error.localizedDescription)")
        }
      } else {
        print("Tip: run with --list-models to attempt listing models (2s timeout)")
      }
      print("Default OpenAI model: gpt-4o-mini")
      print("Default Gemini model: gemini-1.5-flash-latest")
      print("Tip: pass --api-key or set env vars as above.")
    }
  }
}
