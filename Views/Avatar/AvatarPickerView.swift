import SwiftUI

struct AvatarPickerView: View {
    @AppStorage("selectedAvatarID") private var selectedAvatarID = AvatarConfig.defaultAvatar.id
    @State private var genderFilter: AvatarGenderFilter = .all
    var compact: Bool = false

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        VStack(spacing: compact ? 12 : 20) {
            if !compact {
                Text("Choose Your Assistant")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
            }

            // Gender filter
            Picker("Filter", selection: $genderFilter) {
                ForEach(AvatarGenderFilter.allCases, id: \.self) { filter in
                    Text(filter.displayName).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, compact ? 0 : 16)

            // Avatar grid
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(filteredAvatars) { avatar in
                    avatarCell(avatar)
                }
            }
            .padding(.horizontal, compact ? 0 : 16)
        }
    }

    private var filteredAvatars: [AvatarConfig] {
        switch genderFilter {
        case .all: return AvatarConfig.allAvatars
        case .male: return AvatarConfig.allAvatars.filter { $0.gender == .male }
        case .female: return AvatarConfig.allAvatars.filter { $0.gender == .female }
        }
    }

    private func avatarCell(_ avatar: AvatarConfig) -> some View {
        let isSelected = avatar.id == selectedAvatarID

        return Button {
            withAnimation(.spring(response: 0.3)) {
                selectedAvatarID = avatar.id
            }
        } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    AvatarView(avatar: avatar, size: compact ? 64 : 80)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: compact ? 18 : 22))
                            .foregroundStyle(AegisTheme.cyan)
                            .background(Circle().fill(Color.black))
                    }
                }

                Text(avatar.name)
                    .font(compact ? .caption : .subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? AegisTheme.cyan : AegisTheme.textSecondary)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AegisTheme.cyan.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? AegisTheme.cyan.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Gender Filter

private enum AvatarGenderFilter: CaseIterable {
    case all, male, female

    var displayName: String {
        switch self {
        case .all: "All"
        case .male: "Male"
        case .female: "Female"
        }
    }
}
