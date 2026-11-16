import StoreDesignSystem
import SwiftUI

struct StoreOrderListSkeletonView: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var isHighlighted = false

    var body: some View {
        VStack(alignment: .leading, spacing: StoreSpacing.s3) {
            placeholder(width: StorePadding.p10 + StorePadding.p8, height: StorePadding.p4)
            HStack(spacing: StoreSpacing.s3) {
                placeholder(height: StorePadding.p6)
                placeholder(width: StorePadding.p12, height: StorePadding.p6)
            }
            placeholder(width: StorePadding.p12 + StorePadding.p8, height: StoreSize.badgeHeight)
        }
        .padding(.horizontal, StorePadding.p5)
        .padding(.vertical, StorePadding.p4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.storeSurface)
        .opacity(isHighlighted ? 0.55 : 1)
        .animation(accessibilityReduceMotion ? nil : .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                   value: isHighlighted)
        .onAppear {
            isHighlighted = true
        }
        .accessibilityHidden(true)
    }

    private func placeholder(width: CGFloat? = nil, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: StoreRadius.small)
            .fill(Color.storeSurfaceContainerHighest)
            .frame(maxWidth: width == nil ? .infinity : nil)
            .frame(width: width, height: height)
    }
}
