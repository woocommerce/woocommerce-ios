//  StoreIconImage.swift
//
//  A design-system icon at a specific style (e.g. `StoreIcon.Gear.regular`). Closed for
//  construction — instances are only the generated `StoreIcon` tokens. Render with
//  `.image(size:)`, which returns a template image you tint via `.foregroundStyle(...)`.

import SwiftUI

public struct StoreIconImage {
    private let assetName: String

    init(_ assetName: String) {
        self.assetName = assetName
    }

    /// A template, tintable image of this icon at the given size (use `StoreIconSize`).
    public func image(size: CGFloat) -> some View {
        Image(assetName, bundle: .module)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}
