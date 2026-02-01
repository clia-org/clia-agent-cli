import ArgumentParser
import CLIAAgentCoreCLICommands
import CLIACore
import CLIACoreModels
import CommonAI
import CommonProcess
import ConsoleKitTerminal
import Foundation
import Markdown
import WrkstrmFoundation
import CommonLog
import WrkstrmMain

#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

// Providers

// Local provider protocol & implementations
// Note: these files live under Sources/Providers
// - AIProvider.swift
// - OpenAIProvider.swift

enum ProviderOption: String, ExpressibleByArgument {
  case openai
  case gemini
  case apple

  var displayName: String {
    switch self {
    case .openai: "OpenAI"
    case .gemini: "Gemini"
    case .apple: "Apple Intelligence"
    }
  }
}

extension Clia {
  struct Ask: AsyncParsableCommand {
    static let configuration: CommandConfiguration = .init(
      commandName: "chat",
      abstract: "Chat with a model (OpenAI, Gemini, or Apple Intelligence).",
    )

    enum OneShotOutputFormat: String, ExpressibleByArgument, CaseIterable {
      case auto
      case json
      case text
    }

    // Final block formatting options
    enum FinalFormat: String, ExpressibleByArgument { case markdown, plain }

    enum FinalColorTheme: String, ExpressibleByArgument {
      case none, info, success, warning, accent
    }

    enum FinalDivider: String, ExpressibleByArgument { case none, thin, thick }

    enum FinalBorder: String, ExpressibleByArgument { case none, single, double }

    enum HeaderDetail: String, ExpressibleByArgument, CaseIterable {
      case provider, model, elapsed, none
    }

    enum ShellOutputFormat: String, ExpressibleByArgument, CaseIterable {
      case text
      case json
    }

    enum FooterDetail: String, ExpressibleByArgument, CaseIterable {
      case tokens, rate, timestamp, none
    }

    // Quick presets
    enum FinalStyle: String, ExpressibleByArgument { case minimal, framed, compact }

    struct ProviderOptions: ParsableArguments {
      @ArgumentParser.Option(name: .long, help: "Provider to use: openai, gemini, or apple")
      var provider: ProviderOption?

      @ArgumentParser.Option(name: .long, help: "Model identifier")
      var model: String?

      @ArgumentParser.Option(name: .long, help: "System instruction to prepend")
      var system: String?

      @ArgumentParser.Option(name: .long, help: "API key (fallback if env not set)")
      var apiKey: String?

      @ArgumentParser.Option(name: .long, help: "OpenAI organization id (optional)")
      var org: String?
    }

    struct PromptOptions: ParsableArguments {
      @ArgumentParser.Option(
        name: .customLong("prompt"),
        help: "One-shot prompt text; when set, CLIA sends it once and exits.",
      )
      var promptText: String?

      @ArgumentParser.Option(
        name: .customLong("one-shot-output"),
        help: "Output format when using a one-shot prompt: auto|json|text (default auto).",
      )
      var oneShotOutput: OneShotOutputFormat = .auto
    }

    struct StreamOptions: ParsableArguments {
      @ArgumentParser.Flag(name: .long, help: "Stream the response if supported")
      var stream: Bool = false

      @ArgumentParser.Flag(
        name: .customLong("stream-final-summary"),
        inversion: .prefixedNo,
        help:
          "When streaming, replace live output with a final formatted summary (use --no-stream-final-summary to keep live output).",
      )
      var streamFinalSummary: Bool = true

      @ArgumentParser.Flag(
        name: .customLong("stream-coalesce-lines"),
        inversion: .prefixedNo,
        help: "Coalesce streamed output to whole lines (default on).",
      )
      var streamCoalesceLines: Bool = true

      @ArgumentParser.Flag(
        name: .customLong("stream-summary-below"),
        help: "Do not erase streamed lines; print final summary below instead.",
      )
      var streamSummaryBelow: Bool = false
    }

    struct FinalRenderOptions: ParsableArguments {
      @ArgumentParser.Option(
        name: .customLong("final-format"), help: "Final format: markdown|plain (default: markdown)",
      )
      var finalFormat: FinalFormat = .markdown

      @ArgumentParser.Option(
        name: .customLong("final-title"), help: "Title text (use --no-final-title to hide)",
      )
      var finalTitle: String = "Assistant"

      @ArgumentParser.Flag(name: .customLong("no-final-title"), help: "Hide final title line")
      var noFinalTitle: Bool = false

      @ArgumentParser.Option(
        name: .customLong("final-prefix"), help: "Prefix label (default: 'Assistant:')",
      )
      var finalPrefix: String = "Assistant:"

      @ArgumentParser.Flag(
        name: .customLong("final-newline"),
        inversion: .prefixedNo,
        help: "Ensure trailing newline after final block (default on)",
      )
      var finalNewline: Bool = true

      @ArgumentParser.Option(
        name: .customLong("final-style"), help: "Preset: minimal|framed|compact")
      var finalStyle: FinalStyle?
    }

    struct HeaderOptions: ParsableArguments {
      @ArgumentParser.Option(
        name: .customLong("slug"),
        help: "Agent slug used for banner/header/avatar (default: codex)")
      var slug: String = "codex"
    }

    struct BannerOptions: ParsableArguments {
      @ArgumentParser.Flag(
        name: .customLong("no-banner"), help: "Suppress the Figlet banner (useful for scripts)",
      )
      var noBanner: Bool = false

      var bannerColor: SwiftFigletIntro.BannerColorTheme { .none }
      var bannerGradient: SwiftFigletIntro.BannerGradientStyle { .off }
    }

    struct ShellOptions: ParsableArguments {
      @ArgumentParser.Option(
        name: .customLong("shell-output"),
        help: "Shell output format for ! commands: text|json (default text)."
      )
      var shellOutputFormat: ShellOutputFormat = .text

      @ArgumentParser.Flag(
        name: .customLong("shell-metadata"),
        help: "Include CommonProcess metadata for ! commands."
      )
      var shellMetadata: Bool = false

      @ArgumentParser.Flag(
        name: .customLong("shell-trace"),
        help: "Enable CommonLog tracing for shell execution."
      )
      var shellTrace: Bool = false
    }

    @OptionGroup var providerOptions: ProviderOptions
    @OptionGroup var promptOptions: PromptOptions
    @OptionGroup var streamOptions: StreamOptions
    @OptionGroup var finalOptions: FinalRenderOptions
    @OptionGroup var bannerOptions: BannerOptions
    @OptionGroup var headerOptions: HeaderOptions
    @OptionGroup var shellOptions: ShellOptions

    @Flag(
      name: .customLong("use-terminalogy-theme"), inversion: .prefixedNo,
      help:
        "Apply terminalogy theme primary color to the header line (off in Xcode). Use --no-use-terminalogy-theme to disable."
    )
    var useTerminalogyTheme: Bool = false

