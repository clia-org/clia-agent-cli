// swift-tools-version:6.2
import PackageDescription
import Foundation

let useLocalDeps: Bool = {
  guard let raw = ProcessInfo.processInfo.environment["SPM_USE_LOCAL_DEPS"] else { return true }
  let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
  return !(normalized == "0" || normalized == "false" || normalized == "no")
}()

func localOrRemote(
  name: String, path: String, remote: () -> Package.Dependency
) -> Package.Dependency {
  if useLocalDeps { return .package(name: name, path: path) }
  return remote()
}

let package = Package(
  name: "clia-agent",
  platforms: [
    .macOS(.v15)
  ],
  products: [
    .executable(name: "clia", targets: ["CLIAAgentTool"]),
    .library(name: "CLIAAgentAudit", targets: ["CLIAAgentAudit"]),
    .library(name: "CLIAAgentCore", targets: ["CLIAAgentCore"]),
    .library(name: "CLIAAgentCoreCLICommands", targets: ["CLIAAgentCoreCLICommands"]),
    .library(name: "CLIAIncidentCoreCommands", targets: ["CLIAIncidentCoreCommands"]),
    .library(name: "CLIAIncidentResolutionCommands", targets: ["CLIAIncidentResolutionCommands"]),
    .library(name: "CLIACore", targets: ["CLIACore"]),
    .library(name: "CLIACoreModels", targets: ["CLIACoreModels"]),
  ],
  dependencies: [
    // Local or remote (set SPM_USE_LOCAL_DEPS=1 for local)
    localOrRemote(
      name: "common-process",
      path: "../../../../../../swift-universal/public/spm/universal/domain/system/common-process",
      remote: { .package(url: "https://github.com/swift-universal/common-process.git", from: "0.3.0") }),
    localOrRemote(
      name: "common-shell",
      path: "../../../../../../swift-universal/public/spm/universal/domain/system/common-shell",
      remote: { .package(url: "https://github.com/swift-universal/common-shell.git", from: "0.0.1") }),
    localOrRemote(
      name: "common-cli",
      path: "../../../../../../swift-universal/public/spm/universal/domain/system/common-cli",
      remote: { .package(url: "https://github.com/swift-universal/common-cli.git", from: "0.1.0") }),
    localOrRemote(
      name: "common-log",
      path: "../../../../../../swift-universal/public/spm/universal/domain/system/common-log",
      remote: { .package(url: "https://github.com/swift-universal/common-log", branch: "main") }),
    localOrRemote(
      name: "wrkstrm-foundation",
      path: "../../../../../../wrkstrm/public/spm/universal/domain/system/wrkstrm-foundation",
      remote: { .package(url: "https://github.com/wrkstrm/wrkstrm-foundation.git", from: "3.0.0") }),
    localOrRemote(
      name: "wrkstrm-main",
      path: "../../../../../../wrkstrm/public/spm/universal/domain/system/wrkstrm-main",
      remote: { .package(url: "https://github.com/wrkstrm/wrkstrm-main", branch: "main") }),
    localOrRemote(
      name: "wrkstrm-performance",
      path: "../../../../../../wrkstrm/public/spm/universal/domain/system/wrkstrm-performance",
      remote: { .package(url: "https://github.com/wrkstrm/wrkstrm-performance", branch: "main") }),
    localOrRemote(
      name: "swift-figlet-kit",
      path: "../../../../../../wrkstrm/public/spm/universal/domain/tooling/swift-figlet-kit",
      remote: { .package(url: "https://github.com/wrkstrm/swift-figlet-kit.git", branch: "main") }),
    // Local or remote (published)
    localOrRemote(
      name: "swift-directory-tools",
      path: "../../../../../../swift-universal/public/spm/universal/domain/system/swift-directory-tools",
      remote: { .package(url: "https://github.com/swift-universal/swift-directory-tools.git", from: "0.1.0") }
    ),
    localOrRemote(
      name: "swift-json-formatter",
      path: "../../../../../../swift-universal/public/spm/universal/domain/tooling/swift-json-formatter",
      remote: { .package(url: "https://github.com/swift-universal/swift-json-formatter.git", from: "0.1.0") }
    ),
    localOrRemote(
      name: "swift-md-formatter",
      path: "../../../../../../swift-universal/public/spm/universal/domain/tooling/swift-md-formatter",
      remote: { .package(url: "https://github.com/swift-universal/swift-md-formatter.git", from: "0.1.0") }
    ),
    // Remaining local-only deps (no public repo published yet)
    .package(
      name: "swift-terminal-link-rewriter",
      path: "../../../../../../wrkstrm/public/spm/universal/domain/tooling/swift-terminal-link-rewriter"
    ),
    // AI providers (local for now)
    .package(
      name: "CommonAI",
      path: "../../../../../../swift-universal/public/spm/universal/domain/ai/common-ai"
    ),
    // Remotes
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.6.0"),
    .package(url: "https://github.com/stencilproject/Stencil.git", from: "0.15.0"),
    .package(url: "https://github.com/vapor/console-kit.git", from: "4.10.2"),
    .package(url: "https://github.com/apple/swift-metrics.git", from: "2.4.0"),
    .package(url: "https://github.com/apple/swift-markdown.git", from: "0.6.0"),
  ],
  targets: [
    .target(
      name: "CLIACoreModels",
      dependencies: [],
      path: "sources/core/clia-core-models"
    ),
    .target(
      name: "CLIACore",
      dependencies: [
        "CLIACoreModels",
        .product(name: "SwiftTerminalLinkRewriter", package: "swift-terminal-link-rewriter"),
      ],
      path: "sources/core/clia-core"
    ),
    .target(
      name: "CLIAAgentCore",
      dependencies: [
        .product(name: "WrkstrmFoundation", package: "wrkstrm-foundation"),
        .product(name: "SwiftMDFormatter", package: "swift-md-formatter"),
      ],
      path: "sources/core/clia-agent-core"
    ),
    .target(
      name: "CLIAAgentCoreCLICommands",
      dependencies: [
        "CLIAAgentCore",
        "CLIACore",
        "CLIACoreModels",
        "CLIAIncidentCoreCommands",
        "CLIAIncidentResolutionCommands",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "WrkstrmFoundation", package: "wrkstrm-foundation"),
        .product(name: "SwiftDirectoryTools", package: "swift-directory-tools"),
        .product(name: "SwiftFigletKit", package: "swift-figlet-kit"),
        .product(name: "SwiftJSONFormatter", package: "swift-json-formatter"),
      ],
      path: "sources/core/clia-agent-core-cli-commands",
      resources: [.process("resources")]
    ),
    .target(
      name: "CLIAIncidentCoreCommands",
      dependencies: [
        "CLIACoreModels",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "sources/core/clia-incident-core-commands"
    ),
    .target(
      name: "CLIAIncidentResolutionCommands",
      dependencies: [
        "CLIAIncidentCoreCommands",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      path: "sources/incidents/clia-incident-resolution-commands"
    ),
    .target(
      name: "CLIAAgentAudit",
      dependencies: [
        "CLIACoreModels",
        "CLIACore",
        "CLIAAgentCoreCLICommands",
      ],
      path: "sources/core/clia-agent-audit"
    ),
    .executableTarget(
      name: "CLIAAgentTool",
      dependencies: [
        // CommonAI
        .product(name: "CommonAI", package: "CommonAI"),
        .product(name: "CommonAIOpenAI", package: "CommonAI"),
        .product(name: "CommonAIGoogle", package: "CommonAI"),
        .product(name: "CommonAIApple", package: "CommonAI"),
        // Core infra
        .product(name: "CommonCLI", package: "common-cli"),
        .product(name: "CommonProcess", package: "common-process"),
        .product(name: "CommonProcessExecutionKit", package: "common-process"),
        .product(name: "CommonShell", package: "common-shell"),
        .product(name: "CommonShellArguments", package: "common-shell"),
        .product(name: "WrkstrmEnvironment", package: "wrkstrm-performance"),
        .product(name: "WrkstrmFoundation", package: "wrkstrm-foundation"),
        .product(name: "WrkstrmMain", package: "wrkstrm-main"),
        .product(name: "CommonLog", package: "common-log"),
        .product(name: "SwiftFigletKit", package: "swift-figlet-kit"),
        // UI + metrics
        .product(name: "ConsoleKit", package: "console-kit"),
        .product(name: "ConsoleKitTerminal", package: "console-kit"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "Stencil", package: "Stencil"),
        .product(name: "Metrics", package: "swift-metrics"),
        .product(name: "Markdown", package: "swift-markdown"),
        // Local libs (re-exported for downstreams)
        "CLIAAgentCore",
        "CLIAAgentCoreCLICommands",
        "CLIACore",
        "CLIACoreModels",
      ],
      path: "sources/core/clia-agent-tool",
      resources: [
        .process("resources")
      ]
    ),
    .testTarget(
      name: "CLIACoreTests",
      dependencies: ["CLIACore"],
      path: "tests/core/clia-core-tests"
    ),
    .testTarget(
      name: "CLIAAgentCoreCLICommandsTests",
      dependencies: [
        "CLIAAgentCoreCLICommands",
        "CLIACore",
        "CLIACoreModels",
      ],
      path: "tests/core/clia-agent-core-cli-commands-tests"
    ),
    .testTarget(
      name: "CLIAIncidentCoreCommandsTests",
      dependencies: [
        "CLIAIncidentCoreCommands",
        "CLIACoreModels",
      ],
      path: "tests/core/clia-incident-core-commands-tests"
    ),
    .testTarget(
      name: "CLIAIncidentResolutionCommandsTests",
      dependencies: [
        "CLIAIncidentResolutionCommands"
      ],
      path: "tests/incidents/clia-incident-resolution-commands-tests"
    ),
    .testTarget(
      name: "CLIAAgentAuditTests",
      dependencies: [
        "CLIAAgentAudit",
        "CLIACoreModels",
      ],
      path: "tests/core/clia-agent-audit-tests"
    ),
    .testTarget(
      name: "CLIAAgentToolTests",
      dependencies: [
        "CLIAAgentTool"
      ],
      path: "tests/core/clia-agent-tool-tests"
    ),
  ]
)
