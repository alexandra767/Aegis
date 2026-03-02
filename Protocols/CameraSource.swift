import Foundation
import CoreImage

protocol CameraSource: Sendable {
    var name: String { get }
    var isConnected: Bool { get async }
    func snapshot() async throws -> Data
    func streamFrames() -> AsyncThrowingStream<CIImage, Error>
}
