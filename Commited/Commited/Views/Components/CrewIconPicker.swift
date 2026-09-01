import SwiftUI

/// The default set of SF Symbols offered when creating a crew — spans
/// the three example categories (sport/food/work) plus a few more
/// general-purpose ones, matching the interactive mockup's icon grid.
enum CrewIcons {
    static let options = [
        "fork.knife", "dumbbell.fill", "briefcase.fill", "cup.and.saucer.fill",
        "leaf.fill", "book.fill", "paintbrush.fill", "gamecontroller.fill",
        "figure.run", "music.note"
    ]
    static let defaultIcon = "fork.knife"
}

/// Reusable "vibe" swatch row — six warm, cozy-DA colors distinct
/// enough to tell crews apart at a glance.
enum CrewSwatches {
    static let options = ["#D9713C", "#7A9169", "#B08968", "#C9A15A", "#A5644E", "#6B8CAE"]
}

/// Icon grid used by Create Crew and Create Boosted Community — tap a
/// symbol to select it, mirrors the mockup's `.icon-pick-row`.
struct CrewIconGrid: View {
    @Binding var selectedIcon: String
    let colorHex: String

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(CrewIcons.options, id: \.self) { icon in
                Button {
                    selectedIcon = icon
                } label: {
                    Image(systemName: icon)
                        .foregroundStyle(icon == selectedIcon ? Color(hex: colorHex) : .secondary)
                        .frame(width: 38, height: 38)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(icon == selectedIcon ? Color(hex: colorHex) : .clear, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Color swatch row used alongside `CrewIconGrid`.
struct CrewColorSwatchRow: View {
    @Binding var selectedColorHex: String

    var body: some View {
        HStack(spacing: 10) {
            ForEach(CrewSwatches.options, id: \.self) { hex in
                Circle()
                    .fill(Color(hex: hex))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Circle().stroke(.primary, lineWidth: hex == selectedColorHex ? 2 : 0)
                    )
                    .onTapGesture { selectedColorHex = hex }
            }
        }
    }
}
