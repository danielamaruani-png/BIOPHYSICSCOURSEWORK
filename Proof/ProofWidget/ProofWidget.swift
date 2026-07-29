import SwiftUI
import WidgetKit

struct StreakEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
}

struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: Date(), snapshot: WidgetSnapshot(
            bestCurrentStreak: 18, totalResolutions: 3, completedToday: 1, updatedAt: Date()
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        completion(StreakEntry(date: Date(), snapshot: WidgetSnapshot.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let entry = StreakEntry(date: Date(), snapshot: WidgetSnapshot.load())
        // Widget data only changes when the app writes a new snapshot;
        // this refresh is just a safety net against a stale read.
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

struct ProofWidgetEntryView: View {
    var entry: StreakEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            let allDone = snapshot.completedToday >= snapshot.totalResolutions && snapshot.totalResolutions > 0
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text("🔥")
                    Text("\(snapshot.bestCurrentStreak)").font(.title2.bold())
                }
                Spacer()
                Text(allDone ? "Today's proof done" : "Today's proof missing")
                    .font(.caption)
                    .foregroundStyle(allDone ? .green : .orange)
                    .fontWeight(.semibold)
            }
            .padding()
        } else {
            VStack {
                Text("Open Proof").font(.headline)
                Text("to get started").font(.caption).foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

struct ProofWidget: Widget {
    let kind = "ProofWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            ProofWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Proof Streak")
        .description("Your current streak and today's status.")
        .supportedFamilies([.systemSmall])
    }
}