    var provider: ProviderOption? { providerOptions.provider }
    var model: String? { providerOptions.model }
    var system: String? { providerOptions.system }
    var apiKey: String? { providerOptions.apiKey }
    var org: String? { providerOptions.org }

    var promptText: String? { promptOptions.promptText }
    var oneShotOutput: OneShotOutputFormat { promptOptions.oneShotOutput }

    var stream: Bool { streamOptions.stream }
    var streamFinalSummary: Bool { streamOptions.streamFinalSummary }
    var streamCoalesceLines: Bool { streamOptions.streamCoalesceLines }
    var streamSummaryBelow: Bool { streamOptions.streamSummaryBelow }

    var finalFormat: FinalFormat { finalOptions.finalFormat }
    var finalTitle: String { finalOptions.finalTitle }
    var noFinalTitle: Bool { finalOptions.noFinalTitle }
    var finalPrefix: String { finalOptions.finalPrefix }
    var finalNewline: Bool { finalOptions.finalNewline }
    var finalStyle: FinalStyle? { finalOptions.finalStyle }

    var noBanner: Bool { bannerOptions.noBanner }
    var bannerColor: SwiftFigletIntro.BannerColorTheme { bannerOptions.bannerColor }
    var bannerGradient: SwiftFigletIntro.BannerGradientStyle { bannerOptions.bannerGradient }

    private struct LoadedDesignSystems {
      let terminalDesignSystem: String?
      let doccDesignSystem: String?
    }

    private func loadDesignSystems(under repoRoot: URL) -> LoadedDesignSystems {
      func read(_ relativePath: String) -> String? {
        let url = repoRoot.appendingPathComponent(relativePath)
        return try? String(contentsOf: url, encoding: .utf8)
      }

      func join(_ parts: [String?]) -> String? {
        let merged = parts.compactMap { text in
          guard let text else { return nil }
          let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
          return trimmed.isEmpty ? nil : trimmed
        }.joined(separator: "\n\n")
        return merged.isEmpty ? nil : merged + "\n"
      }

      return .init(
        terminalDesignSystem: join([
          read(
            "docc/design-systems.docc/articles/terminal-design-system-principles.md"
          ),
          read(
            "docc/design-systems.docc/articles/terminal-design-system-patterns.md"
          ),
          read(
            "docc/design-systems.docc/articles/terminal-design-system-emoji-palette.md"
          ),
          read(
            "docc/design-systems.docc/articles/terminal-design-system-checklists.md"
          ),
        ]),
        doccDesignSystem: read(
          "docc/design-systems.docc/articles/docc-design-system-patterns.md"
        )
      )
    }

    private func loadAgentSystemInstructions(slug: String, under repoRoot: URL) -> String? {
      let merged = Merger.mergeAgent(slug: slug, under: repoRoot)
      guard let compactPath = merged.systemInstructions?.compactPath, !compactPath.isEmpty else {
        return nil
      }
      let url = repoRoot.appendingPathComponent(compactPath)
      if let text = try? String(contentsOf: url, encoding: .utf8) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed + "\n"
      }
      return nil
    }

    private func promptTouchesDocc(_ prompt: String) -> Bool {
      let lower = prompt.lowercased()
      return lower.contains(".docc") || lower.contains("@technologyroot")
    }

    private func buildEffectiveSystem(
      prompt: String,
      explicitSystem: String?,
      agentSystemInstructions: String?,
      designSystems: LoadedDesignSystems?
    ) -> String? {
      var chunks: [String] = []

      if let explicitSystem {
        let trimmed = explicitSystem.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
          chunks.append(trimmed)
        }
      }

      if let agentSystemInstructions {
        chunks.append(agentSystemInstructions)
      }

      if let terminalDesignSystem = designSystems?.terminalDesignSystem,
        !terminalDesignSystem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      {
        chunks.append(
          """
          == terminal design system (required) ==
          \(terminalDesignSystem)
          """
        )
      }
      if promptTouchesDocc(prompt),
        let doccDesignSystem = designSystems?.doccDesignSystem,
        !doccDesignSystem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      {
        chunks.append(
          """
          == docc design system (required when touching .docc) ==
          \(doccDesignSystem)
          """
        )
      }

