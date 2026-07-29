import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var session: SessionViewModel
    @State private var showEdit = false

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

                Section("Resolutions") {
                    ForEach(session.resolutions) { resolution in
                        HStack {
                            Image(systemName: resolution.icon).foregroundStyle(resolution.color)
                            Text(resolution.name)
                            Spacer()
                            StreakBadge(streak: resolution.currentStreak)
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
        }
    }
}

struct AvatarView: View {
    let photoURL: String?
    var size: CGFloat = 40

    var body: some View {
        if let photoURL, let url = URL(string: photoURL) {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(Color(.secondarySystemBackground))
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        } else {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: size, height: size)
                .foregroundStyle(.secondary)
        }
    }
}
