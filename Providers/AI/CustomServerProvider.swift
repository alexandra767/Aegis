import Foundation

struct CustomServerProvider: AIProvider {
    let providerType: AIProviderType = .customServer
    let displayName = "Custom Server"
    let baseURL: String
    let bearerToken: String?

    var isAvailable: Bool {
        get async {
            guard let url = URL(string: "\(baseURL)/api/v1/health") else { return false }
            return await NetworkService.shared.testConnection(url: url, bearerToken: bearerToken)
        }
    }

    var availableModels: [AIModel] {
        get async {
            // Try to fetch models from server
            guard let url = URL(string: "\(baseURL)/api/v1/chat/models") else {
                return [AIModel(id: "default", name: "Server Default", providerType: .customServer)]
            }
            var headers: [String: String] = [:]
            if let token = bearerToken {
                headers["Authorization"] = "Bearer \(token)"
            }
            do {
                struct ModelList: Decodable {
                    let models: [ServerModel]
                }
                struct ServerModel: Decodable {
                    let id: String
                    let name: String
                }
                let result: ModelList = try await NetworkService.shared.request(url, headers: headers)
                return result.models.map { AIModel(id: $0.id, name: $0.name, providerType: .customServer) }
            } catch {
                return [AIModel(id: "default", name: "Server Default", providerType: .customServer)]
            }
        }
    }

    func sendMessage(_ content: String, context: ChatContext) -> AsyncThrowingStream<String, Error> {
        // Two-step Spark API: POST message → GET SSE stream
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    // Step 1: POST the message
                    guard let postURL = URL(string: "\(baseURL)/api/v1/chat/message") else {
                        continuation.finish(throwing: AIProviderError.serverError("Invalid server URL"))
                        return
                    }

                    struct ChatRequest: Encodable {
                        let message: String
                        let conversation_id: String
                        let context: [[String: String]]?
                    }

                    let contextMessages = context.previousMessages.map { ["role": $0.role, "content": $0.content] }
                    let chatReq = ChatRequest(
                        message: content,
                        conversation_id: context.conversationID,
                        context: contextMessages.isEmpty ? nil : contextMessages
                    )

                    var headers: [String: String] = [:]
                    if let token = bearerToken {
                        headers["Authorization"] = "Bearer \(token)"
                    }

                    let responseData = try await NetworkService.shared.post(postURL, body: chatReq, headers: headers)

                    // Parse response to get stream URL
                    guard let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
                          let streamPath = json["stream_url"] as? String else {
                        // Non-streaming response — return full text
                        if let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
                           let text = json["response"] as? String {
                            continuation.yield(text)
                            continuation.finish()
                            return
                        }
                        continuation.finish(throwing: AIProviderError.serverError("Invalid server response"))
                        return
                    }

                    // Step 2: GET SSE stream
                    guard let streamURL = URL(string: "\(baseURL)\(streamPath)") else {
                        continuation.finish(throwing: AIProviderError.serverError("Invalid stream URL"))
                        return
                    }

                    let stream = await NetworkService.shared.streamSSE(url: streamURL, headers: headers)
                    for try await chunk in stream {
                        // Parse SSE data chunks
                        if let data = chunk.data(using: .utf8),
                           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let text = json["content"] as? String {
                            continuation.yield(text)
                        } else {
                            // Plain text chunk
                            continuation.yield(chunk)
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
