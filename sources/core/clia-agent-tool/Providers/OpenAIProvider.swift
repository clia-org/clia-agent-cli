import CommonAI
import CommonAIOpenAI
import Foundation

public struct OpenAIProvider: AIProvider {
  public struct Config: Sendable {
    public let apiKey: String
    public let organization: String?
    public init(apiKey: String, organization: String? = nil) {
      self.apiKey = apiKey
      self.organization = organization
    }
  }

  private let service: OpenAICommonAIService

  public init(config: Config) {
    service = .init(apiKey: config.apiKey, organization: config.organization)
  }

  public func generate(
    messages: [ProviderMessage],
    model: String,
    system: String?,
  ) async throws -> ProviderMessage {
    let m = service.model(named: model)
    let content = Self.makeCAIContent(messages: messages, system: system)
    let res = try await m.generate(content)
    return .init(role: .model, text: res.text)
  }

  public func generateCompletion(
    messages: [ProviderMessage],
    model: String,
    system: String?
  ) async throws -> ProviderCompletion {
    let m = service.model(named: model)
    let content = Self.makeCAIContent(messages: messages, system: system)
    let completion = try await m.complete(content)
    let message = ProviderMessage(role: .model, text: completion.primaryMessage.text)
    return ProviderCompletion(message: message, completion: completion)
  }

  #if canImport(Darwin)
  @available(macOS 12.0, *)
  public func stream(
    messages: [ProviderMessage],
    model: String,
    system: String?,
  ) -> AsyncThrowingStream<ProviderMessage, Error> {
    let m = service.model(named: model)
    let history = Self.makeCAIContent(messages: system.map { [.system($0)] } ?? [], system: nil)
    let payload = Self.makeCAIContent(messages: messages, system: nil)
    return AsyncThrowingStream { continuation in
      Task { @MainActor in
        let chat = m.startChat(history: history)
        let base = chat.sendStream(payload)
        var previous = ""
        do {
          for try await next in base {
            let full = next.text
            let delta: String =
              if full.hasPrefix(previous) {
                String(full.dropFirst(previous.count))
              } else {
                full
              }
            previous = full
            continuation.yield(ProviderMessage(role: .model, text: delta))
          }
          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
      }
    }
  }
  #endif

  public func listModels() async throws -> [String] {
    try await service.listModels(pageSize: nil).map(\.name)
  }

  private static func makeCAIContent(messages: [ProviderMessage], system: String?) -> [CAIContent] {
    var out: [CAIContent] = []
    if let system, !system.isEmpty { out.append(.system(system)) }
    for m in messages {
      switch m.role {
      case .user: out.append(.user(m.text))
      case .system: out.append(.system(m.text))
      case .model: out.append(.model(m.text))
      }
    }
    return out
  }
}
