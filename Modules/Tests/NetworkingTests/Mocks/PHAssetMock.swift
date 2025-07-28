import Photos

// PHAsset mock to allow encoding without an actual Photos library asset
class PHAssetMock: PHAsset, @unchecked Sendable {
    private let customLocalIdentifier: String

    init(localIdentifier: String) {
        self.customLocalIdentifier = localIdentifier
        super.init()
    }

    override var localIdentifier: String {
        return customLocalIdentifier
    }
}
