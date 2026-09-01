import SwiftUI

private enum CommunitiesScope: String, CaseIterable {
    case myCrews = "My Crews"
    case local = "Local"
}

/// Home tab: there's no solo "objective" screen anymore — joining or
/// creating a crew *is* the objective. The top switch flips between
/// "My Crews" (private crews this user belongs to, from
/// `SessionViewModel.myCrews`) and "Local" (public crews, events, and
/// challenges scoped to `UserProfile.localCity`).
struct CommunitiesView: View {
    @EnvironmentObject var session: SessionViewModel
    @StateObject private var viewModel = CommunitiesViewModel()

    @State private var scope: CommunitiesScope = .myCrews
    @State private var localSearch = ""
    @State private var showFabMenu = false
    @State private var showCreateCrew = false
    @State private var showCreateEvent = false
    @State private var showCreateChallenge = false
    @State private var creationContext: CommunitiesScope = .myCrews
    @State private var openedCrew: Crew?

    private var uid: String { session.userId ?? "" }
    private var city: String { session.profile?.localCity ?? "Paris" }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Scope", selection: $scope) {
                    ForEach(CommunitiesScope.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding()

                ScrollView {
                    switch scope {
                    case .myCrews: myCrewsList
                    case .local: localList
                    }
                }
            }
            .navigationTitle("Communities")
            .overlay(alignment: .bottomTrailing) {
                Button {
                    creationContext = scope
                    showFabMenu = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(Color.accentColor, in: Circle())
                        .shadow(radius: 6)
                }
                .padding(20)
            }
            .task { await viewModel.loadLocal(city: city) }
            .refreshable {
                await session.refreshCrews()
                await viewModel.loadLocal(city: city)
            }
            .confirmationDialog("Create", isPresented: $showFabMenu, titleVisibility: .visible) {
                Button("New crew") { showCreateCrew = true }
                Button("New event") { showCreateEvent = true }
                Button("New challenge") { showCreateChallenge = true }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showCreateCrew) {
                CreateCrewView(context: creationContext == .myCrews ? .myCrews : .local, city: city) {
                    Task {
                        await session.refreshCrews()
                        await viewModel.loadLocal(city: city)
                    }
                }
            }
            .sheet(isPresented: $showCreateEvent) {
                CreateEventView(defaultToLocal: creationContext == .local, city: city, myCrews: session.myCrews) {
                    Task {
                        await session.refreshCrews()
                        await viewModel.loadLocal(city: city)
                    }
                }
            }
            .sheet(isPresented: $showCreateChallenge) {
                CreateChallengeView(defaultToLocal: creationContext == .local, city: city, myCrews: session.myCrews) {
                    Task {
                        await session.refreshCrews()
                        await viewModel.loadLocal(city: city)
                    }
                }
            }
            .sheet(item: $openedCrew) { crew in
                CrewChatView(crew: crew)
            }
            .onChange(of: session.pendingCaptureCrewId) { crewId in
                // Widget deep-link: jump straight into that crew's chat
                // (which owns the capture button) instead of just
                // landing on Communities.
                guard let crewId else { return }
                if let crew = session.myCrews.first(where: { $0.id == crewId }) {
                    openedCrew = crew
                }
            }
        }
    }

    private var myCrewsList: some View {
        LazyVStack(spacing: 10) {
            if session.myCrews.isEmpty {
                Text("No crews yet — tap + to start one.")
                    .foregroundStyle(.secondary)
                    .padding(.top, 40)
            }
            ForEach(session.myCrews) { crew in
                CrewRowView(crew: crew, myStreak: session.myMemberships[crew.id ?? ""]?.streak)
                    .onTapGesture { openedCrew = crew }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 90)
    }

    private var localList: some View {
        LazyVStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search local communities…", text: $localSearch)
            }
            .padding(10)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

            if !localSearch.isEmpty {
                sectionLabel("Communities matching \"\(localSearch)\"")
                ForEach(matchingLocalCrews) { crew in
                    CrewRowView(crew: crew, myStreak: nil, isJoined: crew.memberUids.contains(uid))
                        .onTapGesture { handleLocalCrewTap(crew) }
                }
            } else {
                if !viewModel.localEvents.isEmpty {
                    sectionLabel("Events")
                    ForEach(viewModel.localEvents) { event in
                        LocalEventRowView(event: event)
                    }
                }
                if !viewModel.localChallenges.isEmpty {
                    sectionLabel("Challenges")
                    ForEach(viewModel.localChallenges) { challenge in
                        ChallengeRowView(title: challenge.title, from: challenge.from, progress: challenge.progress, total: challenge.total, colorHex: challenge.colorHex)
                    }
                }
                sectionLabel("Chats")
                ForEach(viewModel.joinedCrews(uid: uid)) { crew in
                    CrewRowView(crew: crew, myStreak: nil, isJoined: true)
                        .onTapGesture { openedCrew = crew }
                }
                sectionLabel("Discover more nearby")
                ForEach(viewModel.discoverableCrews(uid: uid)) { crew in
                    CrewRowView(crew: crew, myStreak: nil, isJoined: false, onJoin: { Task { await join(crew) } })
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 90)
    }

    private var matchingLocalCrews: [Crew] {
        viewModel.localCrews.filter { $0.name.localizedCaseInsensitiveContains(localSearch) }
    }

    private func handleLocalCrewTap(_ crew: Crew) {
        if crew.memberUids.contains(uid) {
            openedCrew = crew
        } else {
            Task { await join(crew) }
        }
    }

    private func join(_ crew: Crew) async {
        guard let profile = session.profile else { return }
        let ok = await viewModel.joinCrew(crew, uid: uid, name: profile.name, colorHex: "#D9713C")
        if ok { await viewModel.loadLocal(city: city) }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption.bold())
            .foregroundStyle(.secondary)
            .padding(.top, 8)
    }
}

