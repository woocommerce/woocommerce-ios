import Foundation
import Yosemite

extension ProductFormDataModel {
    var imageStatuses: [ProductImageStatus] {
        return images.map({ ProductImageStatus.remote(image: $0) })
    }
}
