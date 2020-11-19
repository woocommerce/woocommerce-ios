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
        case images(isEditable: Bool)
        case name(name: String?, isEditable: Bool)
        case variationName(name: String)
        case description(description: String?, isEditable: Bool)
    }

    enum SettingsRow: Equatable {
        case price(viewModel: ViewModel, isEditable: Bool)
        case reviews(viewModel: ViewModel, ratingCount: Int, averageRating: String)
        case productType(viewModel: ViewModel, isEditable: Bool)
        case shipping(viewModel: ViewModel, isEditable: Bool)
        case inventory(viewModel: ViewModel, isEditable: Bool)
        case categories(viewModel: ViewModel, isEditable: Bool)
        case tags(viewModel: ViewModel, isEditable: Bool)
        case shortDescription(viewModel: ViewModel, isEditable: Bool)
        case externalURL(viewModel: ViewModel, isEditable: Bool)
        case sku(viewModel: ViewModel, isEditable: Bool)
        case groupedProducts(viewModel: ViewModel, isEditable: Bool)
        case variations(viewModel: ViewModel)
        case downloadableFiles(viewModel: ViewModel)
        case noPriceWarning(viewModel: WarningViewModel)
        case status(viewModel: SwitchableViewModel, isEditable: Bool)
        case linkedProducts(viewModel: ViewModel, isEditable: Bool)

        struct ViewModel {
            let icon: UIImage
            let title: String?
            let details: String?
            /// If not nil, the color is applied to icon and text labels.
            let tintColor: UIColor?
            let numberOfLinesForDetails: Int
            let isActionable: Bool

            init(icon: UIImage, title: String?, details: String?, tintColor: UIColor? = nil, numberOfLinesForDetails: Int = 0, isActionable: Bool = true) {
                self.icon = icon
                self.title = title
                self.details = details
                self.tintColor = tintColor
                self.numberOfLinesForDetails = numberOfLinesForDetails
                self.isActionable = isActionable
            }
        }

        /// View model with a switch toggle
        struct SwitchableViewModel: Equatable {
            let viewModel: ViewModel
            let isSwitchOn: Bool
            let isActionable: Bool

            init(viewModel: ViewModel,
                 isSwitchOn: Bool,
                 isActionable: Bool) {
                self.viewModel = viewModel
                self.isSwitchOn = isSwitchOn
                self.isActionable = isActionable
            }
        }

        /// View model for warning UI
        struct WarningViewModel: Equatable {
            let icon: UIImage
            let title: String?
        }
    }
}

/// Abstracts the view model used to render the Product form
protocol ProductFormTableViewModel {
    var sections: [ProductFormSection] { get }
}


// MARK: Equatable implementations
extension ProductFormSection.SettingsRow.ViewModel: Equatable {
    static func ==(lhs: ProductFormSection.SettingsRow.ViewModel, rhs: ProductFormSection.SettingsRow.ViewModel) -> Bool {
        return lhs.icon == rhs.icon &&
            lhs.title == rhs.title &&
            lhs.details == rhs.details
    }
}
