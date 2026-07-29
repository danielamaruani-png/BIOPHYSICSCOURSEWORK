import SwiftUI

struct MissionRow: View {
    let resolution: Resolution
    let isCompletedToday: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: resolution.icon)
                .font(.title3)
                .foregroundStyle(resolution.color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(resolution.name).font(.headline)
                Text(resolution.targetFrequency.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if resolution.currentStreak > 0 {
                StreakBadge(streak: resolution.currentStreak)
            }

            Image(systemName: isCompletedToday ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(isCompletedToday ? .green : .secondary)
        }
        .padding(.vertical, 6)
    }
}
