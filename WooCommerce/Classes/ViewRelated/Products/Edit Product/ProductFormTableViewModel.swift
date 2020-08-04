import UIKit
import Yosemite

enum ProductFormSection: Equatable {
    case primaryFields(rows: [PrimaryFieldRow])
    case settings(rows: [SettingsRow])

    var isNotEmpty: Bool {
        switch self {
        case .primaryFields(let rows):
            return rows.isNotEmpty
        case .settings(let rows):
            return rows.isNotEmpty
        }
    }

    enum PrimaryFieldRow: Equatable {
        case images
        case name(name: String?, isEditable: Bool)
        case description(description: String?)
    }

    enum SettingsRow: Equatable {
        case price(viewModel: ViewModel)
        case shipping(viewModel: ViewModel)
        case inventory(viewModel: ViewModel)
        case categories(viewModel: ViewModel)
        case tags(viewModel: ViewModel)
        case briefDescription(viewModel: ViewModel)
        case externalURL(viewModel: ViewModel)
        case sku(viewModel: ViewModel)
        case groupedProducts(viewModel: ViewModel)
        case variations(viewModel: ViewModel)

        struct ViewModel {
            let icon: UIImage
            let title: String?
            let details: String?
            let numberOfLinesForDetails: Int
            let isActionable: Bool

            init(icon: UIImage, title: String?, details: String?, numberOfLinesForDetails: Int = 0, isActionable: Bool = true) {
                self.icon = icon
                self.title = title
                self.details = details
                self.numberOfLinesForDetails = numberOfLinesForDetails
                self.isActionable = isActionable
            }
        }
    }
}

/// Abstracts the view model used to render the Product form
protocol ProductFormTableViewModel {
    var sections: [ProductFormSection] { get }
}

extension ProductFormSection.SettingsRow.ViewModel: Equatable {
    static func ==(lhs: ProductFormSection.SettingsRow.ViewModel, rhs: ProductFormSection.SettingsRow.ViewModel) -> Bool {
        return lhs.icon == rhs.icon &&
            lhs.title == rhs.title &&
            lhs.details == rhs.details
    }
}
