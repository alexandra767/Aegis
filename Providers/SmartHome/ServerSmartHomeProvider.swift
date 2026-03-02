import Foundation

struct ServerSmartHomeProvider: SmartHomeProvider {
    let baseURL: String
    let bearerToken: String?

    private var headers: [String: String] {
        var h: [String: String] = [:]
        if let token = bearerToken {
            h["Authorization"] = "Bearer \(token)"
        }
        return h
    }

    func listRooms() async throws -> [SmartRoom] {
        // Phase 3: GET /api/v1/smart-home/lights
        return []
    }

    func controlRoom(name: String, on: Bool?, brightness: Int?, color: String?) async throws {
        // Phase 3: PUT /api/v1/smart-home/lights/room/{name}
        throw AIProviderError.unavailable("Server smart home coming in Phase 3")
    }

    func listScenes() async throws -> [SmartScene] {
        // Phase 3: GET /api/v1/smart-home/scenes
        return []
    }

    func activateScene(_ sceneID: String) async throws {
        // Phase 3: POST /api/v1/smart-home/scene/{name}
        throw AIProviderError.unavailable("Server smart home coming in Phase 3")
    }

    func sendTVCommand(_ command: String) async throws {
        // Phase 3: POST /api/v1/smart-home/tv/command
        throw AIProviderError.unavailable("Server TV remote coming in Phase 3")
    }
}
