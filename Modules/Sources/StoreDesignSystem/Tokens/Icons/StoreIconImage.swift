import SwiftUI

public struct StoreIconImage: Sendable {
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

    /// Like ``image(size:)``, but the size follows Dynamic Type on the same curve as
    /// ``StoreTextStyle``, for glyphs that sit inline with text (a search field's glass, a clear control).
    @MainActor
    public func scaledImage(size: StoreIconSize) -> some View {
        StoreScaledIconImage(assetName: assetName, size: size)
    }
}

private struct StoreScaledIconImage: View {
    private let assetName: String
    @ScaledMetric private var side: CGFloat

    init(assetName: String, size: StoreIconSize) {
        self.assetName = assetName
        _side = ScaledMetric(wrappedValue: size.value, relativeTo: .body)
    }

    var body: some View {
        Image(assetName, bundle: .module)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: side, height: side)
    }
}
