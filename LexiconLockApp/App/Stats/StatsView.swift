import SwiftUI
import LearningGateCore

/// Reward-framed progress: cards reviewed, current streak, breaks earned.
struct StatsView: View {
    @EnvironmentObject private var services: AppServices
    @State private var stats: Stats = .empty
    @State private var lessonProgress = LessonProgress()

    var body: some View {
        NavigationStack {
            List {
                Section("Lessons") {
                    statRow(icon: "book.fill", title: "Lessons completed",
                            value: "\(lessonProgress.lessonsCompleted) of \(services.course.orderedLessons.count)")
                    statRow(icon: "clock.badge.checkmark", title: "Lessons done (incl. repeats)",
                            value: "\(lessonProgress.totalCompletions)")
                }
                Section("Flashcards") {
                    statRow(icon: "flame.fill", title: "Current streak",
                            value: "\(stats.currentStreakDays) day\(stats.currentStreakDays == 1 ? "" : "s")")
                    statRow(icon: "checkmark.circle.fill", title: "Cards reviewed",
                            value: "\(stats.cardsReviewed)")
                    statRow(icon: "gift.fill", title: "Breaks earned",
                            value: "\(stats.breaksEarned)")
                }
                Section {
                    Text("Every lesson counts. Keep your streak alive and keep earning your scroll time.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Progress")
            .onAppear {
                stats = services.reviewStore.current(now: Date())
                lessonProgress = services.lessonProgressStore.load()
            }
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
