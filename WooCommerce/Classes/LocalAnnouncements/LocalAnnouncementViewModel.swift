import Foundation
import UIKit
import Yosemite

/// View model for `LocalAnnouncementModal` view.
final class LocalAnnouncementViewModel {
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
        // TODO: 10021 - analytics
    }

    func trackCtaTapped() {
        // TODO: 10021 - analytics
    }

    func trackDismissTapped() {
        // TODO: 10021 - analytics
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
        switch self {
            case .productDescriptionAI:
                return NSLocalizedString(
                    "Add product description with AI",
                    comment: "Title of the product description AI local announcement."
                )
        }
    }

    var message: String {
        switch self {
            case .productDescriptionAI:
                return NSLocalizedString(
                    "Add descriptions in a snap with AI. Try our feature today!",
                    comment: "Message of the product description AI local announcement."
                )
        }
    }

    var buttonTitle: String? {
        switch self {
            case .productDescriptionAI:
                return NSLocalizedString(
                    "Try it Now",
                    comment: "Button title of the product description AI local announcement."
                )
        }
    }

    var image: UIImage {
        switch self {
            case .productDescriptionAI:
                return .productDescriptionAIAnnouncementImage
        }
    }
}
