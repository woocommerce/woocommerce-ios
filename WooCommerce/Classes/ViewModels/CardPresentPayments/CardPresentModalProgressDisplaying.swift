import UIKit

protocol CardPresentModalProgressDisplaying: CardPresentPaymentsModalViewModel {
    var progress: Float { get }
    var isComplete: Bool { get }
    var titleComplete: String { get }
    var titleInProgress: String { get }
    var messageComplete: String? { get }
    var messageInProgress: String? { get }
}

extension CardPresentModalProgressDisplaying {
    var image: UIImage {
        .softwareUpdateProgress(progress: CGFloat(progress))
    }

    var isComplete: Bool {
        progress == 1
    }

    var topTitle: String {
        isComplete ? titleComplete : titleInProgress
    }

    var bottomTitle: String? {
        String(format: CardPresentModalProgressDisplayingLocalization.percentComplete, 100 * progress)
    }

    var bottomSubtitle: String? {
        isComplete ? messageComplete : messageInProgress
    }
}

fileprivate enum CardPresentModalProgressDisplayingLocalization {
    static let percentComplete = NSLocalizedString(
        "%.0f%% complete",
        comment: "Label that describes the completed progress of an update being installed (e.g. 15% complete). Keep the %.0f%% exactly as is"
    )
}