/// Row shared by My Crews and Local's Chats/Discover lists — shows the
/// crew's icon/name/visibility, its "checked in today" ratio, and
/// either a streak badge (My Crews) or a Join button (Discover).
struct CrewRowView: View {
    let crew: Crew
    let myStreak: Int?
    var isJoined: Bool = true
    var onJoin: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color(hex: crew.colorHex).opacity(0.2))
                Image(systemName: crew.iconName).foregroundStyle(Color(hex: crew.colorHex))
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(crew.name).font(.subheadline.bold())
                    if crew.boosted {
                        Label("Boosted", systemImage: "arrow.up.forward.app.fill")
                            .font(.caption2.bold())
                            .foregroundStyle(Color.accentColor)
                    }
                }
                Text("\(crew.memberCount) members · \(crew.isPrivate ? "Private" : "Public")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let onJoin {
                Button("Join", action: onJoin)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            } else if let myStreak {
                StreakBadge(streak: myStreak)
            }
            if isJoined && onJoin == nil {
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        .contentShape(Rectangle())
    }
}

struct LocalEventRowView: View {
    let event: LocalEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "calendar").foregroundStyle(Color.accentColor)
                VStack(alignment: .leading) {
                    Text(event.title).font(.subheadline.bold())
                    Text("\(event.when) · \(event.goingUids.count)+ going").font(.caption).foregroundStyle(.secondary)
                }
            }
            Text("🔥 +\(event.streakBonus) streak bonus")
                .font(.caption.bold())
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Color.green.opacity(0.15), in: Capsule())
                .foregroundStyle(.green)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct ChallengeRowView: View {
    let title: String
    let from: String
    let progress: Int
    let total: Int
    let colorHex: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading) {
                    Text(title).font(.subheadline.bold())
                    Text(from).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(progress)/\(total)").font(.caption.bold()).foregroundStyle(.secondary)
            }
            ProgressView(value: Double(progress), total: Double(max(total, 1)))
                .tint(Color(hex: colorHex))
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
