import SwiftUI
import LearningGateCore

/// The review screen shown when the user chooses to earn a break.
///
/// The presenter passes `AppServices` so the view model can be built at init and
/// owned with `@StateObject` (its `@Published` changes then drive the UI).
struct ReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model: ReviewViewModel

    init(services: AppServices) {
        _model = StateObject(wrappedValue: ReviewViewModel(
            cardStore: services.cardStore,
            gateController: services.gateController,
            recorder: services.reviewStore,
            blockingController: services.blockingController
        ))
    }

    var body: some View {
        NavigationStack {
            content
                .padding()
                .navigationTitle("Earn a break")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.phase {
        case .nothingDue:
            message(title: "You’re all caught up!",
                    body: "Nothing’s due right now — enjoy your time.",
                    systemImage: "checkmark.seal")
        case .earned(let minutes):
            message(title: "Break earned 🎉",
                    body: "Nice work. Enjoy \(minutes) minute\(minutes == 1 ? "" : "s").",
                    systemImage: "party.popper")
        case .reviewing:
            reviewing
        }
    }

    private var reviewing: some View {
        VStack(spacing: 24) {
            ProgressView(value: Double(model.passed), total: Double(max(model.required, 1)))
            Text("\(model.passed) of \(model.required) cards recalled")
                .font(.caption).foregroundStyle(.secondary)

            Spacer()
            cardFace
            Spacer()

            if model.showingBack {
                gradeButtons
            } else {
                Button {
                    model.reveal()
                } label: {
                    Text("Show answer").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var cardFace: some View {
        VStack(spacing: 16) {
            Text(model.front).font(.title2.bold()).multilineTextAlignment(.center)
            if model.showingBack {
                Divider()
                Text(model.back).font(.title3).multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var gradeButtons: some View {
        HStack(spacing: 8) {
            gradeButton("Again", .again)
            gradeButton("Hard", .hard)
            gradeButton("Good", .good)
            gradeButton("Easy", .easy)
        }
    }

    private func gradeButton(_ title: String, _ grade: ReviewGrade) -> some View {
        Button(title) { model.grade(grade) }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
    }

    private func message(title: String, body: String, systemImage: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage).font(.system(size: 56)).foregroundStyle(.tint)
            Text(title).font(.title2.bold())
            Text(body).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button("Done") { dismiss() }.buttonStyle(.borderedProminent)
        }
    }
}
