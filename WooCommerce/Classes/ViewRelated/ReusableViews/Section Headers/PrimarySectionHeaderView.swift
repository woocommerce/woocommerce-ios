
import Foundation
import UIKit

/// A section header with a headline-style title and a white background.
///
/// This is originally used for the Order Details' Product section header.
///
final class PrimarySectionHeaderView: UITableViewHeaderFooterView {

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var containerView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()

        titleLabel.text = ""
        titleLabel.applyHeadlineStyle()

        containerView.backgroundColor = .basicBackground
    }

    /// Change the configurable properties of this header.
    ///
    func configure(title: String?) {
        titleLabel.text = title
    }
}
