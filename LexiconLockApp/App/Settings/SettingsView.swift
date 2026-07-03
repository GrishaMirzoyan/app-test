import SwiftUI
import FamilyControls
import LearningGateCore

/// Lets the (self-controlling) user tune the gate: how many cards (N) earn how
/// long a break (X), and which apps are gated. In a future parent-controlled
/// mode `gateController.canCurrentUserEditPolicy` would be false and these
/// controls would be hidden/locked behind a passcode.
struct SettingsView: View {
    @EnvironmentObject private var services: AppServices
    @State private var selection = FamilyActivitySelection()
    @State private var showingPicker = false

    @State private var cardsToUnlock = 5
    @State private var breakMinutes = 10
    @State private var minutesPerLesson = 1
    @State private var canEdit = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Lessons") {
                    Stepper("Minutes earned per lesson: \(minutesPerLesson)",
                            value: $minutesPerLesson, in: 1...10)
                        .disabled(!canEdit)
                }

                Section("Flashcard gate") {
                    Stepper("Cards to unlock: \(cardsToUnlock)",
                            value: $cardsToUnlock, in: 1...20)
                        .disabled(!canEdit)
                    Stepper("Break length: \(breakMinutes) min",
                            value: $breakMinutes, in: 1...120, step: 1)
                        .disabled(!canEdit)
                }

                Section("Gated apps") {
                    Button("Edit app selection") { showingPicker = true }
                    Button("Re-apply gate now") {
                        services.blockingController.applyShield()
                    }
                }

                if !canEdit {
                    Section {
                        Label("These settings are managed for you.",
                              systemImage: "lock.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .familyActivityPicker(isPresented: $showingPicker, selection: $selection)
            .onChange(of: selection) { _, newValue in
                services.selectionStore.save(newValue)
            }
            .onChange(of: cardsToUnlock) { _, _ in savePolicy() }
            .onChange(of: breakMinutes) { _, _ in savePolicy() }
            .onChange(of: minutesPerLesson) { _, _ in savePolicy() }
            .onAppear(perform: load)
        }
    }

    private func load() {
        let policy = services.gateController.policy
        cardsToUnlock = policy.cardsToUnlock
        breakMinutes = max(1, Int(policy.breakDuration / 60))
        minutesPerLesson = max(1, Int(policy.timePerLesson / 60))
        canEdit = services.gateController.canCurrentUserEditPolicy
        selection = services.selectionStore.load() ?? FamilyActivitySelection()
    }

    private func savePolicy() {
        guard canEdit else { return }
        let policy = GatePolicy(
            cardsToUnlock: cardsToUnlock,
            breakDuration: TimeInterval(breakMinutes * 60),
            passThreshold: services.gateController.policy.passThreshold,
            timePerLesson: TimeInterval(minutesPerLesson * 60)
        )
        try? services.gateController.updatePolicy(policy)
    }
}
