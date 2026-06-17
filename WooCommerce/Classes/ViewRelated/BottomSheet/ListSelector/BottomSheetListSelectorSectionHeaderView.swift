import UIKit

/// Renders a section header for the bottom sheet list selector with a main title label.
///
final class BottomSheetListSelectorSectionHeaderView: UITableViewHeaderFooterView {
    @IBOutlet private weak var title: UILabel!
    @IBOutlet private weak var subtitle: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        configureMainView()
        configureTitle()
        configureSubtitle()
    }

    func configure(title: String?, subtitle: String?, backgroundColor: UIColor = .listForeground(modal: false)) {
        self.title.text = title
        self.title.numberOfLines = 0
        self.subtitle.text = subtitle
        self.subtitle.numberOfLines = 0
        configureMainView(backgroundColor: backgroundColor)
    }
}

private extension BottomSheetListSelectorSectionHeaderView {
    func configureMainView(backgroundColor: UIColor = .listForeground(modal: false)) {
        self.backgroundColor = backgroundColor
        contentView.backgroundColor = backgroundColor

        var backgroundConfiguration = UIBackgroundConfiguration.listPlainHeaderFooter()
        backgroundConfiguration.backgroundColor = backgroundColor
        self.backgroundConfiguration = backgroundConfiguration
    }

    func configureTitle() {
        title.applyHeadlineStyle()
        title.textColor = .systemColor(.label)
    }

    func configureSubtitle() {
        subtitle.applySubheadlineStyle()
        subtitle.textColor = .systemColor(.secondaryLabel)
    }
}
