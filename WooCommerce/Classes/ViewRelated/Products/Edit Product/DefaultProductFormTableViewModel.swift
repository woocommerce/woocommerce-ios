import UIKit
import Yosemite

/// The Product form contains 3 sections: images, primary fields, and details.
final class DefaultProductFormTableViewModel: NSObject, ProductFormTableViewModel {

    private(set) var sections: [ProductFormSection] = []

    private let product: Product

    init(product: Product) {
        self.product = product
        super.init()
        configureSections()
    }
}

private extension DefaultProductFormTableViewModel {
    func configureSections() {
        sections = [.images,
                    .primaryFields(rows: primaryFieldRows(product: product)),
                    .details(rows: [])]
    }

    func primaryFieldRows(product: Product) -> [ProductFormSection.PrimaryFieldRow] {
        return [
            .description(description: product.singleLineFullDescription)
        ]
    }
}
