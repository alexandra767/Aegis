import Foundation

enum AvatarGender: String, CaseIterable, Sendable {
    case male, female

    var displayName: String {
        switch self {
        case .male: "Male"
        case .female: "Female"
        }
    }
}

struct AvatarConfig: Identifiable, Sendable {
    let id: String
    let name: String
    let imageName: String
    let sfSymbol: String
    let gender: AvatarGender

    static let allAvatars: [AvatarConfig] = [
        AvatarConfig(id: "male1", name: "Atlas", imageName: "avatar_male1", sfSymbol: "person.circle.fill", gender: .male),
        AvatarConfig(id: "male2", name: "Orion", imageName: "avatar_male2", sfSymbol: "figure.stand", gender: .male),
        AvatarConfig(id: "male3", name: "Nova", imageName: "avatar_male3", sfSymbol: "person.crop.circle.fill", gender: .male),
        AvatarConfig(id: "female1", name: "Aria", imageName: "avatar_female1", sfSymbol: "person.circle.fill", gender: .female),
        AvatarConfig(id: "female2", name: "Luna", imageName: "avatar_female2", sfSymbol: "figure.stand.dress", gender: .female),
        AvatarConfig(id: "female3", name: "Sage", imageName: "avatar_female3", sfSymbol: "person.crop.circle.fill", gender: .female),
    ]

    static func avatar(for id: String) -> AvatarConfig? {
        allAvatars.first { $0.id == id }
    }

    static var defaultAvatar: AvatarConfig {
        allAvatars[3] // Aria
    }

    static var selectedAvatarID: String {
        get { UserDefaults.standard.string(forKey: "selectedAvatarID") ?? defaultAvatar.id }
        set { UserDefaults.standard.set(newValue, forKey: "selectedAvatarID") }
    }

    static var selected: AvatarConfig {
        avatar(for: selectedAvatarID) ?? defaultAvatar
    }
}
