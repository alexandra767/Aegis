import Foundation
import SwiftData

@Model
final class CameraConfig {
    @Attribute(.unique) var id: String
    var name: String
    var type: String  // "rtsp", "homekit", "server"
    var url: String?  // RTSP URL
    var isEnabled: Bool
    var sortOrder: Int

    init(id: String = UUID().uuidString, name: String, type: String, url: String? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.url = url
        self.isEnabled = true
        self.sortOrder = 0
    }
}
