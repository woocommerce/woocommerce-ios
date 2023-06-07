import Foundation
import UIKit
import WordPressUI


/// Helper that makes sharing on iOS slightly easier
///
class SharingHelper {

    typealias Completion = (UIActivity.ActivityType?, Bool, [Any]?, Error?) -> Void

    /// Private: NO-OP
    ///
    private init() { }

    /// Share a message using the iOS share sheet
    ///
    /// - Parameters:
    ///   - message: Optional descriptive title for the url
    ///   - anchorView: View that the share popover should be displayed from (needed for iPad support)
    ///   - viewController: VC presenting the share VC (UIActivityViewController)
    ///   - onCompletion: The completion handler to execute after the activity view controller is dismissed.
    ///
    static func shareMessage(_ message: String,
                             from anchorView: UIView,
                             in viewController: UIViewController,
                             onCompletion: Completion? = nil) {
        guard let avc = createActivityVC(title: message, url: nil, onCompletion: onCompletion) else {
            return
        }

        avc.setupPopoverForIPadsIfNecessary(with: anchorView)
        viewController.present(avc, animated: true)
    }

    /// Share a URL using the iOS share sheet.
    ///
    /// - Parameters:
    ///   - url: URL you want to share.
    ///   - title: Optional descriptive title for the url.
    ///   - item: Item that the share action sheet should be displayed from.
    ///   - viewController: VC presenting the share VC (UIActivityViewController).
    ///
    static func shareMessage(_ message: String,
                             from item: UIBarButtonItem,
                             in viewController: UIViewController,
                             onCompletion: Completion? = nil) {
        guard let avc = createActivityVC(title: message, url: nil, onCompletion: onCompletion) else {
            return
        }

        let popoverController = avc.popoverPresentationController
        popoverController?.barButtonItem = item
        viewController.present(avc, animated: true)
    }

    /// Share a URL using the iOS share sheet
    ///
    /// - Parameters:
    ///   - url: URL you want to share
    ///   - title: Optional descriptive title for the url
    ///   - anchorView: View that the share popover should be displayed from (needed for iPad support)
    ///   - viewController: VC presenting the share VC (UIActivityViewController)
    ///
    static func shareURL(url: URL,
                         title: String? = nil,
                         from anchorView: UIView,
                         in viewController: UIViewController,
                         onCompletion: Completion? = nil) {
        guard let avc = createActivityVC(title: title, url: url, onCompletion: onCompletion) else {
            return
        }

        avc.setupPopoverForIPadsIfNecessary(with: anchorView)
        viewController.present(avc, animated: true)
    }

    /// Share a URL using the iOS share sheet.
    ///
    /// - Parameters:
    ///   - url: URL you want to share.
    ///   - title: Optional descriptive title for the url.
    ///   - item: Item that the share action sheet should be displayed from.
    ///   - viewController: VC presenting the share VC (UIActivityViewController).
    ///
    static func shareURL(url: URL,
                         title: String? = nil,
                         from item: UIBarButtonItem,
                         in viewController: UIViewController,
                         onCompletion: Completion? = nil) {
        guard let avc = createActivityVC(title: title, url: url, onCompletion: onCompletion) else {
            return
        }

        let popoverController = avc.popoverPresentationController
        popoverController?.barButtonItem = item
        viewController.present(avc, animated: true)
    }

    /// List all activity types.
    /// UIActivity.ActivityType is not CaseIterable. :sadface:
    ///
    static func allActivityTypes() -> [UIActivity.ActivityType] {
        return [.postToFacebook,
                .postToTwitter,
                .postToWeibo,
                .message,
                .mail,
                .print,
                .copyToPasteboard,
                .assignToContact,
                .saveToCameraRoll,
                .addToReadingList,
                .postToFlickr,
                .postToVimeo,
                .postToTencentWeibo,
                .airDrop,
                .openInIBooks,
                .markupAsPDF]
    }
}


// MARK: - Private Helpers
//
private extension SharingHelper {

    static func createActivityVC(title: String? = nil, url: URL? = nil, onCompletion: Completion?) -> UIActivityViewController? {
        guard title != nil || url != nil else {
            DDLogWarn("⚠ Cannot create sharing activity — both title AND URL are nil.")
            return nil
        }

        var items: [Any] = []
        if let title = title {
            items.append(title)
        }

        if let url = url {
            items.append(url)
        }

        let activityController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityController.completionWithItemsHandler = onCompletion
        return activityController
    }
}

extension UIActivityViewController {
    /// Update the controller with the provided source view.
    ///
    func setupPopoverForIPadsIfNecessary(with anchorView: UIView) {
        guard UIDevice.isPad() else {
            return
        }
        // Use a popover for iPads
        modalPresentationStyle = .popover

        if let presentationController = popoverPresentationController {
            presentationController.permittedArrowDirections = .any
            presentationController.sourceView = anchorView
            presentationController.sourceRect = anchorView.bounds
        }
    }
}
