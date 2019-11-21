import UIKit

enum ProductFormSection {
    case images
    case primaryFields(rows: [PrimaryFieldRow])
    case details(rows: [DetailRow])

    enum PrimaryFieldRow {
        case name(name: String?)
        case description(description: String?)
    }

    enum DetailRow {
        case price
        case shipping
        case inventory
    }
}

/// Abstracts the view model used to render the Product form
protocol ProductFormTableViewModel {
    var sections: [ProductFormSection] { get }
}
