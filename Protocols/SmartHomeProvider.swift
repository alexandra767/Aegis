import Foundation

struct SmartRoom: Identifiable, Sendable {
    let id: String
    let name: String
    var isOn: Bool
    var brightness: Int  // 0-254
    var colorName: String?
}

struct SmartScene: Identifiable, Sendable {
    let id: String
    let name: String
    let icon: String  // SF Symbol name
}

protocol SmartHomeProvider: Sendable {
    func listRooms() async throws -> [SmartRoom]
    func controlRoom(name: String, on: Bool?, brightness: Int?, color: String?) async throws
    func listScenes() async throws -> [SmartScene]
    func activateScene(_ sceneID: String) async throws
    func sendTVCommand(_ command: String) async throws
}
