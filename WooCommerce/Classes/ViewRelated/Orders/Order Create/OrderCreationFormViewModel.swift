import Foundation

final class OrderCreationFormViewModel {
    private(set) var sections: [Section] = []

    init() {
        setupInitialSectionsForEmptyOrder()
    }
}

private extension OrderCreationFormViewModel {

    func setupInitialSectionsForEmptyOrder() {
        sections = [
            .init(category: .summary, title: nil, rows: [.summary]),
            .init(category: .items, title: Localization.itemsHeader, rows: [.addOrderItem]),
            .init(category: .customerInformation, title: Localization.customerHeader, rows: [.addCustomer]),
            .init(category: .notes, title: Localization.orderNotesHeader, rows: [.addOrderNote])
        ]
    }
}

extension OrderCreationFormViewModel {

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
    }
}

private extension OrderCreationFormViewModel {
    enum Localization {
        static let itemsHeader = NSLocalizedString("Items", comment: "Title for items list header of 'Create Order' screen.")
        static let customerHeader = NSLocalizedString("Customer", comment: "Title for customer info header of 'Create Order' screen.")
        static let orderNotesHeader = NSLocalizedString("Order Notes", comment: "Title for notes list header of 'Create Order' screen.")
    }
}
