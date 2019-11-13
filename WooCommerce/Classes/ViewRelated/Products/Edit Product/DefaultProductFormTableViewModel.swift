import UIKit
import Yosemite

/// The Product form contains 3 sections: images, primary fields, and details.
struct DefaultProductFormTableViewModel: ProductFormTableViewModel {

    private(set) var sections: [ProductFormSection] = []

    init(product: Product) {
        configureSections(product: product)
    }
}

private extension DefaultProductFormTableViewModel {
    mutating func configureSections(product: Product) {
        sections = [.images,
                    .primaryFields(rows: primaryFieldRows(product: product)),
                    .details(rows: [])]
    }

    func primaryFieldRows(product: Product) -> [ProductFormSection.PrimaryFieldRow] {
        return [
            .description(description: product.trimmedFullDescription)
        ]
    }
}
