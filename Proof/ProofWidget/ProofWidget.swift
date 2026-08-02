import SwiftUI
import WidgetKit

struct StreakEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
    let myImage: UIImage?
    let partnerImage: UIImage?
}

struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(
            date: Date(),
            snapshot: WidgetSnapshot(
                myUid: "me", bestCurrentStreak: 18, totalResolutions: 3, completedToday: 1, updatedAt: Date(),
                partnerStreaks: [
                    PartnerStreakSummary(id: "1", name: "Marco", streak: 9, completedToday: true),
                    PartnerStreakSummary(id: "2", name: "Léa", streak: 31, completedToday: false)
                ]
            ),
            myImage: nil,
            partnerImage: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        // Widget data only changes when the app writes a new snapshot;
        // this refresh is just a safety net against a stale read.
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        completion(Timeline(entries: [makeEntry()], policy: .after(nextRefresh)))
    }

    private func makeEntry() -> StreakEntry {
        let snapshot = WidgetSnapshot.load()
        let myImage = snapshot.flatMap { WidgetPhotoLoader.image(forUid: $0.myUid) }
        let featuredPartner = snapshot?.partnerStreaks.first { $0.completedToday }
        let partnerImage = featuredPartner.flatMap { WidgetPhotoLoader.image(forUid: $0.id) }
        return StreakEntry(date: Date(), snapshot: snapshot, myImage: myImage, partnerImage: partnerImage)
    }
}

struct ProofWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: StreakEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            switch family {
            case .systemMedium:
                MediumWidgetView(snapshot: snapshot, myImage: entry.myImage, partnerImage: entry.partnerImage)
            default:
                SmallWidgetView(snapshot: snapshot, myImage: entry.myImage)
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
    let myImage: UIImage?

    var completedToday: Bool { snapshot.completedToday > 0 }

    var body: some View {
        PhotoTile(image: completedToday ? myImage : nil, streak: snapshot.bestCurrentStreak, completed: completedToday, label: nil)
    }
}

/// Adds one accepted accountability partner's photo alongside the
/// user's own — only ever a partner who explicitly agreed to share
/// proof, never a plain follower.
private struct MediumWidgetView: View {
    let snapshot: WidgetSnapshot
    let myImage: UIImage?
    let partnerImage: UIImage?

    var completedToday: Bool { snapshot.completedToday > 0 }
    var featuredPartner: PartnerStreakSummary? { snapshot.partnerStreaks.first { $0.completedToday } }

    var body: some View {
        HStack(spacing: 6) {
            PhotoTile(image: completedToday ? myImage : nil, streak: snapshot.bestCurrentStreak, completed: completedToday, label: "You")
            if let partner = featuredPartner {
                PhotoTile(image: partnerImage, streak: partner.streak, completed: true, label: partner.name)
            } else {
                NoPartnerTile()
            }
        }
    }
}

/// A single BeReal-style photo tile: the proof photo fills the frame,
/// the streak sits over it as a badge, and a bottom gradient keeps the
/// name/status legible over whatever the photo looks like.
private struct PhotoTile: View {
    let image: UIImage?
    let streak: Int
    let completed: Bool
    let label: String?

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(colors: [.gray.opacity(0.35), .gray.opacity(0.55)], startPoint: .top, endPoint: .bottom)
            }

            LinearGradient(colors: [.black.opacity(0.45), .clear], startPoint: .top, endPoint: .bottom)
                .frame(maxHeight: 44)
                .frame(maxWidth: .infinity, alignment: .top)

            HStack(spacing: 3) {
                Text("🔥")
                Text("\(streak)").fontWeight(.bold)
            }
            .font(.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.black.opacity(0.35), in: Capsule())
            .padding(6)

            VStack {
                Spacer()
                HStack {
                    if let label {
                        Text(label)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                    Spacer()
                    if !completed {
                        Image(systemName: "circle")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .padding(6)
                .background(
                    LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct NoPartnerTile: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14).fill(.gray.opacity(0.15))
            VStack(spacing: 2) {
                Image(systemName: "person.badge.plus").foregroundStyle(.secondary)
                Text("No partner\nproof yet").font(.caption2).multilineTextAlignment(.center).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private extension View {
    /// `containerBackground(_:for:)` is iOS 17+; the app's deployment
    /// target is 16, so this falls back to a plain `.background()`
    /// there instead of failing to build.
    @ViewBuilder
    func widgetBackground() -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(.fill.tertiary, for: .widget)
        } else {
            background()
        }
    }
}

struct ProofWidget: Widget {
    let kind = "ProofWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            ProofWidgetEntryView(entry: entry)
                .widgetBackground()
        }
        .configurationDisplayName("Proof Streak")
        .description("Today's proof photo and streak — yours, and an accepted partner's.")
        .supportedFamilies([.systemSmall, .systemMedium])
        // .contentMarginsDisabled() (edge-to-edge photo, no system
        // padding) is also iOS 17+ — worth adding once the minimum OS
        // version moves up.
    }
}
