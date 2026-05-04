import Foundation

public struct ParcelPresetCarrier: Identifiable {
    public let id: String
    public let name: String
    public let packages: [ParcelPresetPackage]

    public init(id: String, name: String, packages: [ParcelPresetPackage]) {
        self.id = id
        self.name = name
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
}
