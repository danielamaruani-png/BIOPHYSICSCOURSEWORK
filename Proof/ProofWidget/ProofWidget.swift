import SwiftUI
import WidgetKit

struct StreakEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
    let myImage: UIImage?
    let spotlightImage: UIImage?
}

struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(
            date: Date(),
            snapshot: WidgetSnapshot(
                myUid: "me", totalStreak: 26, selectedCrewId: "mycrew", selectedCrewName: "Home Cooking",
                selectedCrewColorHex: "#D9713C", myStreakInSelectedCrew: 12, crewCheckedInToday: 3, crewSize: 4,
                spotlightMemberUid: "marco", spotlightMemberName: "Marco", spotlightDoneToday: true, updatedAt: Date()
            ),
            myImage: nil,
            spotlightImage: nil
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
        let spotlightImage = snapshot?.spotlightMemberUid.flatMap { WidgetPhotoLoader.image(forUid: $0) }
        return StreakEntry(date: Date(), snapshot: snapshot, myImage: myImage, spotlightImage: spotlightImage)
    }
}

struct ProofWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: StreakEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            switch family {
            case .systemMedium:
                MediumWidgetView(snapshot: snapshot, myImage: entry.myImage)
            default:
                SmallWidgetView(snapshot: snapshot, spotlightImage: entry.spotlightImage)
            }
        } else {
            VStack {
                Text("Open Proof").font(.headline)
                Text("join a crew to get started").font(.caption).foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

/// Spotlight tile: a crew member's photo (whoever checked in today) with
/// the crew's streak badge, plus a "post proof" button that deep-links
/// straight into that crew's capture sheet via `proof://capture`.
/// Camera-only capture (no gallery import) applies the same way whether
/// you got there from the app or the widget.
private struct SmallWidgetView: View {
    let snapshot: WidgetSnapshot
    let spotlightImage: UIImage?

    var body: some View {
        PhotoTile(
            image: snapshot.spotlightDoneToday ? spotlightImage : nil,
            streak: snapshot.myStreakInSelectedCrew,
            completed: snapshot.spotlightDoneToday,
            label: snapshot.selectedCrewName,
            showPostButton: true,
            crewId: snapshot.selectedCrewId
        )
    }
}

/// "You" tile next to a stat-split card (your streak vs. how many of
/// the crew checked in today) — mirrors the mockup's "streak crew vs
/// toi" widget.
private struct MediumWidgetView: View {
    let snapshot: WidgetSnapshot
    let myImage: UIImage?

    var body: some View {
        HStack(spacing: 6) {
            PhotoTile(
                image: myImage, streak: snapshot.myStreakInSelectedCrew,
                completed: myImage != nil, label: "You",
                showPostButton: true, crewId: snapshot.selectedCrewId
            )
            StatSplitTile(snapshot: snapshot)
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
    var showPostButton: Bool = false
    var crewId: String?

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

            if showPostButton, let crewId, let url = URL(string: "proof://capture?crewId=\(crewId)") {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Link(destination: url) {
                            Image(systemName: "camera.fill")
                                .font(.caption)
                                .foregroundStyle(.white)
                                .padding(8)
                                .background(Color.accentColor, in: Circle())
                        }
                    }
                }
                .padding(6)
            }

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

private struct StatSplitTile: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        HStack(spacing: 0) {
            statColumn(label: "You", value: "🔥\(snapshot.myStreakInSelectedCrew)", sub: "your streak")
            Divider()
            statColumn(
                label: snapshot.selectedCrewName,
                value: "🔥\(snapshot.crewCheckedInToday)/\(snapshot.crewSize)",
                sub: "checked in today"
            )
        }
        .background(.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
    }

    private func statColumn(label: String, value: String, sub: String) -> some View {
        VStack(spacing: 2) {
            Text(label.uppercased()).font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary)
            Text(value).font(.system(size: 18, weight: .bold, design: .rounded))
            Text(sub).font(.system(size: 8)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
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
        .description("Today's crew spotlight photo and streak — tap the camera to post straight from the widget.")
        .supportedFamilies([.systemSmall, .systemMedium])
        // .contentMarginsDisabled() (edge-to-edge photo, no system
        // padding) is also iOS 17+ — worth adding once the minimum OS
        // version moves up.
    }
}
