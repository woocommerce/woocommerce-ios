import UIKit

protocol CardPresentModalProgressDisplaying: CardPresentPaymentsModalViewModel {
    var progress: Float { get }
}

extension CardPresentModalProgressDisplaying {
    var image: UIImage {
        .softwareUpdateProgress(progress: CGFloat(progress))
    }

    var bottomTitle: String? {
        String(format: CardPresentModalProgressDisplayingLocalization.percentComplete, 100 * progress)
    }
}

fileprivate enum CardPresentModalProgressDisplayingLocalization {
    static let percentComplete = NSLocalizedString(
        "%.0f%% complete",
        comment: "Label that describes the completed progress of an update being installed (e.g. 15% complete). Keep the %.0f%% exactly as is"
    )
}
