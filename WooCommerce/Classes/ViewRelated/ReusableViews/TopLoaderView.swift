import UIKit

/// A view with a loader on the left side, and a text on the right, useful for showing that there is some content that is still loading.
/// Used on top of the Order Detail screen.
///
final class TopLoaderView: UIView {

    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var body: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        customizeView()
        customizeIndicator()
        customizeLabels()
    }

    func setBody(_ text: String) {
        self.body.text = text
    }
}

private extension TopLoaderView {
    func customizeView() {
        backgroundColor = .black
    }

    func customizeIndicator() {
        activityIndicator.startAnimating()
        activityIndicator.color = .white
    }

    func customizeLabels() {
        body.applySubheadlineStyle()
        body.textColor = .white
    }
}
