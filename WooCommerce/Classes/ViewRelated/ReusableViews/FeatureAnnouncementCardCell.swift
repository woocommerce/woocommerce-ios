import UIKit

/// UIKit implementation of `FeatureAnnouncementCardView`
///
class FeatureAnnouncementCardCell: UITableViewCell {

    private var viewModel: FeatureAnnouncementCardViewModel?

    @IBOutlet weak var badgeBg: UIView! {
        didSet {
            badgeBg.layer.cornerRadius = BadgeStyle.cornerRadius
            badgeBg.backgroundColor = UIColor.withColorStudio(.wooCommercePurple, shade: .shade0)
        }
    }
    @IBOutlet weak var badgeLabel: UILabel! {
        didSet {
            badgeLabel.textColor = .textBrand
        }
    }

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var ctaButton: UIButton! {
        didSet {
            ctaButton.setTitleColor(UIColor.withColorStudio(.pink), for: .normal)
        }
    }
    @IBOutlet weak var closeButton: UIButton! {
        didSet {
            closeButton.tintColor = UIColor.withColorStudio(.gray)
        }
    }
    @IBOutlet weak var contentImageView: UIImageView!

    @IBOutlet weak var topSeparator: UIView!
    @IBOutlet weak var bottomSeparator: UIView!

    func configure(with viewModel: FeatureAnnouncementCardViewModel) {
        self.viewModel = viewModel

        badgeLabel.text = viewModel.badgeType.title.uppercased()
        titleLabel.text = viewModel.title
        messageLabel.text = viewModel.message
        ctaButton.setTitle(viewModel.buttonTitle, for: .normal)
        contentImageView.image = viewModel.image

        topSeparator.isHidden = !viewModel.showDividers
        bottomSeparator.isHidden = !viewModel.showDividers
    }
}

extension FeatureAnnouncementCardCell {
    enum BadgeStyle {
        static let cornerRadius: CGFloat = 8
    }
}
