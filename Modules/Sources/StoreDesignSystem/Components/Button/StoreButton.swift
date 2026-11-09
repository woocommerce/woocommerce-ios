import SwiftUI

public struct StoreButton: View {
    private let title: String
    private let icon: StoreIconImage?
    private let variant: StoreButtonVariant
    private let size: StoreButtonSize
    private let isFullWidth: Bool
    private let isTitleFixedSize: Bool
    private let action: () -> Void

    public init(_ title: String,
                icon: StoreIconImage? = nil,
                variant: StoreButtonVariant = .filled,
                size: StoreButtonSize = .small,
                isFullWidth: Bool = false,
                isTitleFixedSize: Bool = false,
                action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.variant = variant
        self.size = size
        self.isFullWidth = isFullWidth
        self.isTitleFixedSize = isTitleFixedSize
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: StoreSpacing.s3) {
                icon?.image(size: size.iconSize)
                Text(title)
                    .storeTextStyle(size.textStyle)
                    .fixedSize(horizontal: isTitleFixedSize, vertical: false)
            }
            .frame(maxWidth: isFullWidth ? .infinity : nil)
        }
        .buttonStyle(StoreButtonStyle(variant: variant, size: size))
    }
}
