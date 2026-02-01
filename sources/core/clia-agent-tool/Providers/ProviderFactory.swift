import CommonAI
import CommonAIOpenAI
import Foundation

enum ProviderBuildError: LocalizedError {
  case missingAPIKey(String)
  var errorDescription: String? {
    switch self {
    case .missingAPIKey(let name): "Missing API key. Provide via --api-key or env \(name)."
    }
  }
}

enum ProviderFactory {
  static func makeProvider(
    option: ProviderOption,
    apiKeyFlag: String?,
    orgFlag: String?,
  ) throws -> any AIProvider {
    switch option {
    case .openai:
      guard
        let tuple = DefaultOpenAIConfigurationProvider.load(
          apiKeyFlag: apiKeyFlag, orgFlag: orgFlag,
        )
      else { throw ProviderBuildError.missingAPIKey("OPENAI_API_KEY") }
      return OpenAIProvider(config: .init(apiKey: tuple.apiKey, organization: tuple.org))

    case .gemini:
      let key = apiKeyFlag ?? ProcessInfo.processInfo.environment["GEMINI_API_KEY"]
      guard let key, !key.isEmpty else { throw ProviderBuildError.missingAPIKey("GEMINI_API_KEY") }
      return GeminiProvider(apiKey: key)

    case .apple:
      return AppleProvider()
    }
  }
}
