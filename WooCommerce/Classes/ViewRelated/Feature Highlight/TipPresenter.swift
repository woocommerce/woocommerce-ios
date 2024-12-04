import TipKit
import SwiftUI

/// Small helper protocol for a tip that is available below iOS 17
/// so that we can pass tips around and have members storing tips,
/// as stored properties can't be marked with `@available`.
/// See: https://stackoverflow.com/a/77858436
@available(iOS, obsoleted: 17, message: "Can be removed once we only support iOS 17+")
public protocol TipShim {

    @available(iOS 17, *)
    var tip: AnyTip { get }

}

@available(iOS 17, *)
public extension Tip where Self: TipShim {

    var tip: AnyTip { AnyTip(self) }

}

/// Helper used for presentation of a TipKit tip on a UIKit view.
/// Note that the tip will only be displayed on iOS 17+ (required for TipKit support).
final class TipPresenter {
    private var tip: TipShim
    private weak var tipPopoverController: UIViewController?
    private var tipObservationTask: Task<Void, Never>?

    init(tip: TipShim) {
        self.tip = tip
    }

    func displayTip(_ animated: Bool, on sourceItem: any UIPopoverPresentationControllerSourceItem, view: UIViewController) {
        guard #available(iOS 17.0, *) else {
            return
        }
        tipObservationTask = tipObservationTask ?? Task { @MainActor in
            for await shouldDisplay in tip.tip.shouldDisplayUpdates {
                if shouldDisplay {
                    let popoverController = TipUIPopoverViewController(tip.tip, sourceItem: sourceItem)
                    popoverController.viewStyle = InvertedTipStyle(showCloseButton: false)
                    popoverController.popoverPresentationController?.permittedArrowDirections = .up
                    view.present(popoverController, animated: animated)
                    tipPopoverController = popoverController
                }
                else {
                    if view.presentedViewController is TipUIPopoverViewController {
                        view.dismiss(animated: animated) { [weak self] in
                            self?.tipPopoverController = nil
                        }
                    }
                }
            }
        }
    }

    func dismissTip() {
        tipObservationTask?.cancel()
        tipObservationTask = nil
    }
}
