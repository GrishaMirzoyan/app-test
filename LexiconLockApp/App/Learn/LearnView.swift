import SwiftUI
import LearningGateCore

/// The course path: units → lessons, unlocked in order. Each completed lesson
/// banks `timePerLesson` of app time; the header shows the spendable balance.
struct LearnView: View {
    @EnvironmentObject private var services: AppServices
    @State private var progress = LessonProgress()
    @State private var activeLesson: Lesson?
    @State private var bankedMinutes = 0

    var body: some View {
        NavigationStack {
            List {
                bankHeader

                ForEach(services.course.units) { unit in
                    Section(unit.title) {
                        ForEach(unit.lessons) { lesson in
                            lessonRow(lesson)
                        }
                    }
                }
            }
            .navigationTitle(services.course.title)
            .onAppear(perform: refresh)
            .sheet(item: $activeLesson, onDismiss: refresh) { lesson in
                LessonView(lesson: lesson, services: services)
            }
        }
    }

    private var bankHeader: some View {
        Section {
            HStack {
                Label("Banked app time", systemImage: "clock.badge.checkmark")
                Spacer()
                Text("\(bankedMinutes) min")
                    .font(.headline).foregroundStyle(.tint)
            }
            if bankedMinutes > 0 {
                Button {
                    let seconds = services.timeBank.redeemAll()
                    if seconds > 0 {
                        services.blockingController.grantBreak(for: seconds)
                    }
                    refresh()
                } label: {
                    Label("Unlock my apps · \(bankedMinutes) min", systemImage: "lock.open")
                }
            } else {
                Text("Finish a lesson to earn a minute of app time.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func lessonRow(_ lesson: Lesson) -> some View {
        let unlocked = services.course.isUnlocked(lesson.id, progress: progress)
        let completions = progress.completions(of: lesson.id)

        Button {
            activeLesson = lesson
        } label: {
            HStack(spacing: 12) {
                Text(lesson.icon).font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(lesson.title)
                        .foregroundStyle(unlocked ? .primary : .secondary)
                    if completions > 0 {
                        Text("Completed \(completions)×")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if !unlocked {
                    Image(systemName: "lock.fill").foregroundStyle(.tertiary)
                } else if completions > 0 {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                } else {
                    Image(systemName: "play.circle.fill").foregroundStyle(.tint)
                }
            }
        }
        .disabled(!unlocked)
    }

    private func refresh() {
        progress = services.lessonProgressStore.load()
        bankedMinutes = Int(services.timeBank.balance / 60)
    }
}
