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
}
