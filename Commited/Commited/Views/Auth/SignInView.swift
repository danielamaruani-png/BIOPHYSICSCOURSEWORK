import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var session: SessionViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            VStack(spacing: 8) {
                Text("Commited")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                Text("Post today's proof. Build the streak.")
                    .foregroundStyle(.secondary)
            }
            Spacer()

            VStack(spacing: 12) {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { _ in
                    Task { await session.signInWithApple() }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Button {
                    Task { await session.signInWithGoogle() }
                } label: {
                    HStack {
                        Image(systemName: "g.circle.fill")
                        Text("Continue with Google").fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 24)

            if let errorMessage = session.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 24)
            }

            Spacer()
        }
    }
}
