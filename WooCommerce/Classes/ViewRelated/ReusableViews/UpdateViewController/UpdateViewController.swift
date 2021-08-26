import Foundation
import UIKit

/// A non-dismissable, non-interactive view controller that displays a
/// headline, spinner and footnote. Useful during uniterruptable things
/// like card reader software updates.
///
final class UpdateViewController: UIViewController {
    @IBOutlet private weak var headlineLabel: UILabel!
    @IBOutlet private weak var footnoteLabel: UILabel!

    override func viewDidLoad() {
        view.backgroundColor = .gray(.shade90)
        modalPresentationStyle = .overFullScreen
    }

    func configure(headline: String, footnote: String) {
        headlineLabel?.text = headline
        footnoteLabel?.text = footnote
    }
}