      let merged =
        chunks
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: "\n\n")
        .trimmingCharacters(in: .whitespacesAndNewlines)

      return merged.isEmpty ? nil : merged
    }

    private func defaultModel(for provider: ProviderOption) -> String {
      switch provider {
      case .openai: "gpt-4o-mini"
      case .gemini: "gemini-1.5-flash-latest"
      case .apple: "apple.system.general"
      }
    }

    private struct ProviderResolution {
      let option: ProviderOption
      let instance: any AIProvider
      let notice: String?
    }

    private func resolveProvider(
      explicitProvider: ProviderOption?,
      modelWasExplicit: Bool,
      apiKeyFlag: String?,
      orgFlag: String?
    ) throws -> ProviderResolution {
      let requested = explicitProvider ?? .apple
      let providerWasExplicit = explicitProvider != nil
      if requested == .apple,
        !providerWasExplicit,
        !AppleProvider.isAvailable()
      {
        do {
          let fallbackInstance = try ProviderFactory.makeProvider(
            option: .openai,
            apiKeyFlag: apiKeyFlag,
            orgFlag: orgFlag
          )
          return .init(
            option: .openai,
            instance: fallbackInstance,
            notice: "Apple Intelligence unavailable; defaulting to OpenAI."
          )
        } catch {
          throw AppleProviderError.platformUnavailable
        }
      }
      do {
        let instance = try ProviderFactory.makeProvider(
          option: requested,
          apiKeyFlag: apiKeyFlag,
          orgFlag: orgFlag
        )
        return .init(option: requested, instance: instance, notice: nil)
      } catch let error as ProviderBuildError {
        guard case .missingAPIKey = error,
          requested == .openai,
          !providerWasExplicit,
          !modelWasExplicit,
          AppleProvider.isAvailable()
        else {
          throw error
        }
        let fallbackInstance = try ProviderFactory.makeProvider(
          option: .apple,
          apiKeyFlag: nil,
          orgFlag: nil
        )
        return .init(
          option: .apple,
          instance: fallbackInstance,
          notice: "OPENAI_API_KEY not found; defaulting to Apple Intelligence (local provider)."
        )
      }
    }

    private static func writeNoticeToStandardError(_ text: String) {
      guard !text.isEmpty else { return }
      if let data = (text + "\n").data(using: .utf8) {
        FileHandle.standardError.write(data)
      }
    }

    mutating func run() async throws {
      let resolution = try resolveProvider(
        explicitProvider: provider,
        modelWasExplicit: model != nil,
        apiKeyFlag: apiKey,
        orgFlag: org
      )
      let activeProvider = resolution.option
      let providerInstance = resolution.instance
      let resolvedModel = model ?? defaultModel(for: activeProvider)

      let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
      let repoRoot = findRepoRoot(startingAt: cwd)
      let agentSystemInstructions = repoRoot.flatMap {
        loadAgentSystemInstructions(slug: headerOptions.slug, under: $0)
      }
      let designSystems = repoRoot.map { loadDesignSystems(under: $0) }

      let explicitPrompt: String? = {
        guard let raw = promptText?.trimmingCharacters(in: .whitespacesAndNewlines),
          !raw.isEmpty
        else { return nil }
        return raw
      }()

      let stdinPrompt: String? = try readPromptFromStandardInputIfAvailable()
      let oneShotPrompt = explicitPrompt ?? stdinPrompt

      if let prompt = oneShotPrompt {
        guard !stream else {
          throw ValidationError("--stream is not supported in one-shot mode; remove --stream.")
        }
        if let notice = resolution.notice {
          Self.writeNoticeToStandardError(notice)
        }
        let effectiveSystem = buildEffectiveSystem(
          prompt: prompt,
          explicitSystem: system,
          agentSystemInstructions: agentSystemInstructions ?? nil,
          designSystems: designSystems
        )
        try await runOneShot(
          prompt: prompt,
          providerOption: activeProvider,
          providerInstance: providerInstance,
          modelIdentifier: resolvedModel,
          system: effectiveSystem
        )
        return
      }

      var terminal: Terminal = .init()
      if !noBanner {
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        var bannerText = "C.L.I.A."
        var bannerFont: String? = nil
        if let repoRoot = findRepoRoot(startingAt: cwd) {
          let view = Merger.mergeAgent(slug: headerOptions.slug, under: repoRoot)
          let trimmedTitle = view.title.trimmingCharacters(in: .whitespacesAndNewlines)
          if !trimmedTitle.isEmpty { bannerText = trimmedTitle }
          if let figlet = view.figletFontName {
            let t = figlet.trimmingCharacters(in: .whitespacesAndNewlines)
            if !t.isEmpty { bannerFont = t }
          } else if let ext = view.extensions, case .string(let f) = ext["figletFontName"] {
            let t = f.trimmingCharacters(in: .whitespacesAndNewlines)
            if !t.isEmpty { bannerFont = t }
          }
        }
        SwiftFigletIntro.show(
          on: &terminal,
          text: bannerText,
          color: bannerColor,
          gradient: bannerGradient,
          fontName: bannerFont
        )
        // Show avatar (if configured) for the active agent in this workspace.
        if let repoRoot = findRepoRoot(startingAt: cwd) {
          AvatarPresenter.show(slug: headerOptions.slug, under: repoRoot)
        }
      }
      // Standard conversation header (3 lines: line3 = incident when active)
      do {
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        if let lines = HeaderPresenter.render(slug: headerOptions.slug, under: cwd) {
          let themeOverride: Bool? = Self.cliOverridesThemeFlag() ? useTerminalogyTheme : nil
          let out = HeaderPresenter.present(
            under: cwd, lines: lines, useTerminalogyTheme: themeOverride)
          if out.count >= 2 {
            terminal.info(out[0])
            terminal.info(out[1])
          }
          if out.count >= 3 {
            if ProcessInfo.inXcodeEnvironment {
              terminal.error(out[2])
            } else {
              terminal.print(out[2])
            }
          }
        }
        // Load workspace.clia.json (required) and emoji posture
        do {
          let ws = try WorkspaceConfig.load(under: cwd)
          if let posture = ws.preferences?.emojiPosture?.lowercased() {
            self._emojiPosture = posture
          }
          // Default theme usage from workspace unless CLI override was given
          if !Self.cliOverridesThemeFlag(), let pref = ws.preferences?.useTerminalogyTheme {
            self.useTerminalogyTheme = pref
          }
        } catch {
          terminal.error("workspace.clia.json required: \(error.localizedDescription)")
          return
        }
      }
      if let notice = resolution.notice {
        terminal.info(notice)
      }
      var chatting = true
      let intentRouter = CLIAIntentRouter()
      let executor = CLIAExecutor()
      if shellOptions.shellTrace {
        Log.Inject.setBackend(.print)
        Log.globalExposureLevel = .trace
        Log.shared.trace("shell.trace enabled")
      }

      while chatting {
        let rawPrompt: String = terminal.ask(
          "What do you want to speak about today?".consoleText(.info))
        var prompt = rawPrompt
        let trimmed = rawPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowerAll = trimmed.lowercased()
        if lowerAll == "quit" || lowerAll == "exit" {
          chatting = false
          break
        }
        if trimmed.hasPrefix("!") {
          let payload = trimmed.dropFirst().drop { $0.isWhitespace }
          if payload.isEmpty {
            terminal.error("no command after '!'.")
            continue
          }
        }
        var wasShellExecution = false
        let intent: CLIAIntent
        do {
          intent = try intentRouter.route(rawPrompt)
        } catch {
          terminal.error("\(error)")
          continue
        }
        switch intent {
        case .execute(let spec):
          wasShellExecution = true
          do {
            let terminalOutput = terminal
            let startedAt = Date()
            Log.shared.trace("shell.run streaming input=\(rawPrompt)")
            let capture = ShellOutputCapture()
            let handleEvent: @Sendable (CLIARunEvent) -> Void = { event in
              switch event {
              case .stdout(let data):
                capture.appendStdout(data)
                terminalOutput.print(data)
              case .stderr(let data):
                capture.appendStderr(data)
                terminalOutput.error(data)
              case .completed(let exitCode, let processIdentifier):
                capture.setExitCode(exitCode)
                capture.setProcessIdentifier(processIdentifier)
                terminalOutput.print("exit: \(exitCode)")
              }
            }
            var streamingSpec = spec
            if streamingSpec.runnerKind == nil || streamingSpec.runnerKind == .auto {
              streamingSpec.runnerKind = .subprocess
            }
            try await executor.run(streamingSpec, emit: handleEvent)
            let snapshot = capture.snapshot()
            let finishedAt = Date()
            let summary = ShellExecutionSummary(
              input: rawPrompt,
              spec: streamingSpec,
              stdout: snapshot.stdout,
              stderr: snapshot.stderr,
              exitCode: snapshot.exitCode,
              processIdentifier: snapshot.processIdentifier,
              startedAt: startedAt,
              finishedAt: finishedAt
            )
            if shellOptions.shellOutputFormat == .json {
              printShellExecutionJSON(summary)
            }
            prompt = renderShellFollowupPrompt(
              summary: summary,
              includeMetadata: shellOptions.shellMetadata,
              error: (nil as Error?)
            )
          } catch {
            terminal.error("exec error: \(error)")
            let failureSummary = ShellExecutionSummary(
              input: rawPrompt,
              spec: spec,
              stdout: "",
              stderr: "",
              exitCode: 1,
              processIdentifier: nil,
              startedAt: Date(),
              finishedAt: Date()
            )
            if shellOptions.shellOutputFormat == .json {
              printShellExecutionJSON(failureSummary)
            }
            prompt = renderShellFollowupPrompt(
              summary: failureSummary,
              includeMetadata: shellOptions.shellMetadata,
              error: error
            )
          }
        case .chat:
          break
        }
        // Inline directives inside chat ('$' primary). '#' is reserved. Slash ('/') is prompts.
        if !wasShellExecution && (trimmed.hasPrefix("$") || trimmed.hasPrefix("#")) {
          let lower = trimmed.lowercased()
          if trimmed.hasPrefix("#") {
            // Reserve '#' for future features.
            terminal.info(
              "(note) '#' is reserved; use '$' for skills (e.g., $sync)."
            )
            continue
          } else if lower == "$reload" || lower == "$sync" {
            // Reload profile & directives mid-conversation
            do {
              let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
              if let lines = HeaderPresenter.render(slug: headerOptions.slug, under: cwd) {
                let themeOverride: Bool? = Self.cliOverridesThemeFlag() ? useTerminalogyTheme : nil
                let out = HeaderPresenter.present(
                  under: cwd, lines: lines, useTerminalogyTheme: themeOverride)
                if out.count >= 2 {
                  terminal.info(out[0])
                  terminal.info(out[1])
                }
                if out.count >= 3 {
                  if ProcessInfo.inXcodeEnvironment {
                    terminal.error(out[2])
                  } else {
                    terminal.print(out[2])
                  }
                }
              }
              let env = try DirectivesProfiler.render(
                slug: "codex", root: cwd, format: "text", rootChain: true)
              terminal.info("-- environment directives --")
              terminal.print(env)
              continue
            } catch {
              terminal.error("reload failed: \(error)")
              continue
            }
          } else if lower == "$wu" || lower.hasPrefix("$wu ") {
            // Wind up ritual (defaults; parse simple did/news from remainder later if needed)
            var windUp = Wind.Up()
            do { try await windUp.run() } catch { terminal.error("$wu failed: \(error)") }
            continue
          } else if lower == "$wc" || lower.hasPrefix("$wc ") {
            // Wind check-in; optional note = remainder after $wc
            var checkIn = Wind.CheckIn()
            let parts = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
            if !parts.isEmpty { checkIn.note = [String(parts)] }
            do { try await checkIn.run() } catch { terminal.error("$wc failed: \(error)") }
            continue
          } else if lower == "$wd" || lower.hasPrefix("$wd ") {
            // Wind down requires a message
            var windDown = Wind.Down()
            let parts = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
            if parts.isEmpty {
              terminal.error("$wd requires a message. Example: $wd Ship safely; debug with intent.")
            } else {
              windDown.message = [String(parts)]
              do { try await windDown.run() } catch { terminal.error("$wd failed: \(error)") }
            }
            continue
          } else if trimmed.hasPrefix("^") {  // caret mention (deprecated); accept but prefer '>'
            let token = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
            if let slug = resolveSymbolMention(token: token) {
              let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
              if let lines = ConversationHeader.render(slug: slug, under: cwd) {
                let themed: String = {
                  guard useTerminalogyTheme, !ProcessInfo.inXcodeEnvironment,
                    let ws = try? WorkspaceConfig.load(under: cwd),
                    let model = TerminalogyService.loadEffective(under: cwd, from: ws.terminalogy),
                    let hex = model.theme?.primary,
                    let colored = Self.colorize(hex: hex, text: lines.line1)
                  else { return lines.line1 }
                  return colored
                }()
                terminal.info(themed)
                terminal.info(lines.line2)
                if let l3 = lines.line3 {
                  if ProcessInfo.inXcodeEnvironment {
                    terminal.error(l3)
                  } else {
                    terminal.print(Self.colorizeSeverityLine(l3))
                  }
                }
              }
              terminal.info("(note) '^' is deprecated; use '>' e.g., >\(slug)")
            } else {
              terminal.error("unknown mention: \(token)")
            }
            continue
          } else if lower.hasPrefix("$patch") {
            // Simple recovery/incident shortcuts
            let parts = trimmed.split(separator: " ", omittingEmptySubsequences: true).map {
              String($0)
            }
            let sub = parts.count > 1 ? parts[1].lowercased() : ""
            do {
              switch sub {
              case "freeze":
                var r = RecoveryCommand()
                r.freeze = true
                try r.run()
              case "unfreeze":
                var r = RecoveryCommand()
                r.unfreeze = true
                try r.run()
              case "status":
                try IncidentsCommand.Status().run()
              case "clear":
                terminal.error("Use patch-agent-cli incidents clear (restricted)")
              case "plan":
                var r = RecoveryCommand()
                // $patch plan [agency|agent|agenda] [all|<slug>]
                if parts.count > 2 {
                  let k = parts[2].lowercased()
                  if k == "agency" {
                    r.kind = .agency
                  } else if k == "agent" {
                    r.kind = .agent
                  } else if k == "agenda" {
                    r.kind = .agenda
                  }
                }
                if parts.count > 3 {
                  let scope = parts[3].lowercased()
                  if scope == "all" { r.all = true } else { r.slug = scope }
                } else {
                  r.all = true  // default to all
                }
                try r.run()
              case "restore":
                // $patch restore <slug> [agency|agent|agenda]
                guard parts.count > 2 else {
                  terminal.error("usage: $patch restore <slug> [agency|agent|agenda]")
                  break
                }
                var r = RecoveryCommand()
                r.slug = parts[2]
                r.restore = true
                r.verify = true
                if parts.count > 3 {
                  let k = parts[3].lowercased()
                  if k == "agency" {
                    r.kind = .agency
                  } else if k == "agent" {
                    r.kind = .agent
                  } else if k == "agenda" {
                    r.kind = .agenda
                  }
                }
                try r.run()
              default:
                terminal.error(
                  "unknown $patch subcommand. Try: freeze | plan | restore <slug> | status | clear | unfreeze"
                )
              }
            } catch {
              terminal.error("$patch failed: \(error)")
            }
            continue
          }
        } else if trimmed.hasPrefix("/") {
          // Saved prompts are handled by the host (not handled here)
          terminal.info("Saved prompts are handled by the host; use '$' for skills (e.g., $sync).")
          continue
        }
        // Print the response header (required) before generating the answer
        do {
          let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
          if let lines = HeaderPresenter.render(slug: headerOptions.slug, under: cwd) {
            let themeOverride: Bool? = Self.cliOverridesThemeFlag() ? useTerminalogyTheme : nil
            let out = HeaderPresenter.present(
              under: cwd, lines: lines, useTerminalogyTheme: themeOverride)
            if out.count >= 2 {
              terminal.info(out[0])
              terminal.info(out[1])
            }
            if out.count >= 3 {
              if ProcessInfo.inXcodeEnvironment {
                terminal.error(out[2])
              } else {
                terminal.print(out[2])
              }
            }
          }
        }
        let lookupNote: String = {
          switch _emojiPosture ?? "standard" {
          case "minimal": return "Looking this up..."
          case "lively": return "Looking this up... 🔍"
          default: return "Looking this up... 🔎"
          }
        }()
        if ProcessInfo.inXcodeEnvironment {
          terminal.info(lookupNote)
        } else {
          terminal.print(lookupNote)
        }
        let activityIndicator: InlineActivityIndicator =
          .init(console: terminal, style: { .random }, delay: 0.2)
        activityIndicator.start()
        do {
          if stream {
            #if canImport(Darwin)
            let messages: [ProviderMessage] = [.user(prompt)]
            let startTime = Date()
            let effectiveSystem = buildEffectiveSystem(
              prompt: prompt,
              explicitSystem: system,
              agentSystemInstructions: agentSystemInstructions ?? nil,
              designSystems: designSystems
            )
            let sequence = providerInstance.stream(
              messages: messages, model: resolvedModel, system: effectiveSystem)
            activityIndicator.succeed()
            var aggregated = ""
            // Ctrl-C (SIGINT) cancellation support (no detached task to avoid Sendable warnings)
            let cancelSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
            var cancelled = false
            signal(SIGINT, SIG_IGN)
            cancelSource.setEventHandler { cancelled = true }
            cancelSource.resume()
            var lineBuffer = ""
            var printedLines = 0
            do {
              for try await delta in sequence {
                if cancelled { break }
                let newPart = delta.text
                aggregated += newPart
                if streamCoalesceLines {
                  lineBuffer += newPart
                  if lineBuffer.contains("\n") {
                    let parts = lineBuffer.split(separator: "\n", omittingEmptySubsequences: false)
                    if parts.count > 1 {
                      for p in parts.dropLast() {
                        print(String(p))
                        printedLines &+= 1
                      }
                      fflush(stdout)
                      lineBuffer = String(parts.last ?? "")
                    }
                  }
                } else {
                  print(newPart, terminator: "")
                  fflush(stdout)
                }
              }
              // Flush any remaining partial line at the end
              if !cancelled, streamCoalesceLines, !lineBuffer.isEmpty {
                print(lineBuffer)
                printedLines &+= 1
                fflush(stdout)
                lineBuffer.removeAll(keepingCapacity: false)
              }
            } catch {
              // Propagate provider errors to outer catch
              throw error
            }
            cancelSource.cancel()
            if !cancelled {
              let elapsed = Date().timeIntervalSince(startTime)
              if streamFinalSummary {
                if !streamSummaryBelow {
                  fflush(stdout)
                  let lineCount: Int = printedLines
                  if lineCount > 0 {
                    for i in 0..<lineCount {
                      fputs("\u{001B}[2K\r", stdout)
                      if i < lineCount - 1 { fputs("\u{001B}[1A", stdout) }
                    }
                    fflush(stdout)
                  }
                } else {
                  if streamCoalesceLines, !aggregated.hasSuffix("\n") { print("") }
                }
                // Resolve preset-adjusted formatting settings
                let eff = resolveFinalSettings()
                Self.printFinalBlock(
                  on: &terminal,
                  body: aggregated,
                  format: eff.format,
                  title: eff.title,
                  color: eff.color,
                  wrap: eff.wrap,
                  padTop: eff.padTop,
                  padBottom: eff.padBottom,
                  divider: eff.divider,
                  border: eff.border,
                  header: eff.header,
                  footer: eff.footer,
                  prefix: eff.prefix,
                  provider: activeProvider.displayName,
                  model: resolvedModel,
                  elapsedSeconds: elapsed,
                  ensureTrailingNewline: eff.newline,
                )
              } else {
                if streamCoalesceLines, !aggregated.hasSuffix("\n") { print("") }
              }
            }
            #else
            let startTime = Date()
            let effectiveSystem = buildEffectiveSystem(
              prompt: prompt,
              explicitSystem: system,
              agentSystemInstructions: agentSystemInstructions ?? nil,
              designSystems: designSystems
            )
            let msg = try await providerInstance.generate(
              messages: [.user(prompt)], model: resolvedModel, system: effectiveSystem,
            )
            activityIndicator.succeed()
            let elapsed = Date().timeIntervalSince(startTime)
            let eff = resolveFinalSettings()
            Self.printFinalBlock(
              on: &terminal,
              body: msg.text,
              format: eff.format,
              title: eff.title,
              color: eff.color,
              wrap: eff.wrap,
              padTop: eff.padTop,
              padBottom: eff.padBottom,
              divider: eff.divider,
              border: eff.border,
              header: eff.header,
              footer: eff.footer,
              prefix: eff.prefix,
              provider: activeProvider.displayName,
              model: resolvedModel,
              elapsedSeconds: elapsed,
              ensureTrailingNewline: eff.newline,
            )
            #endif
          } else {
            let startTime = Date()
            let effectiveSystem = buildEffectiveSystem(
              prompt: prompt,
              explicitSystem: system,
              agentSystemInstructions: agentSystemInstructions ?? nil,
              designSystems: designSystems
            )
            let msg = try await providerInstance.generate(
              messages: [.user(prompt)], model: resolvedModel, system: effectiveSystem,
            )
            activityIndicator.succeed()
            let elapsed = Date().timeIntervalSince(startTime)
            let eff2 = resolveFinalSettings()
            Self.printFinalBlock(
              on: &terminal,
              body: msg.text,
              format: eff2.format,
              title: eff2.title,
              color: eff2.color,
              wrap: eff2.wrap,
              padTop: eff2.padTop,
              padBottom: eff2.padBottom,
              divider: eff2.divider,
              border: eff2.border,
              header: eff2.header,
              footer: eff2.footer,
              prefix: eff2.prefix,
              provider: activeProvider.displayName,
              model: resolvedModel,
              elapsedSeconds: elapsed,
              ensureTrailingNewline: eff2.newline,
            )
          }
        } catch {
          activityIndicator.succeed()
          // Enriched error logging for better diagnostics
          let typeName = String(describing: type(of: error))
          var details: [String] = []
          if let le = error as? LocalizedError, let desc = le.errorDescription, !desc.isEmpty {
            details.append(desc)
          }
          let ns = error as NSError
          details.append("code=\(ns.code)")
          details.append("domain=\(ns.domain)")
          if !ns.userInfo.isEmpty {
            // Print compact userInfo to aid debugging without overwhelming output
            let ui = ns.userInfo.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            details.append("userInfo={\(ui)}")
          }
          // Mirror common fields (statusCode/message/body) if present on error types
          let mirror = Mirror(reflecting: error)
          var mirrored: [String] = []
          for child in mirror.children {
            guard let label = child.label else { continue }
            switch label {
            case "status", "statusCode", "httpStatus", "message", "error", "reason":
              mirrored.append("\(label)=\(child.value)")
            default: continue
            }
          }
          if !mirrored.isEmpty { details.append("details=[\(mirrored.joined(separator: ", "))]") }
          terminal.error("Error (\(typeName)): \(details.joined(separator: "; "))")
          chatting = false
        }
      }

    }

    // Workspace preferences (e.g., emoji posture)
    private var _emojiPosture: String? = nil

    private static func colorize(hex: String, text: String) -> String? {
      func hexToRGB(_ s: String) -> (Int, Int, Int)? {
        let cs = s.trimmingCharacters(in: .whitespacesAndNewlines)
        let clean = cs.hasPrefix("#") ? String(cs.dropFirst()) : cs
        guard clean.count == 6, let v = Int(clean, radix: 16) else { return nil }
        return ((v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF)
      }
      guard let (r, g, b) = hexToRGB(hex) else { return nil }
      return "\u{001B}[38;2;\(r);\(g);\(b)m" + text + "\u{001B}[0m"
    }

    private static func cliOverridesThemeFlag() -> Bool {
      let args = CommandLine.arguments
      return args.contains("--use-terminalogy-theme") || args.contains("--no-use-terminalogy-theme")
    }

    private static func colorizeSeverityLine(_ text: String) -> String {
      // ANSI colors: red 31, yellow 33, magenta 35, cyan 36; reset 0
      // Detect S-level in the incident line (e.g., [INCIDENT — S1 — ...])
      let upper = text.uppercased()
      let code: String
      if upper.contains(" S1 ") {
        code = "\u{001B}[31m"  // red
      } else if upper.contains(" S2 ") {
        code = "\u{001B}[33m"  // yellow
      } else if upper.contains(" S3 ") {
        code = "\u{001B}[36m"  // cyan
      } else {
        code = "\u{001B}[35m"  // magenta default
      }
      let reset = "\u{001B}[0m"
      return code + text + reset
    }

    // Resolve >/< mentions to a slug by scanning .clia/agents
    private func resolveSymbolMention(token: String) -> String? {
      let fm = FileManager.default
      let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
      guard let root = findRepoRoot(startingAt: cwd) else { return nil }
      let agentsRoot = root.appendingPathComponent(".clia/agents")
      var norm = token.trimmingCharacters(in: .whitespacesAndNewlines)
      if norm.hasPrefix("[") && norm.hasSuffix("]") { norm = String(norm.dropFirst().dropLast()) }
      let lower = norm.lowercased()
      guard fm.fileExists(atPath: agentsRoot.path),
        let dirs = try? fm.contentsOfDirectory(
          at: agentsRoot, includingPropertiesForKeys: [.isDirectoryKey])
      else { return nil }
      for dir in dirs {
        var isDir: ObjCBool = false
        if !fm.fileExists(atPath: dir.path, isDirectory: &isDir) || !isDir.boolValue { continue }
        if let file = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
          .first(where: { $0.lastPathComponent.contains(".agent.") && $0.pathExtension == "json" }),
          let data = fm.contents(atPath: file.path),
          let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        {
          let s = (raw["slug"] as? String) ?? dir.lastPathComponent
          if s.lowercased() == lower { return s }
        }
      }
      return nil
    }

    private func runOneShot(
      prompt: String,
      providerOption: ProviderOption,
      providerInstance: any AIProvider,
      modelIdentifier: String,
      system: String?
    ) async throws {
      let sanitizedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !sanitizedPrompt.isEmpty else {
        throw ValidationError("Prompt is empty after trimming whitespace. Provide content to send.")
      }

      let startTime = Date()
      let completion = try await providerInstance.generateCompletion(
        messages: [.user(sanitizedPrompt)],
        model: modelIdentifier,
        system: system
      )
      let elapsed = Date().timeIntervalSince(startTime)

      switch resolvedOneShotOutputFormat() {
      case .json:
        try emitOneShotJSON(
          prompt: sanitizedPrompt,
          providerOption: providerOption,
          modelIdentifier: modelIdentifier,
          providerCompletion: completion,
          startedAt: startTime,
          duration: elapsed,
          system: system
        )

      case .text:
        var terminal = Terminal()
        let eff = resolveFinalSettings()
        Self.printFinalBlock(
          on: &terminal,
          body: completion.message.text,
          format: eff.format,
          title: eff.title,
          color: eff.color,
          wrap: eff.wrap,
          padTop: eff.padTop,
          padBottom: eff.padBottom,
          divider: eff.divider,
          border: eff.border,
          header: eff.header,
          footer: eff.footer,
          prefix: eff.prefix,
          provider: providerOption.displayName,
          model: modelIdentifier,
          elapsedSeconds: elapsed,
          ensureTrailingNewline: eff.newline
        )

      case .auto:
        // Handled in resolvedOneShotOutputFormat; keep for exhaustive switch.
        break
      }
    }

    private func resolvedOneShotOutputFormat() -> OneShotOutputFormat {
      switch oneShotOutput {
      case .auto: return .json
      case .json: return .json
      case .text: return .text
      }
    }

    private func emitOneShotJSON(
      prompt: String,
      providerOption: ProviderOption,
      modelIdentifier: String,
      providerCompletion: ProviderCompletion,
      startedAt: Date,
      duration: TimeInterval,
      system: String?
    ) throws {
      let formatter = ISO8601DateFormatter()
      formatter.formatOptions = [.withInternetDateTime]
      let metadata = OpenAIStyleChatCompletion.CLiaMetadata(
        prompt: prompt,
        system_instruction: system,
        provider_identifier: providerOption.rawValue,
        provider_display_name: providerOption.displayName,
        model: modelIdentifier,
        started_at: formatter.string(from: startedAt),
        duration_seconds: duration,
        additional: nil
      )

      let payload: OpenAIStyleChatCompletion
      if let cai = providerCompletion.completion {
        payload = OpenAIStyleChatCompletion(from: cai, fallbackMetadata: metadata)
      } else {
        let message = OpenAIStyleChatCompletion.Choice.Message(
          role: "assistant",
          content: providerCompletion.message.text
        )
        let choice = OpenAIStyleChatCompletion.Choice(
          index: 0, message: message, finish_reason: "stop")
        payload = OpenAIStyleChatCompletion(
          id: "clia-" + UUID().uuidString.lowercased(),
          object: "chat.completion",
          created: Int(startedAt.timeIntervalSince1970),
          model: modelIdentifier,
          choices: [choice],
          usage: nil,
          clia_metadata: metadata
        )
      }

      let encoder = JSON.Formatting.humanEncoder
      let data = try encoder.encode(payload)
      guard var text = String(data: data, encoding: .utf8) else { return }
      if !text.hasSuffix("\n") { text.append("\n") }
      print(text, terminator: "")
    }

    private func readPromptFromStandardInputIfAvailable() throws -> String? {
      guard !isStandardInputTTY() else { return nil }
      let data = try FileHandle.standardInput.readToEnd()
      guard let data, !data.isEmpty else { return nil }
      guard let raw = String(data: data, encoding: .utf8) else { return nil }
      let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
      return trimmed.isEmpty ? nil : trimmed
    }

    private struct ShellExecutionSummary: Sendable {
      let input: String
      let spec: CommandSpec
      let stdout: String
      let stderr: String
      let exitCode: Int32
      let processIdentifier: String?
      let startedAt: Date
      let finishedAt: Date

      var durationMs: Double {
        finishedAt.timeIntervalSince(startedAt) * 1000.0
      }
    }

    private final class ShellOutputCapture: @unchecked Sendable {
      private let queue = DispatchQueue(label: "clia.shell-output-capture")
      private var stdout = ""
      private var stderr = ""
      private var exitCode: Int32 = 0
      private var processIdentifier: String?

      func appendStdout(_ text: String) {
        queue.sync { stdout.append(text) }
      }

      func appendStderr(_ text: String) {
        queue.sync { stderr.append(text) }
      }

      func setExitCode(_ code: Int32) {
        queue.sync { exitCode = code }
      }

      func setProcessIdentifier(_ identifier: String?) {
        queue.sync { processIdentifier = identifier }
      }

      func snapshot() -> (
        stdout: String,
        stderr: String,
        exitCode: Int32,
        processIdentifier: String?
      ) {
        queue.sync {
          (
            stdout: stdout,
            stderr: stderr,
            exitCode: exitCode,
            processIdentifier: processIdentifier
          )
        }
      }
    }

    private func formatShellDate(_ date: Date) -> String {
      let formatter = ISO8601DateFormatter()
      formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      return formatter.string(from: date)
    }

    private func printShellExecutionJSON(_ summary: ShellExecutionSummary) {
      struct Payload: Encodable {
        let input: String
        let command: String
        let args: [String]
        let exitCode: Int32
        let processIdentifier: String?
        let stdout: String
        let stderr: String
        let startedAt: String
        let finishedAt: String
        let durationMs: Double
        let requestId: String
        let hostKind: String?
        let runnerKind: String?
        let workingDirectory: String?
        let timeoutSeconds: Double?
      }

      let payload = Payload(
        input: summary.input,
        command: renderCommandLine(spec: summary.spec, fallback: summary.input),
        args: summary.spec.args,
        exitCode: summary.exitCode,
        processIdentifier: summary.processIdentifier,
        stdout: summary.stdout,
        stderr: summary.stderr,
        startedAt: formatShellDate(summary.startedAt),
        finishedAt: formatShellDate(summary.finishedAt),
        durationMs: summary.durationMs,
        requestId: summary.spec.requestId,
        hostKind: summary.spec.hostKind.map { String(describing: $0) },
        runnerKind: summary.spec.runnerKind.map { String(describing: $0) },
        workingDirectory: summary.spec.workingDirectory,
        timeoutSeconds: summary.spec.timeout.map { Double($0.components.seconds) }
      )

      do {
        let encoder = JSON.Formatting.humanEncoder
        let data = try encoder.encode(payload)
        if let text = String(data: data, encoding: .utf8) {
          print(text)
        }
      } catch {
        print("shell-json-error: \(error.localizedDescription)")
      }
    }

    private func renderShellFollowupPrompt(
      summary: ShellExecutionSummary,
      includeMetadata: Bool,
      error: Error?
    ) -> String {
      let commandLine = "$ " + renderCommandLine(spec: summary.spec, fallback: summary.input)
      var sections: [String] = []
      sections.append("Shell command output:")
      sections.append(commandLine)
      sections.append("exit: \(summary.exitCode)")
      let trimmedStdout = summary.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
      if !trimmedStdout.isEmpty {
        sections.append("stdout:\n\(trimmedStdout)")
      }
      let trimmedStderr = summary.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
      if !trimmedStderr.isEmpty {
        sections.append("stderr:\n\(trimmedStderr)")
      }
      if includeMetadata {
        let startedAt = formatShellDate(summary.startedAt)
        let finishedAt = formatShellDate(summary.finishedAt)
        let pid = summary.processIdentifier ?? "-"
        let duration = String(format: "%.1f", summary.durationMs)
        sections.append(
          "metadata: requestId=\(summary.spec.requestId) pid=\(pid) durationMs=\(duration)"
        )
        sections.append("metadata: startedAt=\(startedAt) finishedAt=\(finishedAt)")
        if let hostKind = summary.spec.hostKind {
          sections.append("metadata: hostKind=\(hostKind)")
        }
        if let runnerKind = summary.spec.runnerKind {
          sections.append("metadata: runnerKind=\(runnerKind)")
        }
        if let workingDirectory = summary.spec.workingDirectory {
          sections.append("metadata: workingDirectory=\(workingDirectory)")
        }
        if let timeout = summary.spec.timeout {
          sections.append("metadata: timeoutSeconds=\(timeout.components.seconds)")
        }
      }
      if let error {
        sections.append("error: \(error.localizedDescription)")
      }
      return sections.joined(separator: "\n")
    }

    private func renderCommandLine(spec: CommandSpec, fallback: String) -> String {
      var parts: [String] = []
      switch spec.executable.ref {
      case .name(let name):
        parts.append(name)
      case .path(let path):
        parts.append(path)
      case .none:
        break
      }
      parts.append(contentsOf: spec.executable.options)
      parts.append(contentsOf: spec.executable.arguments)
      parts.append(contentsOf: spec.args)
      if parts.isEmpty {
        return fallback.trimmingCharacters(in: .whitespacesAndNewlines)
      }
      return parts.joined(separator: " ")
    }

    private func isStandardInputTTY() -> Bool {
      isatty(STDIN_FILENO) != 0
    }

    private struct OpenAIStyleChatCompletion: Encodable {
      struct Choice: Encodable {
        struct Message: Encodable {
          let role: String
          let content: String
        }

        let index: Int
        let message: Message
        let finish_reason: String?
      }

      struct Usage: Encodable {
        let prompt_tokens: Int?
        let completion_tokens: Int?
        let total_tokens: Int?
      }

      struct CLiaMetadata: Encodable {
        let prompt: String
        let system_instruction: String?
        let provider_identifier: String
        let provider_display_name: String
        let model: String
        let started_at: String
        let duration_seconds: Double
        let additional: [String: String]?

        func withAdditional(_ extra: [String: String]?) -> CLiaMetadata {
          CLiaMetadata(
            prompt: prompt,
            system_instruction: system_instruction,
            provider_identifier: provider_identifier,
            provider_display_name: provider_display_name,
            model: model,
            started_at: started_at,
            duration_seconds: duration_seconds,
            additional: extra
          )
        }
      }

      let id: String
      let object: String
      let created: Int
      let model: String
      let choices: [Choice]
      let usage: Usage?
      let clia_metadata: CLiaMetadata?

      init(
        id: String,
        object: String,
        created: Int,
        model: String,
        choices: [Choice],
        usage: Usage?,
        clia_metadata: CLiaMetadata?
      ) {
        self.id = id
        self.object = object
        self.created = created
        self.model = model
        self.choices = choices
        self.usage = usage
        self.clia_metadata = clia_metadata
      }

      init(from completion: CAICompletion, fallbackMetadata: CLiaMetadata) {
        let mappedChoices: [Choice] = completion.choices.map { choice in
          let role: String
          switch choice.message.role {
          case .model: role = "assistant"
          case .user: role = "user"
          case .system: role = "system"
          }
          return Choice(
            index: choice.index,
            message: .init(role: role, content: choice.message.text),
            finish_reason: choice.finishReason
          )
        }
        let usage = completion.usage.map { usage in
          Usage(
            prompt_tokens: usage.promptTokens,
            completion_tokens: usage.completionTokens,
            total_tokens: usage.totalTokens
          )
        }
        self.init(
          id: completion.id,
          object: completion.object,
          created: completion.created,
          model: completion.model,
          choices: mappedChoices,
          usage: usage,
          clia_metadata: fallbackMetadata.withAdditional(completion.metadata)
        )
      }
    }

  }
}

