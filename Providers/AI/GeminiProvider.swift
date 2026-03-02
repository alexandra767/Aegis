import Foundation

struct GeminiProvider: AIProvider {
    let providerType: AIProviderType = .gemini
    let displayName = "Gemini"
    let apiKey: String

    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"

    var isAvailable: Bool {
        get async {
            guard let url = URL(string: "\(baseURL)/models?key=\(apiKey)") else { return false }
            do {
                let (_, response) = try await URLSession.shared.data(from: url)
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
                AIModel(id: "gemini-2.0-flash", name: "Gemini 2.0 Flash", providerType: .gemini),
                AIModel(id: "gemini-2.0-pro", name: "Gemini 2.0 Pro", providerType: .gemini),
                AIModel(id: "gemini-1.5-pro", name: "Gemini 1.5 Pro", providerType: .gemini),
            ]
        }
    }

    func sendMessage(_ content: String, context: ChatContext) -> AsyncThrowingStream<String, Error> {
        let model = "gemini-2.0-flash"
        guard let url = URL(string: "\(baseURL)/models/\(model):streamGenerateContent?alt=sse&key=\(apiKey)") else {
            return AsyncThrowingStream { $0.finish(throwing: AIProviderError.serverError("Invalid URL")) }
        }

        var contents: [[String: Any]] = []
        if let systemPrompt = context.systemPrompt {
            contents.append(["role": "user", "parts": [["text": "System: \(systemPrompt)"]]])
            contents.append(["role": "model", "parts": [["text": "Understood."]]])
        }
        for msg in context.previousMessages {
            let role = msg.role == "user" ? "user" : "model"
            contents.append(["role": role, "parts": [["text": msg.content]]])
        }
        contents.append(["role": "user", "parts": [["text": content]]])

        let body: [String: Any] = ["contents": contents]

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
                    request.httpBody = httpBody

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    guard let http = response as? HTTPURLResponse else {
                        continuation.finish(throwing: NetworkError.invalidResponse)
                        return
                    }
                    guard (200...299).contains(http.statusCode) else {
                        continuation.finish(throwing: NetworkError.httpError(http.statusCode, "Gemini API error"))
                        return
                    }

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let payload = String(line.dropFirst(6))
                        guard let data = payload.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let candidates = json["candidates"] as? [[String: Any]],
                              let firstCandidate = candidates.first,
                              let contentObj = firstCandidate["content"] as? [String: Any],
                              let parts = contentObj["parts"] as? [[String: Any]],
                              let text = parts.first?["text"] as? String else {
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
