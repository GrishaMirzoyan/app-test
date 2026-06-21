import SwiftUI

/// Switches between onboarding and the main tabbed UI, and reacts to the Shield
/// Action extension's "pending unlock" flag by opening the review flow.
struct RootView: View {
    @EnvironmentObject private var services: AppServices
    @StateObject private var auth = AuthorizationModel()
    @Environment(\.scenePhase) private var scenePhase

    @State private var needsOnboarding = true
    @State private var showingReview = false

    var body: some View {
        Group {
            if needsOnboarding {
                OnboardingView { needsOnboarding = false }
            } else {
                MainTabView(showingReview: $showingReview)
            }
        }
        .onAppear(perform: refreshState)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refreshState() }
        }
        .sheet(isPresented: $showingReview) {
            ReviewView(services: services)
        }
    }

    private func refreshState() {
        auth.refresh()
        needsOnboarding = !(auth.isAuthorized && services.selectionStore.hasSelection)

        // The shield's "Learn to unlock" button sets this flag; honor it.
        if AppGroup.defaults.bool(forKey: SharedDefaultsKey.pendingUnlock) {
            AppGroup.defaults.set(false, forKey: SharedDefaultsKey.pendingUnlock)
            if !needsOnboarding { showingReview = true }
        }
    }
}

/// Main tabs: Today (review CTA), Decks, Stats.
struct MainTabView: View {
    @EnvironmentObject private var services: AppServices
    @Binding var showingReview: Bool

    var body: some View {
        TabView {
            TodayView(showingReview: $showingReview)
                .tabItem { Label("Today", systemImage: "sun.max") }
            DeckListView()
                .tabItem { Label("Decks", systemImage: "rectangle.stack") }
            StatsView()
                .tabItem { Label("Progress", systemImage: "chart.bar") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
