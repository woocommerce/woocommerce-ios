import Foundation
import UIKit
import Yosemite
import protocol WooFoundation.Analytics

/// View model for `LocalAnnouncementModal` view.
final class LocalAnnouncementViewModel {
    // Set externally when the modal is being shown.
    var actionTapped: (_ announcement: LocalAnnouncement) -> Void = { _ in }

    let title: String
    let message: String
    let buttonTitle: String?
    let dismissButtonTitle: String = Localization.dismissButtonTitle
    let image: UIImage

    private let announcement: LocalAnnouncement
    private let analytics: Analytics
    private let stores: StoresManager

    init(announcement: LocalAnnouncement,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.title = announcement.title
        self.message = announcement.message
        self.buttonTitle = announcement.buttonTitle
        self.image = announcement.image
        self.announcement = announcement
        self.analytics = analytics
        self.stores = stores
    }

    func onAppear() {
        trackAnnouncementDisplayed()
    }

    // MARK: - Actions

    func ctaTapped() {
        actionTapped(announcement)
        trackCtaTapped()
        Task { @MainActor in
            await markAnnouncementAsDismissed()
        }
    }

    func dismissTapped() {
        trackDismissTapped()
        Task { @MainActor in
            await markAnnouncementAsDismissed()
        }
    }
}

// MARK: - Analytics
//
private extension LocalAnnouncementViewModel {
    func trackAnnouncementDisplayed() {
        analytics.track(event: .LocalAnnouncementModal.localAnnouncementDisplayed(announcement: announcement))
    }

    func trackCtaTapped() {
        analytics.track(event: .LocalAnnouncementModal.localAnnouncementCallToActionTapped(announcement: announcement))
    }

    func trackDismissTapped() {
        analytics.track(event: .LocalAnnouncementModal.localAnnouncementDismissTapped(announcement: announcement))
    }
}

private extension LocalAnnouncementViewModel {
    @MainActor
    func markAnnouncementAsDismissed() async {
        await withCheckedContinuation { continuation in
            stores.dispatch(AppSettingsAction.setLocalAnnouncementDismissed(announcement: announcement) { result in
                continuation.resume(returning: ())
            })
        }
    }
}

private extension LocalAnnouncementViewModel {
    enum Localization {
        static let dismissButtonTitle = NSLocalizedString(
            "Maybe Later",
            comment: "Dismiss button title for the local announcement modal."
        )
    }
}

private extension LocalAnnouncement {
    var title: String {
        "" // TODO: edit when needed
    }

    var message: String {
        "" // TODO: edit when needed
    }

    var buttonTitle: String? {
        nil // TODO: edit when needed
    }

    var image: UIImage {
        .emptyBoxImage // TODO: edit when needed
    }
}
