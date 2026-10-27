import UIKit

@MainActor
class LargeImageTableViewCell: UITableViewCell {

    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var textBadge: PaddedLabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // UIKit loads view nibs on the main actor; NSObject's callback is nonisolated.
        MainActor.assumeIsolated { configureAfterNibLoad() }
    }

    private func configureAfterNibLoad() {
        clipsToBounds = true
        mainImageView.contentMode = .scaleAspectFill
        mainImageView.clipsToBounds = false
    }
}
