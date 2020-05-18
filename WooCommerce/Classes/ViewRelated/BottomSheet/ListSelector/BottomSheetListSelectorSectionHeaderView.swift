import UIKit

/// Renders a section header for the bottom sheet list selector with a main title label.
///
final class BottomSheetListSelectorSectionHeaderView: UITableViewHeaderFooterView {
    @IBOutlet private weak var label: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        configureMainView()
        configureLabel()
    }

    func configure(text: String?) {
        label.text = text
    }
}

private extension BottomSheetListSelectorSectionHeaderView {
    func configureMainView() {
        contentView.backgroundColor = .listForeground
    }

    func configureLabel() {
        label.applySubheadlineStyle()
        label.textColor = .systemColor(.secondaryLabel)
    }
}
