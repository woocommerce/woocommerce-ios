import SwiftUI

/// Design-system Products list and search cell; the table owns taps and selection.
@MainActor
final class StoreProductListTableViewCell: UITableViewCell {
    private var viewModel: ProductsTabProductViewModel?
    private var showsDivider = true
    private var isChecked: Bool?
    private var isPlaceholder = false
    private(set) var usesSelectedAppearance = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundConfiguration = .clear()
        focusEffect = nil
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var accessibilityTraits: UIAccessibilityTraits {
        get {
            isChecked == true ? super.accessibilityTraits.union(.selected) : super.accessibilityTraits
        }
        set {
            super.accessibilityTraits = newValue
        }
    }

    func configure(viewModel: ProductsTabProductViewModel, showsDivider: Bool, isChecked: Bool?) {
        self.viewModel = viewModel
        self.showsDivider = showsDivider
        self.isChecked = isChecked
        isPlaceholder = false
        isUserInteractionEnabled = true
        accessibilityElementsHidden = false
        accessibilityIdentifier = viewModel.createNameLabel()
        setNeedsUpdateConfiguration()
    }

    func configurePlaceholder() {
        viewModel = nil
        isChecked = nil
        isPlaceholder = true
        isUserInteractionEnabled = false
        accessibilityElementsHidden = true
        accessibilityIdentifier = nil
        setNeedsUpdateConfiguration()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        viewModel = nil
        showsDivider = true
        isChecked = nil
        isPlaceholder = false
        isUserInteractionEnabled = true
        accessibilityElementsHidden = false
        accessibilityIdentifier = nil
        usesSelectedAppearance = false
        contentConfiguration = nil
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        guard viewModel != nil || isPlaceholder else { return }

        usesSelectedAppearance = !isPlaceholder && (state.isSelected || state.isHighlighted)
        contentConfiguration = UIHostingConfiguration { [viewModel, usesSelectedAppearance, isChecked, showsDivider] in
            if let viewModel {
                StoreProductListRow(viewModel: viewModel, isSelected: usesSelectedAppearance, isChecked: isChecked, showsDivider: showsDivider)
            } else {
                StoreProductListSkeletonRow()
            }
        }
        .margins(.all, 0)
    }
}

extension StoreProductListTableViewCell: @MainActor SearchResultCell {
    typealias SearchModel = ProductsTabProductViewModel

    static func register(for tableView: UITableView) {
        tableView.register(self)
    }

    func configureCell(searchModel: ProductsTabProductViewModel) {
        configure(viewModel: searchModel, showsDivider: true, isChecked: nil)
    }
}
