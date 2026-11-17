import SwiftUI

@MainActor
final class StoreOrderListTableViewCell: UITableViewCell {
    private var viewModel: OrderListCellViewModel?
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

    func configure(viewModel: OrderListCellViewModel?) {
        self.viewModel = viewModel
        accessibilityIdentifier = viewModel?.title
        setNeedsUpdateConfiguration()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        viewModel = nil
        accessibilityIdentifier = nil
        usesSelectedAppearance = false
        contentConfiguration = nil
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        guard let viewModel else { return }

        usesSelectedAppearance = state.isSelected || state.isHighlighted
        contentConfiguration = UIHostingConfiguration {
            StoreOrderListRow(viewModel: viewModel, isSelected: usesSelectedAppearance)
        }
        .margins(.all, 0)
    }
}

extension StoreOrderListTableViewCell: @MainActor SearchResultCell {
    typealias SearchModel = OrderListCellViewModel

    static func register(for tableView: UITableView) {
        tableView.register(self)
    }

    func configureCell(searchModel: OrderListCellViewModel) {
        configure(viewModel: searchModel)
    }
}
