import CommonProcess
import CommonProcessExecutionKit
import Foundation

public enum CLIAIntent: Sendable {
  case chat(String)
  case execute(CommandSpec)
}

public struct CLIAIntentRouter: Sendable {
  public init() {}

  public func route(_ raw: String) throws -> CLIAIntent {
    let trimmed = raw.drop { $0.isWhitespace }
    guard trimmed.first == "!" else {
      return .chat(raw)
    }

    let payload = trimmed.dropFirst().drop { $0.isWhitespace }
    let tokens = shellSplit(String(payload))
    guard let exeToken = tokens.first else {
      return .chat(raw)
    }

    let args = Array(tokens.dropFirst())
    let executable: Executable = exeToken.contains("/") ? .path(exeToken) : .name(exeToken)
    let hostKind: ExecutionHostKind =
      exeToken.contains("/")
      ? .direct
      : .env(options: [])

    let spec = CommandSpec(
      executable: executable,
      args: args,
      env: .inherit(updating: nil),
      workingDirectory: nil,
      logOptions: .init(exposure: .summary),
      instrumentationKeys: [.metrics],
      hostKind: hostKind,
      runnerKind: .auto,
      timeout: .seconds(60),
      streamingMode: .passthrough
    )
    try spec.validateOrThrow()

    return .execute(spec)
  }
}

public enum CLIARunEvent: Sendable {
  case stdout(String)
  case stderr(String)
  case completed(exitCode: Int32, processIdentifier: String?)
}

public actor CLIAExecutor {
  private var cancelInFlight: (@Sendable () -> Void)?

  public init() {}

  public func cancel() {
    cancelInFlight?()
    cancelInFlight = nil
  }

  public func run(
    _ spec: CommandSpec,
    emit: @escaping @Sendable (CLIARunEvent) -> Void
  ) async throws {
    let (events, cancel) = RunnerControllerFactory.stream(command: spec)
    cancelInFlight = cancel

    do {
      for try await event in events {
        switch event {
        case .stdout(let data):
          emit(.stdout(String(decoding: data, as: UTF8.self)))
        case .stderr(let data):
          emit(.stderr(String(decoding: data, as: UTF8.self)))
        case .completed(let status, let processIdentifier):
          cancelInFlight = nil
          emit(.completed(exitCode: exitCode(from: status), processIdentifier: processIdentifier))
        }
      }
    } catch {
      cancelInFlight = nil
      throw error
    }
  }

  public func runBuffered(_ spec: CommandSpec) async throws -> ProcessOutput {
    cancelInFlight = nil
    return try await RunnerControllerFactory.run(command: spec)
  }

  public func runInteractive(
    _ spec: CommandSpec,
    emit: @escaping @Sendable (CLIARunEvent) -> Void
  ) async throws {
    let (events, send, closeInput, cancel) = RunnerControllerFactory.interactive(command: spec)
    cancelInFlight = cancel

    #if canImport(Darwin)
    let stdinHandle = FileHandle.standardInput
    stdinHandle.readabilityHandler = { handle in
      let data = handle.availableData
      if data.isEmpty {
        closeInput()
      } else {
        send(data)
      }
    }
    #endif

    defer {
      #if canImport(Darwin)
      stdinHandle.readabilityHandler = nil
      closeInput()
      #endif
    }

    do {
      for try await event in events {
        switch event {
        case .stdout(let data):
          emit(.stdout(String(decoding: data, as: UTF8.self)))
        case .stderr(let data):
          emit(.stderr(String(decoding: data, as: UTF8.self)))
        case .completed(let status, let processIdentifier):
          cancelInFlight = nil
          emit(.completed(exitCode: exitCode(from: status), processIdentifier: processIdentifier))
        }
      }
    } catch {
      cancelInFlight = nil
      throw error
    }
  }
}

private func exitCode(from status: ProcessExitStatus) -> Int32 {
  switch status {
  case .exited(let code):
    return Int32(code)
  case .signalled(let signal):
    return Int32(128 + signal)
  }
}

public func shellSplit(_ input: String) -> [String] {
  var out: [String] = []
  var current = ""
  var inQuotes = false
  var escape = false

  for ch in input {
    if escape {
      current.append(ch)
      escape = false
      continue
    }
    if ch == "\\" {
      escape = true
      continue
    }
    if ch == "\"" {
      inQuotes.toggle()
      continue
    }
    if ch.isWhitespace && !inQuotes {
      if !current.isEmpty {
        out.append(current)
        current = ""
      }
      continue
    }
    current.append(ch)
  }

  if !current.isEmpty {
    out.append(current)
  }
  return out
}
