
import Foundation

extension ProductImage: Copiable {
    func copy() -> ProductImage {
        self.copy(imageID: self.imageID)
    }

    func copy(imageID: Int64? = nil,
              dateCreated: Date? = nil,
              dateModified: Date?? = nil,
              src: String? = nil,
              name: String?? = nil,
              alt: String?? = nil) -> ProductImage {
        ProductImage(
            imageID: imageID ?? self.imageID,
            dateCreated: dateCreated ?? self.dateCreated,
            dateModified: dateModified ?? self.dateModified,
            src: src ?? self.src,
            name: name ?? self.name,
            alt: alt ?? self.alt
        )
    }
}
