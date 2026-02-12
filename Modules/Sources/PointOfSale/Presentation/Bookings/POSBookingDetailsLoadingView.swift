import SwiftUI

struct POSBookingDetailsLoadingView: View {
    @ScaledMetric private var scale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            POSPageHeaderView(
                title: " ",
                backButtonConfiguration: nil,
                leadingContent: { ghostHeaderTitle },
                bottomContent: { ghostHeaderSubtitle }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: POSSpacing.large) {
                    ghostBookingDetailsCard
                    ghostAttendanceCard
                    ghostCustomerCard
                    ghostPaymentCard
                    ghostBookingNoteCard
                }
                .padding(.top, POSPadding.xSmall)
                .padding(.horizontal, POSPadding.medium)
                .padding(.bottom, POSPadding.medium)
            }
        }
        .background(Color.posSurface)
        .navigationBarHidden(true)
        .accessibilityHidden(true)
    }

    // MARK: - Header

    private var ghostHeaderTitle: some View {
        HStack {
            ghostLine(width: Constants.extraLargeWidth, height: Constants.titleHeight * scale)
            Spacer()
        }
        .dynamicTypeSize(...POSHeaderLayoutConstants.maximumDynamicTypeSize)
    }

    private var ghostHeaderSubtitle: some View {
        VStack(alignment: .leading, spacing: POSSpacing.small) {
            ghostLine(width: Constants.largeWidth, height: Constants.subtitleHeight * scale)
            HStack(spacing: POSSpacing.small) {
                ghostLine(width: Constants.smallWidth, height: Constants.badgeHeight * scale)
                ghostLine(width: Constants.extraSmallWidth, height: Constants.badgeHeight * scale)
            }
        }
        .dynamicTypeSize(...POSHeaderLayoutConstants.maximumDynamicTypeSize)
        .padding(.top, POSPadding.xSmall)
    }

    // MARK: - Cards

    private var ghostBookingDetailsCard: some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            ghostLine(width: Constants.mediumWidth, height: Constants.sectionTitleHeight * scale)
            ghostDetailRow(labelWidth: Constants.smallWidth, valueWidth: Constants.mediumWidth)
            ghostDetailRow(labelWidth: Constants.smallWidth, valueWidth: Constants.largeWidth)
            ghostDetailRow(labelWidth: Constants.extraSmallWidth, valueWidth: Constants.extraSmallWidth)
        }
        .sectionCard()
    }

    private var ghostAttendanceCard: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                ghostLine(width: Constants.mediumWidth, height: Constants.rowHeight * scale)
                Spacer()
                HStack(spacing: POSSpacing.small) {
                    ghostLine(width: Constants.smallWidth, height: Constants.buttonHeight * scale)
                    ghostLine(width: Constants.smallWidth, height: Constants.buttonHeight * scale)
                }
            }
            VStack(alignment: .leading, spacing: POSSpacing.medium) {
                ghostLine(width: Constants.mediumWidth, height: Constants.rowHeight * scale)
                HStack(spacing: POSSpacing.small) {
                    ghostLine(width: Constants.smallWidth, height: Constants.buttonHeight * scale)
                    ghostLine(width: Constants.smallWidth, height: Constants.buttonHeight * scale)
                }
            }
        }
        .sectionCard()
    }

    private var ghostCustomerCard: some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            ghostLine(width: Constants.smallWidth, height: Constants.sectionTitleHeight * scale)
            ghostDetailRow(labelWidth: Constants.largeWidth, valueWidth: Constants.tinyWidth)
            ghostDetailRow(labelWidth: Constants.mediumWidth, valueWidth: Constants.tinyWidth)
            VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                ghostLine(width: Constants.smallWidth, height: Constants.captionHeight * scale)
                ghostLine(width: Constants.largeWidth, height: Constants.rowHeight * scale)
            }
        }
        .sectionCard()
    }

    private var ghostPaymentCard: some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            ghostLine(width: Constants.smallWidth, height: Constants.sectionTitleHeight * scale)
            ghostDetailRow(labelWidth: Constants.extraSmallWidth, valueWidth: Constants.extraSmallWidth)
            ghostDetailRow(labelWidth: Constants.extraSmallWidth, valueWidth: Constants.extraSmallWidth)
            ghostDetailRow(labelWidth: Constants.extraSmallWidth, valueWidth: Constants.extraSmallWidth)
            Divider()
                .overlay(Color.posOutlineVariant.opacity(0.5))
            ghostDetailRow(labelWidth: Constants.extraSmallWidth, valueWidth: Constants.extraSmallWidth)
        }
        .sectionCard()
    }

    private var ghostBookingNoteCard: some View {
        HStack {
            ghostLine(width: Constants.mediumWidth, height: Constants.sectionTitleHeight * scale)
            Spacer()
            ghostLine(width: Constants.smallWidth, height: Constants.buttonHeight * scale)
        }
        .sectionCard()
    }

    // MARK: - Reusable Ghost Components

    private func ghostLine(width: CGFloat, height: CGFloat) -> some View {
        Rectangle()
            .fill(Color.posOnSurfaceVariantLowest)
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
            .shimmering()
    }

    private func ghostDetailRow(labelWidth: CGFloat, valueWidth: CGFloat) -> some View {
        HStack {
            ghostLine(width: labelWidth, height: Constants.rowHeight * scale)
            Spacer()
            ghostLine(width: valueWidth, height: Constants.rowHeight * scale)
        }
    }
}

private enum Constants {
    // Heights
    static let titleHeight: CGFloat = 36
    static let subtitleHeight: CGFloat = 20
    static let sectionTitleHeight: CGFloat = 28
    static let rowHeight: CGFloat = 20
    static let captionHeight: CGFloat = 14
    static let badgeHeight: CGFloat = 24
    static let buttonHeight: CGFloat = 36

    // Widths
    static let extraLargeWidth: CGFloat = 260
    static let largeWidth: CGFloat = 180
    static let mediumWidth: CGFloat = 120
    static let smallWidth: CGFloat = 80
    static let extraSmallWidth: CGFloat = 60
    static let tinyWidth: CGFloat = 20
}

#if DEBUG
#Preview("Loading State") {
    POSBookingDetailsLoadingView()
}
#endif
