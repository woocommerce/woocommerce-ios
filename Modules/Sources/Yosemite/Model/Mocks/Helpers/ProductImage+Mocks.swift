import Foundation

extension ProductImage {
    static func fromUrl(_ string: String) -> ProductImage {
        ProductImage(imageID: 0, dateCreated: Date(), dateModified: nil, src: string, name: string.slugified, alt: string.slugified)
    }
}
