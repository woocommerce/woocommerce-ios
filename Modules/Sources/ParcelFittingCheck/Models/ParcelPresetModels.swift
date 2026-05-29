import UIKit

public struct ParcelPresetCarrier: Identifiable {
    public let id: String
    public let name: String
    public let logo: UIImage?
    public let packages: [ParcelPresetPackage]

    public init(id: String, name: String, logo: UIImage? = nil, packages: [ParcelPresetPackage]) {
        self.id = id
        self.name = name
        self.logo = logo
        self.packages = packages
    }
}

public struct ParcelPresetPackage: Identifiable {
    public let id: String
    public let name: String
    public let length: Float
    public let width: Float
    public let height: Float

    public init(id: String, name: String, length: Float, width: Float, height: Float) {
        self.id = id
        self.name = name
        self.length = length
        self.width = width
        self.height = height
    }

    var dimensions: ParcelDimensions {
        ParcelDimensions(length: length, width: width, height: height)
    }

    var volume: Float {
        length * width * height
    }
}

public enum ParcelFittingResult {
    case carrierPackage(ParcelPresetPackage, measurement: ParcelDimensions)
    case customDimensions(ParcelDimensions)

    public var measurement: ParcelDimensions {
        switch self {
        case .carrierPackage(_, let measurement): return measurement
        case .customDimensions(let dims): return dims
        }
    }
}

public protocol ParcelFittingDelegate: AnyObject {
    func parcelFittingDidConfirm(_ result: ParcelFittingResult,
                                  carriers: [ParcelPresetCarrier],
                                  starredPackageIDs: Set<String>,
                                  dimensionUnit: UnitLength)
    func parcelFittingDidCancel()
    func parcelFittingDidToggleStar(packageID: String, carrierID: String, isStarred: Bool)
}
