import Foundation
import UIKit
import Yosemite

/// Type to encapsulate the options presented when generating variations.
///
final class GenerateVariationsOptionsPresenter {
    /// Options available when generating variations
    ///
    enum Option {
        case single
        case all
    }

    /// Base view controller where the loading indicators and notices will be presented.
    ///
    private let baseViewController: UIViewController

    /// Analytics tracker.
    ///
    private let analytics: Analytics

    init(baseViewController: UIViewController, analytics: Analytics = ServiceLocator.analytics) {
        self.baseViewController = baseViewController
        self.analytics = analytics
    }

    /// Displays a bottom sheet allowing the merchant to choose whether to generate one variation or to generate all variations.
    ///
    func presentGenerationOptions(sourceView: UIView, onCompletion: @escaping (_ selectedOption: Option) -> Void) {
        let viewProperties = BottomSheetListSelectorViewProperties(title: Localization.addVariationAction)
        let command = GenerateVariationsSelectorCommand(selected: nil) { [analytics, baseViewController] option in
            baseViewController.dismiss(animated: true)
            switch option {
            case .single:
                onCompletion(.single)
            case .all:
                onCompletion(.all)
                analytics.track(event: .Variations.productVariationGenerationRequested())
            }
        }
        let bottomSheetPresenter = BottomSheetListSelectorPresenter(viewProperties: viewProperties, command: command)
        bottomSheetPresenter.show(from: baseViewController, sourceView: sourceView)
    }
}

// MARK: Localization
//
private extension GenerateVariationsOptionsPresenter {
    enum Localization {
        static let addVariationAction = NSLocalizedString("Add Variation",
                                                          comment: "Title on the bottom sheet to choose what variation process to start")
    }
}
