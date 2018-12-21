import Foundation
import UIKit
import WordPressUI


/// Helper that makes sharing on iOS slightly easier
///
class SharingHelper {

    /// Private: NO-OP
    ///
    private init() { }


    /// Share a URL using the iOS share sheet
    ///
    /// - Parameters:
    ///   - url: URL you want to share
    ///   - title: Optional descriptive title for the url
    ///   - anchorView: View that the share popover should be displayed from (needed for iPad support)
    ///   - viewController: VC presenting the share VC (UIActivityViewController)
    ///
    static func shareURL(url: URL, title: String? = nil, from anchorView: UIView, in viewController: UIViewController) {
        guard let avc = createActivityVC(title: title, url: url) else {
            return
        }

        if UIDevice.isPad() {
            // Use a popover for iPads
            avc.modalPresentationStyle = .popover
            viewController.present(avc, animated: true)

            if let presentationController = avc.popoverPresentationController {
                presentationController.permittedArrowDirections = .any
                presentationController.sourceView = anchorView
                presentationController.sourceRect = anchorView.bounds
            }
            return
        }

        viewController.present(avc, animated: true)
    }
}


// MARK: - Private Helpers
//
private extension SharingHelper {

    static func createActivityVC(title: String? = nil, url: URL? = nil) -> UIActivityViewController? {
        guard (title != nil || url != nil) else {
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

        return UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
}
