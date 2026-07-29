import SwiftUI

/// Simple week-column calendar heatmap, GitHub-contributions style,
/// covering the last ~14 weeks — enough history to feel meaningful
/// without paginating for a Phase 1 screen.
struct HeatmapGrid: View {
    let markedDays: Set<DateComponents>
    let color: Color

    private let weeksBack = 14
    private let calendar = Calendar.current

    private var days: [Date] {
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -(weeksBack * 7 - 1), to: today) ?? today
        return (0..<(weeksBack * 7)).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(days, id: \.self) { day in
                RoundedRectangle(cornerRadius: 3)
                    .fill(isMarked(day) ? color : Color(.systemGray5))
                    .frame(height: 14)
            }
        }
    }

    private func isMarked(_ day: Date) -> Bool {
        let components = calendar.dateComponents([.year, .month, .day], from: day)
        return markedDays.contains(components)
    }
}
