import Photos
import Yosemite

/// The status of a Product image.
///
enum ProductImageStatus: Equatable {
    /// An image asset is being uploaded.
    ///
    case uploading(asset: ProductImageAssetType, siteID: Int64, productID: ProductOrVariationID)

    /// The Product image exists remotely.
    ///
    case remote(image: ProductImage, siteID: Int64, productID: ProductOrVariationID)
}

/// The type of product image asset.
enum ProductImageAssetType: Equatable {
    /// `PHAsset` from device photo library or camera capture.
    case phAsset(asset: PHAsset)

    /// `UIImage` from image processing. The filename and alt text need to be provided separately.
    case uiImage(image: UIImage, filename: String?, altText: String?)
}

extension Collection where Element == ProductImageStatus {
    var images: [ProductImage] {
        compactMap { status in
            switch status {
            case .remote(let image, _, _):
                return image
            default:
                return nil
            }
        }
    }

    /// Whether there are still any images being uploaded.
    ///
    var hasPendingUpload: Bool {
        return contains(where: {
            switch $0 {
            case .uploading:
                return true
            default:
                return false
            }
        })
    }
}

extension ProductImageStatus {
    var cellReuseIdentifier: String {
        return cellClass.reuseIdentifier
    }

    private var cellClass: UICollectionViewCell.Type {
        switch self {
        case .uploading:
            return InProgressProductImageCollectionViewCell.self
        case .remote:
            return ProductImageCollectionViewCell.self
        }
    }

    /// A string that uniquely identifies a `ProductImageStatus` during
    /// dragging.
    ///
    var dragItemIdentifier: String {
        switch self {
        case .uploading(let asset, _, _):
            switch asset {
                case let .phAsset(asset):
                    return asset.identifier()
                case .uiImage:
                    return UUID().uuidString
            }
        case .remote(let image, _, _):
            return "\(image.imageID)"
        }
    }
}

// Add Codable conformance for ProductImageStatus.
// This will be used to encode and decode the status of a product image in UserDefaults
extension ProductImageStatus: Codable {
	enum CodingKeys: String, CodingKey { case type, asset, image, siteID, productID }

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case .uploading(let asset, let siteID, let productID):
			try container.encode("uploading", forKey: .type)
			try container.encode(asset, forKey: .asset)
            try container.encode(siteID, forKey: .siteID)
            try container.encode(productID, forKey: .productID)
		case .remote(let image, let siteID, let productID):
			try container.encode("remote", forKey: .type)
			try container.encode(image, forKey: .image)
            try container.encode(siteID, forKey: .siteID)
            try container.encode(productID, forKey: .productID)
		}
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let type = try container.decode(String.self, forKey: .type)
		switch type {
		case "uploading":
			let asset = try container.decode(ProductImageAssetType.self, forKey: .asset)
            let siteID = try container.decode(Int64.self, forKey: .siteID)
            let productID = try container.decode(ProductOrVariationID.self, forKey: .productID)
			self = .uploading(asset: asset, siteID: siteID, productID: productID)
		case "remote":
			let image = try container.decode(ProductImage.self, forKey: .image)
            let siteID = try container.decode(Int64.self, forKey: .siteID)
            let productID = try container.decode(ProductOrVariationID.self, forKey: .productID)
			self = .remote(image: image, siteID: siteID, productID: productID)
		default:
			throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown ProductImageStatus type")
		}
	}
}

// Add Codable conformance for ProductImageAssetType.
extension ProductImageAssetType: Codable {
	enum CodingKeys: String, CodingKey { case type, phAsset, uiImage, filename, altText }

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case .phAsset(let asset):
			try container.encode("phAsset", forKey: .type)
			try container.encode(asset.localIdentifier, forKey: .phAsset)
		case .uiImage(let image, let filename, let altText):
			try container.encode("uiImage", forKey: .type)
			guard let imageData = image.pngData() else {
				throw EncodingError.invalidValue(image, EncodingError.Context(codingPath: [CodingKeys.uiImage], debugDescription: "Unable to convert UIImage to PNG data"))
			}
			try container.encode(imageData, forKey: .uiImage)
			try container.encode(filename, forKey: .filename)
			try container.encode(altText, forKey: .altText)
		}
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let type = try container.decode(String.self, forKey: .type)
		if type == "phAsset" {
			let localId = try container.decode(String.self, forKey: .phAsset)
			guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [localId], options: nil).firstObject else {
				throw DecodingError.dataCorruptedError(forKey: .phAsset, in: container, debugDescription: "PHAsset not found for identifier \(localId)")
			}
			self = .phAsset(asset: asset)
		} else if type == "uiImage" {
			let imageData = try container.decode(Data.self, forKey: .uiImage)
			guard let image = UIImage(data: imageData) else {
				throw DecodingError.dataCorruptedError(forKey: .uiImage, in: container, debugDescription: "Unable to create UIImage from data")
			}
			let filename = try container.decodeIfPresent(String.self, forKey: .filename)
			let altText = try container.decodeIfPresent(String.self, forKey: .altText)
			self = .uiImage(image: image, filename: filename, altText: altText)
		} else {
			throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown ProductImageAssetType type")
		}
	}
}
