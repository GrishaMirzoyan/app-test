import ManagedSettings
import Foundation

/// Handles taps on the shield's buttons.
///
/// The primary "Learn to unlock" button records a pending-unlock flag in the
/// shared App Group and closes the blocked app, nudging the user back to Lexicon
/// Lock to do their reps. (The system does not let an extension launch the host
/// app directly — see VERIFY.md for the UX validation needed and the option to
/// post a tappable local notification instead.)
final class ShieldActionHandler: ShieldActionDelegate {
    private func handlePrimaryUnlockRequest(_ completionHandler: @escaping (ShieldActionResponse) -> Void) {
        AppGroup.defaults.set(true, forKey: SharedDefaultsKey.pendingUnlock)
        completionHandler(.close)
    }

    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed: handlePrimaryUnlockRequest(completionHandler)
        case .secondaryButtonPressed: completionHandler(.defer)
        @unknown default: completionHandler(.none)
        }
    }

    override func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed: handlePrimaryUnlockRequest(completionHandler)
        case .secondaryButtonPressed: completionHandler(.defer)
        @unknown default: completionHandler(.none)
        }
    }

    override func handle(
        action: ShieldAction,
        for webDomain: WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed: handlePrimaryUnlockRequest(completionHandler)
        case .secondaryButtonPressed: completionHandler(.defer)
        @unknown default: completionHandler(.none)
        }
    }
}
