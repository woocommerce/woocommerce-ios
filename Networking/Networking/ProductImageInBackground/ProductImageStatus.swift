import Foundation
import Photos
import UIKit

/// The status of a Product image.
///

public enum ProductImageStatus: Equatable, Codable {
    /// An image asset is being uploaded.
    ///
    case uploading(asset: ProductImageAssetType, siteID: Int64, productID: ProductOrVariationID)

    /// The Product image exists remotely.
    ///
    case remote(image: ProductImage, siteID: Int64, productID: ProductOrVariationID)

    /// An image asset upload failed.
    ///
    case uploadFailure(asset: ProductImageAssetType, error: Error, siteID: Int64, productID: ProductOrVariationID)

    private enum CodingKeys: String, CodingKey {
        case type
        case asset
        case image
        case error
        case siteID
        case productID
        case errorDomain
        case errorCode
        case errorUserInfo
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeString = try container.decode(String.self, forKey: .type)

        switch typeString {
        case "uploading":
            let asset = try container.decode(ProductImageAssetType.self, forKey: .asset)
            let sID = try container.decode(Int64.self, forKey: .siteID)
            let pID = try container.decode(ProductOrVariationID.self, forKey: .productID)
            self = .uploading(asset: asset, siteID: sID, productID: pID)
        case "remote":
            let image = try container.decode(ProductImage.self, forKey: .image)
            let sID = try container.decode(Int64.self, forKey: .siteID)
            let pID = try container.decode(ProductOrVariationID.self, forKey: .productID)
            self = .remote(image: image, siteID: sID, productID: pID)
        case "uploadFailure":
            let asset = try container.decode(ProductImageAssetType.self, forKey: .asset)
            let sID = try container.decode(Int64.self, forKey: .siteID)
            let pID = try container.decode(ProductOrVariationID.self, forKey: .productID)
            let domain = try container.decode(String.self, forKey: .errorDomain)
            let code = try container.decode(Int.self, forKey: .errorCode)
            let userInfo = try container.decode([String: String]?.self, forKey: .errorUserInfo)
            self = .uploadFailure(asset: asset, error: NSError(domain: domain, code: code, userInfo: userInfo), siteID: sID, productID: pID)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type,
                                                   in: container,
                                                   debugDescription: "Invalid type value: \(typeString)")
        }
    }

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
        case .uploadFailure(let asset, let error, let siteID, let productID):
            try container.encode("uploadFailure", forKey: .type)
            try container.encode(asset, forKey: .asset)
            try container.encode(siteID, forKey: .siteID)
            try container.encode(productID, forKey: .productID)

            let errorMessage = error as NSError
            try container.encode(errorMessage.domain, forKey: .errorDomain)
            try container.encode(errorMessage.code, forKey: .errorCode)
            try container.encode(errorMessage.userInfo as? [String: String], forKey: .errorUserInfo)
        }
    }

    public var isUploading: Bool {
        if case .uploading = self {
            return true
        }
        return false
    }

    public var isUploadFailure: Bool {
        if case .uploadFailure = self {
            return true
        }
        return false
    }

    public var siteID: Int64 {
        switch self {
        case .uploading(_, let siteID, _),
            .remote(_, let siteID, _),
            .uploadFailure(_, _, let siteID, _):
            return siteID
        }
    }

    public var productOrVariationID: ProductOrVariationID {
        switch self {
        case .uploading(_, _, let productID),
             .uploadFailure(_, _, _, let productID),
             .remote(_, _, let productID):
            return productID
        }
    }

    public var asset: ProductImageAssetType? {
        switch self {
        case .uploading(let asset, _, _),
             .uploadFailure(let asset, _, _, _):
            return asset
        default:
            return nil
        }
    }

    public var error: Error? {
        if case .uploadFailure(_, let error, _, _) = self {
            return error
        }
        return nil
    }

    public var isLocalID: Bool {
        if productOrVariationID.id == 0 {
            return true
        }
        return false
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.uploading(lAsset, lSiteID, lProductID), .uploading(rAsset, rSiteID, rProductID)):
            return lAsset == rAsset && lSiteID == rSiteID && lProductID == rProductID
        case let (.remote(lImage, lSiteID, lProductID), .remote(rImage, rSiteID, rProductID)):
            return lImage == rImage && lSiteID == rSiteID && lProductID == rProductID
        case let (.uploadFailure(lAsset, lError, lSiteID, lProductID), .uploadFailure(rAsset, rError, rSiteID, rProductID)):
            return lAsset == rAsset &&
                   (lError as NSError) == (rError as NSError) &&
                   lSiteID == rSiteID &&
                   lProductID == rProductID
        default:
            return false
        }
    }
}

/// The type of product image asset.
public enum ProductImageAssetType: Equatable, Codable {
    /// `PHAsset` from device photo library or camera capture.
    case phAsset(asset: PHAsset)

    /// `UIImage` from image processing. The filename and alt text need to be provided separately.
    case uiImage(image: UIImage, filename: String?, altText: String?)

    private enum CodingKeys: String, CodingKey {
        case type
        case asset    // For phAsset: localIdentifier string
        case imageData  // For uiImage: base64 encoded image data
        case filename
        case altText
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeString = try container.decode(String.self, forKey: .type)
        switch typeString {
        case "phAsset":
            let localIdentifier = try container.decode(String.self, forKey: .asset)
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
            guard let asset = fetchResult.firstObject else {
                throw DecodingError.dataCorruptedError(forKey: .asset,
                                                       in: container,
                                                       debugDescription: "No PHAsset found with localIdentifier \(localIdentifier)")
            }
            self = .phAsset(asset: asset)
        case "uiImage":
            let base64String = try container.decode(String.self, forKey: .imageData)
            guard let imageData = Data(base64Encoded: base64String),
                  let image = UIImage(data: imageData) else {
                throw DecodingError.dataCorruptedError(forKey: .imageData,
                                                       in: container,
                                                       debugDescription: "Invalid image data")
            }
            let filename = try container.decodeIfPresent(String.self, forKey: .filename)
            let altText = try container.decodeIfPresent(String.self, forKey: .altText)
            self = .uiImage(image: image, filename: filename, altText: altText)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type,
                                                   in: container,
                                                   debugDescription: "Unknown type \(typeString)")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .phAsset(let asset):
            try container.encode("phAsset", forKey: .type)
            try container.encode(asset.localIdentifier, forKey: .asset)
        case .uiImage(let image, let filename, let altText):
            try container.encode("uiImage", forKey: .type)
            guard let imageData = image.pngData() else {
                let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "Unable to encode UIImage as PNG")
                throw EncodingError.invalidValue(image, context)
            }
            let base64String = imageData.base64EncodedString()
            try container.encode(base64String, forKey: .imageData)
            try container.encode(filename, forKey: .filename)
            try container.encode(altText, forKey: .altText)
        }
    }

    public static func == (lhs: ProductImageAssetType, rhs: ProductImageAssetType) -> Bool {
        switch (lhs, rhs) {
        case (.phAsset(let lAsset), .phAsset(let rAsset)):
            return lAsset.localIdentifier == rAsset.localIdentifier
        case (.uiImage(let lImage, let lFilename, let lAltText),
              .uiImage(let rImage, let rFilename, let rAltText)):
            return lImage.pngData() == rImage.pngData() &&
                   lFilename == rFilename &&
                   lAltText == rAltText
        default:
            return false
        }
    }
}
