import SwiftUI

/// Home tab, reward-framed: do a lesson, bank a minute, spend it on your apps.
struct TodayView: View {
    @EnvironmentObject private var services: AppServices
    @Binding var showingLesson: Bool
    @Binding var showingReview: Bool

    @State private var bankedMinutes = 0
    @State private var due = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)

                Text(bankedMinutes > 0
                     ? "\(bankedMinutes) minute\(bankedMinutes == 1 ? "" : "s") banked"
                     : "Earn your scroll time")
                    .font(.title.bold())
                Text("Each English lesson you finish banks a minute of time for your blocked apps.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    showingLesson = true
                } label: {
                    Text("Do a lesson · +\(lessonMinutes) min")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)

                if bankedMinutes > 0 {
                    Button {
                        let seconds = services.timeBank.redeemAll()
                        if seconds > 0 {
                            services.blockingController.grantBreak(for: seconds)
                        }
                        refresh()
                    } label: {
                        Text("Unlock my apps · \(bankedMinutes) min")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal)
                }

                if due > 0 {
                    Button("Review \(due) flashcard\(due == 1 ? "" : "s")") {
                        showingReview = true
                    }
                    .font(.callout)
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Today")
            .onAppear(perform: refresh)
            .onChange(of: showingLesson) { _, isShowing in
                if !isShowing { refresh() } // refresh after a lesson
            }
            .onChange(of: showingReview) { _, isShowing in
                if !isShowing { refresh() }
            }
        }
    }

    private var lessonMinutes: Int {
        max(1, Int(services.gateController.policy.timePerLesson / 60))
    }

    private func refresh() {
        bankedMinutes = services.bankedMinutes()
        due = services.dueCount()
    }
}
