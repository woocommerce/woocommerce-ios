import UIKit
import Yosemite

enum ProductFormSection {
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

    enum PrimaryFieldRow {
        case images
        case name(name: String?)
        case description(description: String?)
    }

    enum SettingsRow {
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

// MARK: Equatable implementations

extension ProductFormSection: Equatable {
    static func ==(lhs: ProductFormSection, rhs: ProductFormSection) -> Bool {
        switch (lhs, rhs) {
        case (let .primaryFields(rows1), let .primaryFields(rows2)):
            return rows1 == rows2
        case (let .settings(rows1), let .settings(rows2)):
            return rows1 == rows2
        default:
            return false
        }
    }
}

extension ProductFormSection.PrimaryFieldRow: Equatable {
    static func ==(lhs: ProductFormSection.PrimaryFieldRow, rhs: ProductFormSection.PrimaryFieldRow) -> Bool {
        switch (lhs, rhs) {
        case (.images, .images):
            return true
        case (let .name(name1), let .name(name2)):
            return name1 == name2
        case (let .description(description1), let .description(description2)):
            return description1 == description2
        default:
            return false
        }
    }
}

extension ProductFormSection.SettingsRow: Equatable {
    static func ==(lhs: ProductFormSection.SettingsRow, rhs: ProductFormSection.SettingsRow) -> Bool {
        switch (lhs, rhs) {
        case (let .price(viewModel1), let .price(viewModel2)):
            return viewModel1 == viewModel2
        case (let .reviews(viewModel1, ratingCount1, averageRating1), let .reviews(viewModel2, ratingCount2, averageRating2)):
            return viewModel1 == viewModel2 && ratingCount1 == ratingCount2 && averageRating1 == averageRating2
        case (let .shipping(viewModel1), let .shipping(viewModel2)):
            return viewModel1 == viewModel2
        case (let .inventory(viewModel1), let .inventory(viewModel2)):
            return viewModel1 == viewModel2
        case (let .briefDescription(viewModel1), let .briefDescription(viewModel2)):
            return viewModel1 == viewModel2
        default:
            return false
        }
    }
}

extension ProductFormSection.SettingsRow.ViewModel: Equatable {
    static func ==(lhs: ProductFormSection.SettingsRow.ViewModel, rhs: ProductFormSection.SettingsRow.ViewModel) -> Bool {
        return lhs.icon == rhs.icon &&
            lhs.title == rhs.title &&
            lhs.details == rhs.details
    }
}
