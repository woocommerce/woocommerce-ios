import Foundation
import Yosemite

extension ProductFormDataModel {
    var imageStatuses: [ProductImageStatus] {
        return images.map({ ProductImageStatus.remote(image: $0) })
    }
}

extension Product {
    var imageStatuses: [ProductImageStatus] {
        return images.map({ ProductImageStatus.remote(image: $0) })
    }

    /// Returns the URL of the first image, if available. Otherwise, nil is returned.
    var imageURL: URL? {
        images.first?.imageURL
    }
}

extension ProductVariation {
    var imageURL: URL? {
        image?.imageURL
    }
}

private extension ProductImage {
    var imageURL: URL? {
        guard let encodedProductImageURLString = src.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: encodedProductImageURLString)
    }
}
