import UIKit
import Yosemite

enum ProductFormSection {
    case primaryFields(rows: [PrimaryFieldRow])
    case settings(rows: [SettingsRow])
    
    enum PrimaryFieldRow {
        case images(product: Product)
        case name(name: String?)
        case description(description: String?)
    }

    enum SettingsRow {
        case price(viewModel: ViewModel)
        case shipping(viewModel: ViewModel)
        case inventory(viewModel: ViewModel)

        struct ViewModel {
            let icon: UIImage
            let title: String?
            let details: String?
        }
    }
}

/// Abstracts the view model used to render the Product form
protocol ProductFormTableViewModel {
    var sections: [ProductFormSection] { get }
}
