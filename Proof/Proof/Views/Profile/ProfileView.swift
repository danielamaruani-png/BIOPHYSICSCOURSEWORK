import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var session: SessionViewModel
    @StateObject private var viewModel = ProfileViewModel()

    @State private var showEdit = false
    @State private var showChangeLocal = false
    @State private var showCreatorTools = false

    private var uid: String { session.userId ?? "" }
    private var city: String { session.profile?.localCity ?? "Paris" }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        AvatarView(photoURL: session.profile?.photoURL, size: 60)
                        VStack(alignment: .leading) {
                            Text(session.profile?.name ?? "")
                                .font(.title3.bold())
                            if let bio = session.profile?.bio, !bio.isEmpty {
                                Text(bio).foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section {
                    HStack {
                        Text("Total streak").font(.caption.bold()).foregroundStyle(.secondary)
                        Spacer()
                        Text("🔥 \(session.totalStreak)").font(.title2.bold())
                    }
                    .listRowBackground(
                        LinearGradient(colors: [.orange, .yellow.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundStyle(.white)
                }

                Section {
                    Button { showChangeLocal = true } label: {
                        LabeledContent("Local", value: city)
                    }
                    Toggle("Public feed", isOn: publicFeedBinding)
                    Text("Let your proof photos show up in everyone's random Feed")
                        .font(.caption).foregroundStyle(.secondary)
                }

                if let mostActive = mostActiveCrew {
                    Section {
                        HStack {
                            Image(systemName: mostActive.crew.iconName).foregroundStyle(Color(hex: mostActive.crew.colorHex))
                            VStack(alignment: .leading) {
                                Text("Most active in \(mostActive.crew.name)").font(.subheadline.bold())
                                Text("🔥 \(mostActive.streak)-day streak there").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Rewards") {
                    Text("Real perks for real streaks — unlocked automatically as your total streak grows.")
                        .font(.caption).foregroundStyle(.secondary)
                    ForEach(viewModel.rewards) { reward in
                        rewardRow(reward)
                    }
                }

                Section("Your crews") {
                    ForEach(session.myCrews) { crew in
                        HStack {
                            Image(systemName: crew.iconName).foregroundStyle(Color(hex: crew.colorHex))
                            Text(crew.name)
                            Spacer()
                            StreakBadge(streak: session.myMemberships[crew.id ?? ""]?.streak ?? 0)
                        }
                    }
                }

                if !nextEvents.isEmpty {
                    Section("My next events") {
                        ForEach(nextEvents, id: \.title) { event in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.title).font(.subheadline.bold())
                                Text("\(event.source) · \(event.when)").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if !allChallenges.isEmpty {
                    Section("Challenges") {
                        ForEach(allChallenges, id: \.title) { challenge in
                            ChallengeRowView(title: challenge.title, from: challenge.from, progress: challenge.progress, total: challenge.total, colorHex: challenge.colorHex)
                                .listRowInsets(EdgeInsets())
                                .padding(.vertical, 4)
                        }
                    }
                }

                if session.profile?.isCreator == true {
                    Section {
                        Button { showCreatorTools = true } label: {
                            Label("Creator tools", systemImage: "shield.fill")
                        }
                    }
                }

                Section {
                    Button("Sign out", role: .destructive) {
                        session.signOut()
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") { showEdit = true }
                }
            }
            .sheet(isPresented: $showEdit) {
                ProfileSetupView(isOnboarding: false)
            }
            .sheet(isPresented: $showChangeLocal) {
                ChangeLocalView(currentCity: city) { newCity in
                    Task {
                        _ = await viewModel.updateLocalCity(uid: uid, city: newCity)
                        session.profile?.localCity = newCity
                        await viewModel.loadLocalContext(city: newCity)
                    }
                }
            }
            .sheet(isPresented: $showCreatorTools) {
                CreatorToolsView(city: city)
            }
            .task {
                await viewModel.loadRewards()
                await viewModel.loadLocalContext(city: city)
            }
        }
    }

    private var publicFeedBinding: Binding<Bool> {
        Binding(
            get: { session.profile?.publicFeedOptIn ?? true },
            set: { newValue in
                session.profile?.publicFeedOptIn = newValue
                Task { await viewModel.updatePublicFeedOptIn(uid: uid, optedIn: newValue) }
            }
        )
    }

    private var mostActiveCrew: (crew: Crew, streak: Int)? {
        session.myCrews
            .compactMap { crew -> (Crew, Int)? in
                guard let streak = session.myMemberships[crew.id ?? ""]?.streak else { return nil }
                return (crew, streak)
            }
            .max { $0.1 < $1.1 }
    }

    private struct NextEvent { let title: String; let when: String; let source: String }

    private var nextEvents: [NextEvent] {
        let crewEvents = session.myCrews.compactMap { crew -> NextEvent? in
            guard let event = crew.event else { return nil }
            return NextEvent(title: event.title, when: event.when, source: crew.name)
        }
        let cityEvents = viewModel.localEvents.map { NextEvent(title: $0.title, when: $0.when, source: "Local · \(city)") }
        return crewEvents + cityEvents
    }

    private struct DisplayChallenge { let title: String; let from: String; let progress: Int; let total: Int; let colorHex: String }

    private var allChallenges: [DisplayChallenge] {
        let crewChallenges = session.myCrews.compactMap { crew -> DisplayChallenge? in
            guard let challenge = crew.challenge else { return nil }
            return DisplayChallenge(title: challenge.title, from: challenge.from, progress: challenge.progress, total: challenge.total, colorHex: challenge.colorHex)
        }
        let cityChallenges = viewModel.localChallenges.map {
            DisplayChallenge(title: $0.title, from: $0.from, progress: $0.progress, total: $0.total, colorHex: $0.colorHex)
        }
        return crewChallenges + cityChallenges
    }

    private func rewardRow(_ reward: Reward) -> some View {
        let unlocked = session.totalStreak >= reward.days
        let daysToGo = max(0, reward.days - session.totalStreak)
        return HStack {
            Text(reward.icon).font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(reward.label).font(.subheadline.bold())
                Text(unlocked ? "Unlocked · reached 🔥\(reward.days)" : "🔥 \(reward.days)-day streak · \(daysToGo) to go")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: unlocked ? "checkmark.circle.fill" : "lock.fill")
                .foregroundStyle(unlocked ? .green : .secondary)
        }
        .opacity(unlocked ? 1 : 0.6)
    }
}
