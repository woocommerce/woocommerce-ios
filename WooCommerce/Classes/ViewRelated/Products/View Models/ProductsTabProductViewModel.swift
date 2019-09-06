import Foundation
import Yosemite

private extension Product {
    func createDetailsAttributedString() -> NSAttributedString {
        let attributedString = NSAttributedString(string: productStatus.description, attributes: [.foregroundColor: StyleManager.defaultTextColor])
        return attributedString
    }
}

struct ProductsTabProductViewModel {
    let imageUrl: String?
    let name: String
    let detailsAttributedString: NSAttributedString

    init(product: Product) {
        imageUrl = product.images.first?.src
        name = product.name
        detailsAttributedString = product.createDetailsAttributedString()
    }
}
