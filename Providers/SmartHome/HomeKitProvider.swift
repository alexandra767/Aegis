import Foundation

struct HomeKitSmartHomeProvider: SmartHomeProvider {
    func listRooms() async throws -> [SmartRoom] {
        // Phase 3: HMHomeManager room discovery
        return []
    }

    func controlRoom(name: String, on: Bool?, brightness: Int?, color: String?) async throws {
        // Phase 3: HMAccessory characteristic writes
        throw AIProviderError.unavailable("HomeKit smart home coming in Phase 3")
    }

    func listScenes() async throws -> [SmartScene] {
        // Phase 3: HMActionSet discovery
        return []
    }

    func activateScene(_ sceneID: String) async throws {
        // Phase 3: HMActionSet execution
        throw AIProviderError.unavailable("HomeKit smart home coming in Phase 3")
    }

    func sendTVCommand(_ command: String) async throws {
        throw AIProviderError.unavailable("TV remote not supported via HomeKit — use Custom Server")
    }
}
