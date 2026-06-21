import SwiftUI
import FamilyControls

/// First-run flow: explain the reward framing, request Screen Time access, then
/// let the user pick which apps to put behind the learning gate.
struct OnboardingView: View {
    @EnvironmentObject private var services: AppServices
    @StateObject private var auth = AuthorizationModel()
    @State private var selection = FamilyActivitySelection()
    @State private var showingPicker = false
    let onComplete: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    if !auth.isAuthorized {
                        authStep
                    } else {
                        pickStep
                    }

                    if let error = auth.lastError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Welcome")
            .familyActivityPicker(isPresented: $showingPicker, selection: $selection)
            .onChange(of: selection) { _, newValue in
                services.selectionStore.save(newValue)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Earn your scroll time")
                .font(.largeTitle.bold())
            Text("Do a few quick flashcard reps to unlock the apps you choose. "
                 + "It’s a reward, not a restriction.")
                .foregroundStyle(.secondary)
        }
    }

    private var authStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Turn on Screen Time access", systemImage: "lock.shield")
                .font(.headline)
            Text("This lets Lexicon Lock place a friendly gate on the apps you pick. "
                 + "Your app choices stay private on your device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                Task { await auth.requestAuthorization() }
            } label: {
                Text("Enable Screen Time").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var pickStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Choose apps to gate", systemImage: "square.grid.2x2")
                .font(.headline)
            Text("Pick the apps or categories you’d like to earn time on.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                showingPicker = true
            } label: {
                Text(services.selectionStore.hasSelection ? "Edit selection" : "Pick apps")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button {
                services.blockingController.applyShield()
                onComplete()
            } label: {
                Text("Start earning breaks").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!services.selectionStore.hasSelection)
        }
    }
}
