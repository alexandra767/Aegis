import Foundation

struct AnthropicProvider: AIProvider {
    let providerType: AIProviderType = .anthropic
    let displayName = "Anthropic"
    let apiKey: String

    private let baseURL = "https://api.anthropic.com/v1"

    var isAvailable: Bool {
        get async {
            // Send a minimal request to verify key
            guard let url = URL(string: "\(baseURL)/messages") else { return false }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 10
            let body: [String: Any] = [
                "model": "claude-sonnet-4-20250514",
                "max_tokens": 1,
                "messages": [["role": "user", "content": "hi"]],
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse else { return false }
                return http.statusCode == 200
            } catch {
                return false
            }
        }
    }

    var availableModels: [AIModel] {
        get async {
            [
                AIModel(id: "claude-opus-4-20250514", name: "Claude Opus 4", providerType: .anthropic),
                AIModel(id: "claude-sonnet-4-20250514", name: "Claude Sonnet 4", providerType: .anthropic),
                AIModel(id: "claude-haiku-4-20250414", name: "Claude Haiku 4", providerType: .anthropic),
            ]
        }
    }

    func sendMessage(_ content: String, context: ChatContext) -> AsyncThrowingStream<String, Error> {
        guard let url = URL(string: "\(baseURL)/messages") else {
            return AsyncThrowingStream { $0.finish(throwing: AIProviderError.serverError("Invalid URL")) }
        }

        var messages: [[String: String]] = []
        for msg in context.previousMessages {
            messages.append(["role": msg.role, "content": msg.content])
        }
        messages.append(["role": "user", "content": content])

        var body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 4096,
            "messages": messages,
            "stream": true,
        ]
        if let systemPrompt = context.systemPrompt {
            body["system"] = systemPrompt
        }

        let httpBody: Data
        do {
            httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return AsyncThrowingStream { $0.finish(throwing: error) }
        }

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
                    request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
                    request.httpBody = httpBody

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    guard let http = response as? HTTPURLResponse else {
                        continuation.finish(throwing: NetworkError.invalidResponse)
                        return
                    }

                    if http.statusCode == 401 {
                        continuation.finish(throwing: AIProviderError.invalidAPIKey)
                        return
                    }
                    if http.statusCode == 429 {
                        continuation.finish(throwing: AIProviderError.rateLimited)
                        return
                    }
                    guard (200...299).contains(http.statusCode) else {
                        continuation.finish(throwing: NetworkError.httpError(http.statusCode, "Anthropic API error"))
                        return
                    }

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let payload = String(line.dropFirst(6))

                        guard let data = payload.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                            continue
                        }

                        let eventType = json["type"] as? String

                        if eventType == "content_block_delta",
                           let delta = json["delta"] as? [String: Any],
                           let text = delta["text"] as? String {
                            continuation.yield(text)
                        }

                        if eventType == "message_stop" {
                            break
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
