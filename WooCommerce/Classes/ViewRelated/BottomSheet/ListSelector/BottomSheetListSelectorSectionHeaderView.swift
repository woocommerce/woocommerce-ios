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

    func configure(title: String?, subtitle: String?) {
        self.title.text = title
        self.subtitle.text = subtitle
    }
}

private extension BottomSheetListSelectorSectionHeaderView {
    func configureMainView() {
        contentView.backgroundColor = .listForeground(modal: false)
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
