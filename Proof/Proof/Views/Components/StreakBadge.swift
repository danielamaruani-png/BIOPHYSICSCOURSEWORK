import SwiftUI

struct StreakBadge: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 4) {
            Text("🔥")
            Text("\(streak)")
                .fontWeight(.bold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.15))
        .clipShape(Capsule())
    }
}
