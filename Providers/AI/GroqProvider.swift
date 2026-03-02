import Foundation

struct GroqProvider: AIProvider {
    let providerType: AIProviderType = .groq
    let displayName = "Groq"
    let apiKey: String

    private let baseURL = "https://api.groq.com/openai/v1"

    var isAvailable: Bool {
        get async {
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
                AIModel(id: "llama-3.3-70b-versatile", name: "Llama 3.3 70B", providerType: .groq),
                AIModel(id: "llama-3.1-8b-instant", name: "Llama 3.1 8B", providerType: .groq),
                AIModel(id: "mixtral-8x7b-32768", name: "Mixtral 8x7B", providerType: .groq),
            ]
        }
    }

    func sendMessage(_ content: String, context: ChatContext) -> AsyncThrowingStream<String, Error> {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            return AsyncThrowingStream { $0.finish(throwing: AIProviderError.serverError("Invalid URL")) }
        }

        // Groq uses OpenAI-compatible format
        var messages: [[String: String]] = []
        if let systemPrompt = context.systemPrompt {
            messages.append(["role": "system", "content": systemPrompt])
        }
        for msg in context.previousMessages {
            messages.append(["role": msg.role, "content": msg.content])
        }
        messages.append(["role": "user", "content": content])

        let body: [String: Any] = [
            "model": "llama-3.3-70b-versatile",
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
                    guard (200...299).contains(http.statusCode) else {
                        continuation.finish(throwing: NetworkError.httpError(http.statusCode, "Groq API error"))
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
