// POSBookingDetailView.swift
import SwiftUI

struct POSBookingDetailView: View {
    let booking: POSBooking
    let onBack: () -> Void
    let onPayByCard: () -> Void
    let onPayByCash: () -> Void

    @Environment(\.siteTimezone) private var siteTimezone
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = siteTimezone
        formatter.doesRelativeDateFormatting = true
        return formatter
    }

    var body: some View {
        VStack(spacing: 0) {
            if horizontalSizeClass == .compact {
                POSPageHeaderView(
                    title: Localization.title,
                    backButtonConfiguration: .init(state: .enabled, action: onBack)
                )
            }

            ScrollView {
                VStack(alignment: .leading, spacing: POSSpacing.large) {
                    bookingInfoSection
                    Divider()
                    totalSection
                    paymentActionsSection
                }
                .padding(POSSpacing.large)
            }
        }
        .background(Color.posSurface)
    }

    @ViewBuilder
    private var bookingInfoSection: some View {
        VStack(alignment: .leading, spacing: POSSpacing.small) {
            Text(booking.customerName)
                .font(.posBodyXLargeBold)
                .foregroundStyle(Color.posOnSurface)

            Text(booking.serviceName)
                .font(.posBodyLargeRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)

            Text(dateFormatter.string(from: booking.startTime))
                .font(.posBodyMediumRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
        }
    }

    @ViewBuilder
    private var totalSection: some View {
        HStack {
            Text(Localization.total)
                .font(.posBodyLargeBold)
                .foregroundStyle(Color.posOnSurface)

            Spacer()

            Text(booking.amount)
                .font(.posBodyXLargeBold)
                .foregroundStyle(Color.posOnSurface)
        }
    }

    @ViewBuilder
    private var paymentActionsSection: some View {
        switch booking.status {
        case .unpaid:
            VStack(spacing: POSSpacing.medium) {
                Button(Localization.payByCard) {
                    onPayByCard()
                }
                .buttonStyle(POSFilledButtonStyle(size: .normal))

                Button(Localization.payByCash) {
                    onPayByCash()
                }
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))
            }

        case .paid:
            statusMessage(
                icon: "checkmark.circle.fill",
                text: Localization.paymentComplete,
                color: .posSuccess
            )

        case .cancelled:
            statusMessage(
                icon: "xmark.circle.fill",
                text: Localization.bookingCancelled,
                color: .posOnSurfaceVariantHighest
            )

        case .noLinkedOrder:
            statusMessage(
                icon: "exclamationmark.triangle.fill",
                text: Localization.noLinkedOrder,
                color: .posError
            )
        }
    }

    @ViewBuilder
    private func statusMessage(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: POSSpacing.small) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(text)
                .font(.posBodyLargeRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
        }
        .frame(maxWidth: .infinity)
        .padding(POSSpacing.medium)
        .background(Color.posSurfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: POSSpacing.small))
    }

    private enum Localization {
        static let title = NSLocalizedString("posBookingDetail.title", value: "Booking", comment: "Title for booking detail view")
        static let total = NSLocalizedString("posBookingDetail.total", value: "Total", comment: "Total label")
        static let payByCard = NSLocalizedString("posBookingDetail.payByCard", value: "Pay by Card", comment: "Card payment button")
        static let payByCash = NSLocalizedString("posBookingDetail.payByCash", value: "Pay by Cash", comment: "Cash payment button")
        static let paymentComplete = NSLocalizedString("posBookingDetail.paymentComplete", value: "Payment Complete", comment: "Status for paid booking")
        static let bookingCancelled = NSLocalizedString("posBookingDetail.bookingCancelled", value: "Booking Cancelled", comment: "Status for cancelled booking")
        static let noLinkedOrder = NSLocalizedString("posBookingDetail.noLinkedOrder", value: "No order linked to this booking", comment: "Status for booking without order")
    }
}
