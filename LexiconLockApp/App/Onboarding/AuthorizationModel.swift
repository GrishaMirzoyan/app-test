import Foundation
import FamilyControls

/// Wraps FamilyControls individual authorization. v1 uses `.individual`
/// (self-control). A future parent-controlled kids' mode would request
/// `.child` authorization on the parent's device instead — isolated here so the
/// rest of the app doesn't change.
@MainActor
final class AuthorizationModel: ObservableObject {
    @Published private(set) var status: AuthorizationStatus
    @Published var lastError: String?

    private let center = AuthorizationCenter.shared

    init() {
        self.status = center.authorizationStatus
    }

    var isAuthorized: Bool { status == .approved }

    func refresh() {
        status = center.authorizationStatus
    }

    /// Request individual Screen Time authorization. Must be called from the
    /// main app (not an extension). Surfaces errors as reward-neutral copy.
    func requestAuthorization() async {
        do {
            try await center.requestAuthorization(for: .individual)
            status = center.authorizationStatus
            lastError = nil
        } catch {
            lastError = "We couldn’t turn on Screen Time access. You can try again anytime."
        }
    }
}
