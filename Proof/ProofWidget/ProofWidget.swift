import SwiftUI
import WidgetKit

struct StreakEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
}

struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: Date(), snapshot: WidgetSnapshot(
            bestCurrentStreak: 18, totalResolutions: 3, completedToday: 1, updatedAt: Date(),
            partnerStreaks: [
                PartnerStreakSummary(id: "1", name: "Marco", streak: 9, completedToday: true),
                PartnerStreakSummary(id: "2", name: "Léa", streak: 31, completedToday: false)
            ]
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
    @Environment(\.widgetFamily) private var family
    var entry: StreakEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            switch family {
            case .systemMedium:
                MediumWidgetView(snapshot: snapshot)
            default:
                SmallWidgetView(snapshot: snapshot)
            }
        } else {
            VStack {
                Text("Open Proof").font(.headline)
                Text("to get started").font(.caption).foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

private struct SmallWidgetView: View {
    let snapshot: WidgetSnapshot

    var allDone: Bool {
        snapshot.completedToday >= snapshot.totalResolutions && snapshot.totalResolutions > 0
    }

    var body: some View {
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
    }
}

/// Adds accepted accountability partners alongside the user's own
/// streak — only ever populated with people who explicitly agreed to
/// share proof, never plain followers.
private struct MediumWidgetView: View {
    let snapshot: WidgetSnapshot

    var allDone: Bool {
        snapshot.completedToday >= snapshot.totalResolutions && snapshot.totalResolutions > 0
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("You").font(.caption).foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    Text("🔥")
                    Text("\(snapshot.bestCurrentStreak)").font(.title.bold())
                }
                Text(allDone ? "Done today" : "Missing today")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(allDone ? .green : .orange)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            VStack(alignment: .leading, spacing: 5) {
                Text("Partners").font(.caption).foregroundStyle(.secondary)
                if snapshot.partnerStreaks.isEmpty {
                    Text("None yet").font(.caption2).foregroundStyle(.secondary)
                } else {
                    ForEach(snapshot.partnerStreaks.prefix(3)) { partner in
                        HStack(spacing: 5) {
                            Circle()
                                .fill(partner.completedToday ? .green : .orange)
                                .frame(width: 6, height: 6)
                            Text(partner.name).font(.caption2).lineLimit(1)
                            Spacer()
                            Text("🔥\(partner.streak)").font(.caption2.weight(.semibold))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
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
        .description("Your current streak, today's status, and accepted partners' streaks.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
