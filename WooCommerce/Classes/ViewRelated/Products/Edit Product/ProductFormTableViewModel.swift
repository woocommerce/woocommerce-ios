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
        case name(name: String?)
        case variationName(name: String)
        case description(description: String?)
    }

    enum SettingsRow: Equatable {
        case price(viewModel: ViewModel)
        case reviews(viewModel: ViewModel, ratingCount: Int, averageRating: String)
        case shipping(viewModel: ViewModel)
        case inventory(viewModel: ViewModel)
        case categories(viewModel: ViewModel)
        case tags(viewModel: ViewModel)
        case briefDescription(viewModel: ViewModel)
        case externalURL(viewModel: ViewModel)
        case sku(viewModel: ViewModel)
        case groupedProducts(viewModel: ViewModel)
        case variations(viewModel: ViewModel)
        case noPriceWarning(viewModel: WarningViewModel)
        case status(viewModel: SwitchableViewModel)

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

            init(viewModel: ViewModel,
                 isSwitchOn: Bool) {
                self.viewModel = viewModel
                self.isSwitchOn = isSwitchOn
            }
        }

        /// View model for warning UI
        struct WarningViewModel: Equatable {
            let icon: UIImage
            let title: String?

            init(icon: UIImage, title: String?) {
                self.icon = icon
                self.title = title
            }
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
