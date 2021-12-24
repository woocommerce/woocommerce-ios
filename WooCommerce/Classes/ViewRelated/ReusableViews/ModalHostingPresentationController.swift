import Foundation
import class WordPressUI.FancyAlertPresentationController

/// Subclass of `FancyAlertPresentationController` that manually updates the `presentedView.frame` upon layout changes.
/// This is needed because subclasses of `UIHostingController` are not being updated correctly in events like rotation.
///
final class ModalHostingPresentationController: FancyAlertPresentationController {

    /// Updates the `presentedView.frame` with the `containerView.frame` when the layout changes. EG: Rotation
    ///
    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        guard let presentedView = presentedView, let containerView = containerView else {
            return
        }

        presentedView.frame = containerView.frame
    }
}
