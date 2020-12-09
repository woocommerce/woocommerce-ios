import UIKit

final class OrderCreationFormDataSource: NSObject {
    private(set) var sections: [Section] = []

    override init() {
        super.init()
        sections = [
            Section(category: .summary, title: nil, rows: [.summary]),
            Section(category: .items, title: Localization.itemsHeader, rows: [.addOrderItem]),
            Section(category: .customerInformation, title: Localization.customerHeader, rows: [.addCustomer]),
            Section(category: .notes, title: Localization.orderNotesHeader, rows: [.addOrderNote])
        ]
    }

    func registerTableViewCells(_ tableView: UITableView) {
        for row in Row.allCases {
            tableView.registerNib(for: row.type)
        }

        let headerType = TwoColumnSectionHeaderView.self
        tableView.register(headerType.loadNib(), forHeaderFooterViewReuseIdentifier: headerType.reuseIdentifier)
    }
}

extension OrderCreationFormDataSource: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]
        let reuseIdentifier = section.rows[indexPath.row].reuseIdentifier
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        configure(cell, section: section, indexPath: indexPath)
        return cell
    }

    func heightForHeaderInSection(_ section: Int, tableView: UITableView) -> CGFloat {
        // Hide header for summary
        if sections[section].category == .summary {
            return CGFloat.leastNormalMagnitude
        }

        return UITableView.automaticDimension
    }

    func viewForHeaderInSection(_ section: Int, tableView: UITableView) -> UIView? {
        let reuseIdentifier = TwoColumnSectionHeaderView.reuseIdentifier
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: reuseIdentifier) as? TwoColumnSectionHeaderView else {
            return nil
        }

        header.leftText = sections[section].title
        header.rightText = nil

        return header
    }
}

extension OrderCreationFormDataSource {

    struct Section {
        enum Category {
            case summary
            case items
            case customerInformation
            case notes
        }

        let category: Category
        let title: String?
        let rows: [Row]
    }

    /// Rows listed in the order they appear on screen
    ///
    enum Row: CaseIterable {
        case summary
        case addOrderItem
        case addCustomer
        case addOrderNote

        var type: UITableViewCell.Type {
            switch self {
            case .summary:
                return SummaryTableViewCell.self
            case .addOrderItem, .addCustomer, .addOrderNote:
                return LeftImageTableViewCell.self
            }
        }

        var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}

private extension OrderCreationFormDataSource {
    func configure(_ cell: UITableViewCell, section: Section, indexPath: IndexPath) {
        let row = section.rows[indexPath.row]
        switch cell {
        case let cell as SummaryTableViewCell:
            configureSummary(cell: cell)
        case let cell as LeftImageTableViewCell where row == .addOrderItem:
            configureAddItem(cell: cell)
        case let cell as LeftImageTableViewCell where row == .addCustomer:
            configureAddCustomer(cell: cell)
        case let cell as LeftImageTableViewCell where row == .addOrderNote:
            configureAddNote(cell: cell)
        default:
            fatalError("Unknown cell in Order Creation Form")
        }
    }


    func configureSummary(cell: SummaryTableViewCell) {
        // TODO: add 'new draft' state
    }

    func configureAddItem(cell: LeftImageTableViewCell) {
        cell.leftImage = Icons.addItemIcon
        cell.imageView?.tintColor = .accent
        cell.textLabel?.textColor = .accent
        cell.labelText = Localization.addItemsTitle

        cell.accessibilityTraits = .button
        cell.accessibilityLabel = Localization.addItemsAccessibilityLabel
        cell.accessibilityHint = Localization.addItemsAccessibilityHint
    }

    func configureAddCustomer(cell: LeftImageTableViewCell) {
        cell.leftImage = Icons.addItemIcon
        cell.imageView?.tintColor = .accent
        cell.textLabel?.textColor = .accent
        cell.labelText = Localization.addCustomerTitle

        cell.accessibilityTraits = .button
        cell.accessibilityLabel = Localization.addCustomerAccessibilityLabel
        cell.accessibilityHint = Localization.addCustomerAccessibilityHint
    }

    func configureAddNote(cell: LeftImageTableViewCell) {
        cell.leftImage = Icons.addItemIcon
        cell.imageView?.tintColor = .accent
        cell.textLabel?.textColor = .accent
        cell.labelText = Localization.addNoteTitle

        cell.accessibilityTraits = .button
        cell.accessibilityLabel = Localization.addNoteAccessibilityLabel
        cell.accessibilityHint = Localization.addNoteAccessibilityHint
    }
}

private extension OrderCreationFormDataSource {
    enum Icons {
        static let addItemIcon = UIImage.plusImage
    }

    enum Localization {
        static let itemsHeader = NSLocalizedString("Items", comment: "Title for items list header of 'Create Order' screen.")
        static let customerHeader = NSLocalizedString("Customer", comment: "Title for customer info header of 'Create Order' screen.")
        static let orderNotesHeader = NSLocalizedString("Order Notes", comment: "Title for notes list header of 'Create Order' screen.")

        static let addItemsTitle = NSLocalizedString("Add Items", comment: "Button text for adding a new item on 'Create Order' screen.")
        static let addItemsAccessibilityLabel = NSLocalizedString("Add Items", comment: "Accessibility label for the 'Add Items' button.")
        static let addItemsAccessibilityHint = NSLocalizedString(
            "Adds a new product or custom item into the order.",
            comment: "VoiceOver accessibility hint, informing the user that the button can be used to add a product or create custom item."
        )

        static let addCustomerTitle = NSLocalizedString("Add Customer", comment: "Button text for adding a customer on 'Create Order' screen.")
        static let addCustomerAccessibilityLabel = NSLocalizedString("Add Customer", comment: "Accessibility label for the 'Add Customer' button.")
        static let addCustomerAccessibilityHint = NSLocalizedString(
            "Adds a customer into the order.",
            comment: "VoiceOver accessibility hint, informing the user that the button can be used to add a customer."
        )

        static let addNoteTitle = NSLocalizedString("Add Note", comment: "Button text for adding a new note on 'Create Order' screen.")
        static let addNoteAccessibilityLabel = NSLocalizedString("Add Note", comment: "Accessibility label for the 'Add Note' button.")
        static let addNoteAccessibilityHint = NSLocalizedString(
            "Composes a new order note.",
            comment: "VoiceOver accessibility hint, informing the user that the button can be used to create a new order note."
        )
    }
}
