import SwiftUI

enum SortOption: String, CaseIterable {
    case recent = "Recently added"
    case priceLowHigh = "Price: low→high"
    case priceHighLow = "Price: high→low"
}

struct SortFilterSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Binding var sortOption: SortOption
    @Binding var filterMemberId: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Sort by")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                VStack(spacing: 8) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button {
                            sortOption = option
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                                if sortOption == option {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Theme.primary)
                                }
                            }
                            .padding(12)
                            .cardBackground(cornerRadius: 10)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Filter by member")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip(title: "All", selected: filterMemberId == nil) { filterMemberId = nil }
                        ForEach(appState.members) { member in
                            filterChip(
                                title: member.id == appState.user?.id ? "You" : member.name,
                                selected: filterMemberId == member.id,
                                hex: member.colorHex
                            ) { filterMemberId = member.id }
                        }
                    }
                }
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(20)
        .background(Theme.background)
    }

    private func filterChip(title: String, selected: Bool, hex: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let hex {
                    Circle().fill(Color(hex: hex)).frame(width: 8, height: 8)
                }
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(selected ? .white : Theme.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(selected ? Theme.primary : Theme.card)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(selected ? Color.clear : Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
