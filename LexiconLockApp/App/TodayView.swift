import SwiftUI

/// Home tab: reward-framed call to action to do a quick review and earn a break.
struct TodayView: View {
    @EnvironmentObject private var services: AppServices
    @Binding var showingReview: Bool
    @State private var due = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)

                Text(due > 0 ? "\(due) card\(due == 1 ? "" : "s") ready" : "You’re all caught up")
                    .font(.title.bold())
                Text(due > 0
                     ? "Do a few quick reps to earn your break."
                     : "Come back later for more reps, or get ahead now.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    showingReview = true
                } label: {
                    Text("Earn a break").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                Spacer()
            }
            .padding()
            .navigationTitle("Today")
            .onAppear { due = services.dueCount() }
            .onChange(of: showingReview) { _, isShowing in
                if !isShowing { due = services.dueCount() } // refresh after a session
            }
        }
    }
}
