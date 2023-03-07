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
        guard let productImageURLString = images.first?.src,
              let encodedProductImageURLString = productImageURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: encodedProductImageURLString)
    }
}