// MARK: - Final block rendering helpers

extension Clia.Ask {
  // Compute effective final rendering settings after applying --final-style presets.
  fileprivate func resolveFinalSettings() -> (
    format: FinalFormat,
    title: String?,
    color: FinalColorTheme,
    wrap: String,
    padTop: Int,
    padBottom: Int,
    divider: FinalDivider,
    border: FinalBorder,
    header: [HeaderDetail],
    footer: [FooterDetail],
    prefix: String,
    newline: Bool
  ) {
    var fmt = finalFormat
    var titleOpt: String? = noFinalTitle ? nil : finalTitle
    var colorOpt: FinalColorTheme = .none
    var wrapOpt = "auto"
    let padTopOpt = 0
    let padBottomOpt = 0
    var dividerOpt: FinalDivider = .none
    var borderOpt: FinalBorder = .none
    var headerOpt: [HeaderDetail] = []
    let footerOpt: [FooterDetail] = []
    let prefixOpt = finalPrefix
    let newlineOpt = finalNewline

    if let style = finalStyle {
      switch style {
      case .minimal:
        fmt = .plain
        titleOpt = nil
        colorOpt = .none
        wrapOpt = "auto"
        dividerOpt = .none
        borderOpt = .none

      case .framed:
        fmt = .markdown
        // Keep provided title unless explicitly disabled.
        if noFinalTitle { titleOpt = nil } else { titleOpt = finalTitle }
        colorOpt = .accent
        borderOpt = .single

      case .compact:
        fmt = .markdown
        titleOpt = nil
        dividerOpt = .thin
        wrapOpt = "auto"
      }
      // If user didn't specify any headers, provide sensible defaults for presets
      if headerOpt.isEmpty {
        headerOpt = [.provider, .elapsed]
      }
    }

    return (
      fmt, titleOpt, colorOpt, wrapOpt, padTopOpt, padBottomOpt, dividerOpt, borderOpt,
      headerOpt, footerOpt, prefixOpt, newlineOpt,
    )
  }

