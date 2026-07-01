import Foundation

enum AIConfig {
    /// OpenRouter API key. Leave empty — requests go through your Cloudflare Worker proxy.
    /// To test directly set TONECHECK_API_KEY in the scheme environment.
    static var apiKey: String {
        if let env = ProcessInfo.processInfo.environment["TONECHECK_API_KEY"], !env.isEmpty {
            return env
        }
        return ""
    }

    /// Full OpenRouter completions endpoint.
    static let endpoint = URL(string: "https://openrouter.ai/api/v1/chat/completions")!

    /// Model to use.
    static let model = "anthropic/claude-haiku-4-5"
}
