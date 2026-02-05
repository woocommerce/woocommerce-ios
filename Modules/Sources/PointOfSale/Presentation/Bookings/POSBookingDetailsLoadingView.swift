// POSBookingDetailsLoadingView.swift
import SwiftUI

/// Shimmer skeleton loading view for booking details
struct POSBookingDetailsLoadingView: View {
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: POSSpacing.large) {
                    bookingInfoSection
                    Divider()
                    totalSection
                    actionSection
                }
                .padding(POSSpacing.large)
            }
        }
        .background(Color.posSurface)
    }

    @ViewBuilder
    private var bookingInfoSection: some View {
        VStack(alignment: .leading, spacing: POSSpacing.small) {
            Rectangle()
                .fill(Color.posOnSurfaceVariantLowest)
                .frame(width: Constants.longRowWidth, height: 24)
                .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
                .shimmering()

            Rectangle()
                .fill(Color.posOnSurfaceVariantLowest)
                .frame(width: Constants.mediumRowWidth, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
                .shimmering()

            Rectangle()
                .fill(Color.posOnSurfaceVariantLowest)
                .frame(width: Constants.shortRowWidth, height: 16)
                .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
                .shimmering()
        }
    }

    @ViewBuilder
    private var totalSection: some View {
        HStack {
            Rectangle()
                .fill(Color.posOnSurfaceVariantLowest)
                .frame(width: 60, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
                .shimmering()

            Spacer()

            Rectangle()
                .fill(Color.posOnSurfaceVariantLowest)
                .frame(width: 80, height: 24)
                .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
                .shimmering()
        }
    }

    @ViewBuilder
    private var actionSection: some View {
        VStack(spacing: POSSpacing.medium) {
            Rectangle()
                .fill(Color.posOnSurfaceVariantLowest)
                .frame(height: 48)
                .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.medium.value))
                .shimmering()

            Rectangle()
                .fill(Color.posOnSurfaceVariantLowest)
                .frame(height: 48)
                .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.medium.value))
                .shimmering()
        }
    }
}

private enum Constants {
    static let longRowWidth: CGFloat = 160
    static let mediumRowWidth: CGFloat = 120
    static let shortRowWidth: CGFloat = 100
}

#if DEBUG
#Preview {
    POSBookingDetailsLoadingView()
}
#endif
