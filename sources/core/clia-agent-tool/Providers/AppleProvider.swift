import CommonAI
import CommonAIApple
import Foundation

enum AppleProviderError: LocalizedError {
  case foundationModelsUnavailable
  case platformUnavailable

  var errorDescription: String? {
    switch self {
    case .foundationModelsUnavailable:
      "Apple Intelligence requires Apple's FoundationModels framework, which is unavailable on this host."

    case .platformUnavailable:
      "Apple Intelligence chat requires iOS 26 or macOS 26."
    }
  }
}

public struct AppleProvider: AIProvider {
  public init() {}

  public static func isAvailable() -> Bool {
    #if canImport(FoundationModels)
    if #available(iOS 26.0, macOS 26.0, *) {
      return true
    }
    return false
    #else
    return false
    #endif
  }

  public func generate(
    messages: [ProviderMessage],
    model: String,
    system: String?,
  ) async throws -> ProviderMessage {
    #if canImport(FoundationModels)
    guard #available(iOS 26.0, macOS 26.0, *) else {
      throw AppleProviderError.platformUnavailable
    }
    let service = AppleCommonAIService()
    let m = service.model(named: model)
    let content = Self.makeCAIContent(messages: messages, system: system)
    let response = try await m.generate(content)
    return .init(role: .model, text: response.text)
    #else
    throw AppleProviderError.foundationModelsUnavailable
    #endif
  }

  public func generateCompletion(
    messages: [ProviderMessage],
    model: String,
    system: String?
  ) async throws -> ProviderCompletion {
    #if canImport(FoundationModels)
    guard #available(iOS 26.0, macOS 26.0, *) else {
      throw AppleProviderError.platformUnavailable
    }
    let service = AppleCommonAIService()
    let m = service.model(named: model)
    let content = Self.makeCAIContent(messages: messages, system: system)
    let completion = try await m.complete(content)
    let message = ProviderMessage(role: .model, text: completion.primaryMessage.text)
    return ProviderCompletion(message: message, completion: completion)
    #else
    throw AppleProviderError.foundationModelsUnavailable
    #endif
  }

  #if canImport(Darwin)
  @available(macOS 12.0, *)
  public func stream(
    messages: [ProviderMessage],
    model: String,
    system: String?,
  ) -> AsyncThrowingStream<ProviderMessage, Error> {
    #if canImport(FoundationModels)
    guard #available(iOS 26.0, macOS 26.0, *) else {
      return AsyncThrowingStream { continuation in
        continuation.finish(throwing: AppleProviderError.platformUnavailable)
      }
    }
    let service = AppleCommonAIService()
    let m = service.model(named: model)
    let history = Self.makeCAIContent(messages: system.map { [.system($0)] } ?? [], system: nil)
    let payload = Self.makeCAIContent(messages: messages, system: nil)
    return AsyncThrowingStream { continuation in
      Task { @MainActor in
        let chat = m.startChat(history: history)
        let base = chat.sendStream(payload)
        var previous = ""
        do {
          for try await message in base {
            let full = message.text
            let delta: String =
              if full.hasPrefix(previous) {
                String(full.dropFirst(previous.count))
              } else {
                full
              }
            previous = full
            continuation.yield(.init(role: .model, text: delta))
          }
          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
      }
    }
    #else
    return AsyncThrowingStream { continuation in
      continuation.finish(throwing: AppleProviderError.foundationModelsUnavailable)
    }
    #endif
  }
  #endif

  public func listModels() async throws -> [String] {
    #if canImport(FoundationModels)
    guard #available(iOS 26.0, macOS 26.0, *) else {
      throw AppleProviderError.platformUnavailable
    }
    let service = AppleCommonAIService()
    return try await service.listModels(pageSize: nil).map(\.name)
    #else
    throw AppleProviderError.foundationModelsUnavailable
    #endif
  }

  private static func makeCAIContent(
    messages: [ProviderMessage],
    system: String?,
  ) -> [CAIContent] {
    var out: [CAIContent] = []
    if let system, !system.isEmpty { out.append(.system(system)) }
    for message in messages {
      switch message.role {
      case .user: out.append(.user(message.text))
      case .system: out.append(.system(message.text))
      case .model: out.append(.model(message.text))
      }
    }
    return out
  }
}
