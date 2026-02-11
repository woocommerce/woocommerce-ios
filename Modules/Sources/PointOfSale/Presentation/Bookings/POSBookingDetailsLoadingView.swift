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
            ghostLine(width: 260, height: Constants.titleHeight * scale)
            Spacer()
        }
        .dynamicTypeSize(...POSHeaderLayoutConstants.maximumDynamicTypeSize)
    }

    private var ghostHeaderSubtitle: some View {
        VStack(alignment: .leading, spacing: POSSpacing.small) {
            ghostLine(width: 180, height: Constants.subtitleHeight * scale)
            HStack(spacing: POSSpacing.small) {
                ghostLine(width: 80, height: Constants.badgeHeight * scale)
                ghostLine(width: 60, height: Constants.badgeHeight * scale)
            }
        }
        .dynamicTypeSize(...POSHeaderLayoutConstants.maximumDynamicTypeSize)
        .padding(.top, POSPadding.xSmall)
    }

    // MARK: - Cards

    private var ghostBookingDetailsCard: some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            ghostLine(width: 140, height: Constants.sectionTitleHeight * scale)
            ghostDetailRow(labelWidth: 100, valueWidth: 120)
            ghostDetailRow(labelWidth: 80, valueWidth: 180)
            ghostDetailRow(labelWidth: 70, valueWidth: 60)
        }
        .sectionCard()
    }

    private var ghostAttendanceCard: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                ghostLine(width: 130, height: Constants.rowHeight * scale)
                Spacer()
                HStack(spacing: POSSpacing.small) {
                    ghostLine(width: 90, height: Constants.buttonHeight * scale)
                    ghostLine(width: 90, height: Constants.buttonHeight * scale)
                }
            }
            VStack(alignment: .leading, spacing: POSSpacing.medium) {
                ghostLine(width: 130, height: Constants.rowHeight * scale)
                HStack(spacing: POSSpacing.small) {
                    ghostLine(width: 90, height: Constants.buttonHeight * scale)
                    ghostLine(width: 90, height: Constants.buttonHeight * scale)
                }
            }
        }
        .sectionCard()
    }

    private var ghostCustomerCard: some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            ghostLine(width: 100, height: Constants.sectionTitleHeight * scale)
            ghostDetailRow(labelWidth: 180, valueWidth: 20)
            ghostDetailRow(labelWidth: 150, valueWidth: 20)
            VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                ghostLine(width: 100, height: Constants.captionHeight * scale)
                ghostLine(width: 220, height: Constants.rowHeight * scale)
            }
        }
        .sectionCard()
    }

    private var ghostPaymentCard: some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            ghostLine(width: 90, height: Constants.sectionTitleHeight * scale)
            ghostDetailRow(labelWidth: 60, valueWidth: 60)
            ghostDetailRow(labelWidth: 50, valueWidth: 50)
            ghostDetailRow(labelWidth: 70, valueWidth: 30)
            Divider()
                .overlay(Color.posOutlineVariant.opacity(0.5))
            ghostDetailRow(labelWidth: 50, valueWidth: 60)
        }
        .sectionCard()
    }

    private var ghostBookingNoteCard: some View {
        HStack {
            ghostLine(width: 130, height: Constants.sectionTitleHeight * scale)
            Spacer()
            ghostLine(width: 80, height: Constants.buttonHeight * scale)
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
    static let titleHeight: CGFloat = 36
    static let subtitleHeight: CGFloat = 20
    static let sectionTitleHeight: CGFloat = 28
    static let rowHeight: CGFloat = 20
    static let captionHeight: CGFloat = 14
    static let badgeHeight: CGFloat = 24
    static let buttonHeight: CGFloat = 36
}

#if DEBUG
#Preview("Loading State") {
    POSBookingDetailsLoadingView()
}
#endif
