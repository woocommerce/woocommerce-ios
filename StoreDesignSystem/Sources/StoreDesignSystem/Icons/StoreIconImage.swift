import SwiftUI

public struct StoreIconImage {
    private let assetName: String

    init(_ assetName: String) {
        self.assetName = assetName
    }

    /// The icon's base name, e.g. `AngleDown` for the `AngleDown-Regular` asset.
    public var name: String {
        String(assetName.split(separator: "-").first ?? "")
    }

    /// The icon's style, e.g. `regular` for the `AngleDown-Regular` asset.
    public var style: String {
        assetName.split(separator: "-").last.map { $0.lowercased() } ?? ""
    }

    /// A template, tintable image of this icon at the given size, e.g. `.image(size: .medium)`.
    public func image(size: StoreIconSize) -> some View {
        Image(assetName, bundle: .module)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size.value, height: size.value)
    }
}
