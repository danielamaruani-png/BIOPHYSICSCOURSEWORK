import SwiftUI

/// Shared avatar component — used by Profile, Friends, and crew member
/// rows alike. Moved here (out of ProfileView.swift, where it used to
/// live) since it was already being used by more than just that screen.
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

/// A small colored circle showing a person's initial — used for crew
/// member rows and feed post authors, where there's no `photoURL` on
/// hand (just a name + colorHex), matching the mockup's colored-initial
/// avatars.
struct InitialAvatarView: View {
    let name: String
    let colorHex: String
    var size: CGFloat = 32

    var body: some View {
        Circle()
            .fill(Color(hex: colorHex))
            .frame(width: size, height: size)
            .overlay(
                Text(name.prefix(1).uppercased())
                    .font(.system(size: size * 0.42, weight: .bold))
                    .foregroundStyle(.white)
            )
    }
}
