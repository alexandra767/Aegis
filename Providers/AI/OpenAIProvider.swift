import Foundation

struct OpenAIProvider: AIProvider {
    let providerType: AIProviderType = .openAI
    let displayName = "OpenAI"
    let apiKey: String

    private let baseURL = "https://api.openai.com/v1"

    var isAvailable: Bool {
        get async {
            // Verify key by listing models
            guard let url = URL(string: "\(baseURL)/models") else { return false }
            var request = URLRequest(url: url)
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.timeoutInterval = 10
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
                AIModel(id: "gpt-4o", name: "GPT-4o", providerType: .openAI),
                AIModel(id: "gpt-4o-mini", name: "GPT-4o Mini", providerType: .openAI),
                AIModel(id: "gpt-4-turbo", name: "GPT-4 Turbo", providerType: .openAI),
                AIModel(id: "o3-mini", name: "o3-mini", providerType: .openAI),
            ]
        }
    }

    func sendMessage(_ content: String, context: ChatContext) -> AsyncThrowingStream<String, Error> {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            return AsyncThrowingStream { $0.finish(throwing: AIProviderError.serverError("Invalid URL")) }
        }

        var messages: [[String: String]] = []
        if let systemPrompt = context.systemPrompt {
            messages.append(["role": "system", "content": systemPrompt])
        }
        for msg in context.previousMessages {
            messages.append(["role": msg.role, "content": msg.content])
        }
        messages.append(["role": "user", "content": content])

        let body: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "stream": true,
        ]

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
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
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
                        continuation.finish(throwing: NetworkError.httpError(http.statusCode, "OpenAI API error"))
                        return
                    }

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let payload = String(line.dropFirst(6))
                        if payload == "[DONE]" { break }

                        guard let data = payload.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let choices = json["choices"] as? [[String: Any]],
                              let delta = choices.first?["delta"] as? [String: Any],
                              let text = delta["content"] as? String else {
                            continue
                        }
                        continuation.yield(text)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
