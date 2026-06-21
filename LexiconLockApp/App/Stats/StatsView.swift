import SwiftUI
import LearningGateCore

/// Reward-framed progress: cards reviewed, current streak, breaks earned.
struct StatsView: View {
    @EnvironmentObject private var services: AppServices
    @State private var stats: Stats = .empty

    var body: some View {
        NavigationStack {
            List {
                Section {
                    statRow(icon: "flame.fill", title: "Current streak",
                            value: "\(stats.currentStreakDays) day\(stats.currentStreakDays == 1 ? "" : "s")")
                    statRow(icon: "checkmark.circle.fill", title: "Cards reviewed",
                            value: "\(stats.cardsReviewed)")
                    statRow(icon: "gift.fill", title: "Breaks earned",
                            value: "\(stats.breaksEarned)")
                }
                Section {
                    Text("Every rep counts. Keep your streak alive and keep earning your scroll time.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Progress")
            .onAppear { stats = services.reviewStore.current(now: Date()) }
        }
    }

    private func statRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            Text(value).font(.headline).foregroundStyle(.tint)
        }
    }
}
