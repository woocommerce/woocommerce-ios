import Foundation
import UIKit

/// A non-dismissable, non-interactive view controller that displays a
/// headline, spinner and footnote. Useful during uniterruptable things
/// like card reader software updates.
///
final class UpdateViewController: UIViewController {
    @IBOutlet private weak var headlineLabel: UILabel!
    @IBOutlet private weak var footnoteLabel: UILabel!

    private var headline: String
    private var footnote: String

    init(headline: String, footnote: String) {
        self.headline = headline
        self.footnote = footnote
        super.init(nibName: Self.nibName, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        headlineLabel?.text = headline
        footnoteLabel?.text = footnote
        view.backgroundColor = .gray(.shade90)
    }
}
