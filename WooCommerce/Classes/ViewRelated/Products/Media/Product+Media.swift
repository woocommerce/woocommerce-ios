import Foundation
import Yosemite

extension Product {
    var imageStatuses: [ProductImageStatus] {
        return images.map({ ProductImageStatus.remote(image: $0) })
    }
}
