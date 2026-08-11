import SwiftUI

public struct StoreButton: View {
    private let title: String
    private let icon: StoreIconImage?
    private let variant: StoreButtonVariant
    private let size: StoreButtonSize
    private let action: () -> Void

    public init(_ title: String,
                icon: StoreIconImage? = nil,
                variant: StoreButtonVariant = .filled,
                size: StoreButtonSize = .small,
                action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.variant = variant
        self.size = size
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: StoreSpacing.s3) {
                icon?.image(size: size.iconSize)
                Text(title).storeTextStyle(size.textStyle)
            }
        }
        .buttonStyle(StoreButtonStyle(variant: variant, size: size))
    }
}