  private static func wrapLines(_ text: String, width: Int) -> String {
    guard width > 10 else { return text }
    var out: [String] = []
    for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
      var current = String(line)
      while current.count > width {
        let idx = current.index(current.startIndex, offsetBy: width)
        out.append(String(current[current.startIndex..<idx]))
        current = String(current[idx...])
      }
      out.append(current)
    }
    return out.joined(separator: "\n")
  }

  private static func colorize(_ text: String, theme: FinalColorTheme) -> String {
    let start: String
    switch theme {
    case .none: return text
    case .info: start = "\u{001B}[36m"
    case .success: start = "\u{001B}[32m"
    case .warning: start = "\u{001B}[33m"
    case .accent: start = "\u{001B}[35m"
    }
    return start + text + "\u{001B}[0m"
  }

  static func printFinalBlock(
    on terminal: inout Terminal,
    body: String,
    format: FinalFormat,
    title: String?,
    color: FinalColorTheme,
    wrap: String,
    padTop: Int,
    padBottom: Int,
    divider: FinalDivider,
    border: FinalBorder,
    header: [HeaderDetail],
    footer: [FooterDetail],
    prefix: String,
    provider: String,
    model: String,
    elapsedSeconds: TimeInterval,
    ensureTrailingNewline: Bool,
  ) {
    let rewrittenBody = TerminalLinkRewriter.rewriteClickableFileReferences(body)
    let formatted: String = {
      switch format {
      case .markdown:
        let document: Document = .init(parsing: rewrittenBody)
        return document.format()

      case .plain:
        return rewrittenBody
      }
    }()

    // Compose header meta
    var headerBits: [String] = []
    for h in header where h != .none {
      switch h {
      case .provider: headerBits.append(provider)
      case .model: headerBits.append(model)
      case .elapsed: headerBits.append(String(format: "%.1fs", elapsedSeconds))
      case .none: break
      }
    }
    let headerLine: String? = headerBits.isEmpty ? nil : headerBits.joined(separator: " • ")

    // Determine wrap width
    let width: Int? = {
      if wrap == "auto" { return Int(ProcessInfo.processInfo.environment["COLUMNS"] ?? "0") ?? 0 }
      if let n = Int(wrap), n > 0 { return n }
      return nil
    }()
    var content = formatted
    if let w = width, w > 0 { content = wrapLines(content, width: w) }

    // Build lines with optional parts
    var lines: [String] = []
    if padTop > 0 { lines.append(contentsOf: Array(repeating: "", count: padTop)) }
    if let t = title, !t.isEmpty { lines.append(t) }
    if let headerLine { lines.append(headerLine) }
    switch divider {
    case .none: break

    case .thin:
      lines.append(String(repeating: "-", count: max(3, min(80, width ?? 80))))

    case .thick:
      lines.append(String(repeating: "=", count: max(3, min(80, width ?? 80))))
    }
    if !prefix.isEmpty { lines.append(prefix) }
    lines.append(
      contentsOf: content.split(separator: "\n", omittingEmptySubsequences: false).map(String.init))

    // Footer
    var footerBits: [String] = []
    for f in footer where f != .none {
      switch f {
      case .timestamp:
        let df = ISO8601DateFormatter()
        footerBits.append(df.string(from: Date()))

      default:
        continue
      }
    }
    if !footerBits.isEmpty {
      lines.append(footerBits.joined(separator: " • "))
    }
    if padBottom > 0 { lines.append(contentsOf: Array(repeating: "", count: padBottom)) }

    // Apply border if requested
    let finalBlock: String = {
      switch border {
      case .none:
        return lines.joined(separator: "\n")

      case .single, .double:
        let w = max(lines.map(\.count).max() ?? 0, 1)
        let (h, v): (String, String) = border == .single ? ("-", "|") : ("=", "||")
        let top = "+" + String(repeating: h, count: w + 2) + "+"
        let boxed = lines.map { line in
          let pad = String(repeating: " ", count: w - line.count)
          return "\(v) \(line)\(pad) \(v)"
        }
        let bottom = top
        return ([top] + boxed + [bottom]).joined(separator: "\n")
      }
    }()

    let colored = colorize(finalBlock, theme: color)
    if ensureTrailingNewline {
      terminal.output(ConsoleText(stringLiteral: colored + (colored.hasSuffix("\n") ? "" : "\n")))
    } else {
      terminal.output(ConsoleText(stringLiteral: colored))
    }
  }
}
