import SwiftUI
import struct Yosemite.POSBooking

struct POSBookingDetailView: View {
    let booking: POSBooking
    let onBack: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var navigationPath: [NavigationDestination] = []

    private var shouldShowBackButton: Bool {
        horizontalSizeClass == .compact
    }

    private var lifecycleStatus: POSBookingLifecycleStatus {
        POSBookingLifecycleStatus(bookingStatus: booking.status)
    }

    private var paymentStatus: POSBookingPaymentStatus {
        POSBookingPaymentStatus(bookingStatus: booking.status)
    }

    private var attendanceDisplay: POSBookingAttendanceDisplay {
        POSBookingAttendanceDisplay(attendanceStatus: booking.attendanceStatus)
    }

    private var isPaid: Bool {
        paymentStatus == .paid
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            bookingDetailContent
                .navigationDestination(for: NavigationDestination.self) { destination in
                    switch destination {
                    case .orderDetail:
                        POSOrderDetailsView(order: booking.order, onBack: {
                            navigationPath.removeLast()
                        })
                        // Forces back button to be rendered, otherwise the system assumes that
                        // navigation is handled by the split view's sidebar, not a back button
                        .environment(\.posHeaderBackButtonConfiguration, .init(state: .enabled, action: {
                            navigationPath.removeLast()
                        }))
                    }
                }
        }
    }

    @ViewBuilder
    private var bookingDetailContent: some View {
        VStack(spacing: POSSpacing.none) {
            POSPageHeaderView(
                title: headerTitle.isEmpty ? Localization.bookingTitle : headerTitle,
                backButtonConfiguration: shouldShowBackButton ? .init(state: .enabled, action: onBack) : nil,
                trailingContent: {
                    viewOrderMenu
                }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: POSSpacing.medium) {
                    headerBadges
                    bookingDetailsSection
                    attendanceSection
                    customerSection
                    paymentBreakdownSection
                    paymentActionSection
                    bookingNoteSection
                }
                .padding(.top, POSPadding.xSmall)
                .padding(.horizontal, POSPadding.medium)
                .padding(.bottom, POSPadding.medium)
            }
        }
        .background(Color.posSurface)
        .navigationBarHidden(true)
    }

    @ViewBuilder
    private var viewOrderMenu: some View {
        Menu {
            Button(Localization.viewOrderAction) {
                navigationPath.append(.orderDetail)
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.posBodyLargeBold)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                .foregroundColor(.posOnSurface)
                .padding(POSPadding.small)
        }
        .menuIndicator(.hidden)
    }

    // MARK: - Header Badges

    @ViewBuilder
    private var headerBadges: some View {
        HStack(spacing: POSSpacing.small) {
            Text(formattedTimeRange)
                .font(.posBodySmallRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)

            POSBookingBadgeView(
                title: attendanceDisplay.localizedTitle,
                textColor: attendanceDisplay.textColor,
                backgroundColor: attendanceDisplay.backgroundColor
            )

            POSBookingBadgeView(
                title: paymentStatus.localizedTitle,
                textColor: paymentStatus.textColor,
                backgroundColor: paymentStatus.backgroundColor
            )

            if lifecycleStatus.shouldShowBadge {
                POSBookingBadgeView(
                    title: lifecycleStatus.localizedTitle,
                    textColor: lifecycleStatus.textColor,
                    backgroundColor: lifecycleStatus.backgroundColor
                )
            }
        }
    }

    private var headerTitle: String {
        let parts = [booking.serviceName, booking.customerName].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.joined(separator: " \u{00B7} ")
    }

    // MARK: - Booking Details

    @ViewBuilder
    private var bookingDetailsSection: some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            Text(String(format: Localization.bookingIdTitle, booking.id))
                .font(.posBodySmallBold())
                .foregroundStyle(Color.posOnSurface)

            if let resourceName = booking.resourceName {
                detailRow(label: Localization.teamMemberLabel, value: resourceName)
            }

            if let location = booking.location {
                sectionDivider
                detailRow(label: Localization.locationLabel, value: location)
            }

            if !booking.duration.isEmpty {
                sectionDivider
                detailRow(label: Localization.durationLabel, value: booking.duration)
            }
        }
        .sectionCard()
    }

    // MARK: - Section 3: Customer

    @ViewBuilder
    private var customerSection: some View {
        let hasCustomerDetails = booking.customerName != nil || booking.customerEmail != nil
            || booking.customerPhone != nil || booking.billingAddress != nil
        if hasCustomerDetails {
            VStack(alignment: .leading, spacing: POSSpacing.medium) {
                if let customerName = booking.customerName {
                    detailRow(label: Localization.customerLabel, value: customerName)
                }

                if let email = booking.customerEmail {
                    detailRow(label: Localization.emailLabel, value: email)
                }

                if let phone = booking.customerPhone {
                    detailRow(label: Localization.phoneLabel, value: phone)
                }

                if let address = booking.billingAddress {
                    detailRow(label: Localization.billingAddressLabel, value: address)
                }
            }
            .sectionCard()
        }
    }

    // MARK: - Section 5: Booking Note

    @ViewBuilder
    private var bookingNoteSection: some View {
        if let note = booking.bookingNote {
            VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                Text(Localization.bookingNoteLabel)
                    .font(.posBodySmallBold())
                    .foregroundStyle(Color.posOnSurface)

                Text(note)
                    .font(.posBodySmallRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .sectionCard()
        }
    }

    // MARK: - Attendance Status

    @ViewBuilder
    private var attendanceSection: some View {
        VStack(alignment: .leading, spacing: POSSpacing.small) {
            HStack {
                Text(Localization.attendanceStatusTitle)
                    .font(.posBodySmallBold())
                    .foregroundStyle(Color.posOnSurface)

                Spacer()

                HStack(spacing: POSSpacing.small) {
                    attendancePill(
                        title: Localization.attendedPill,
                        isSelected: attendanceDisplay == .attended
                    )
                    attendancePill(
                        title: Localization.unattendedPill,
                        isSelected: attendanceDisplay == .unattended
                    )
                }
            }
            .sectionCard()

            Text(Localization.attendanceSubtitle)
                .font(.posCaptionRegular)
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
                .padding(.horizontal, POSPadding.xSmall)
        }
    }

    @ViewBuilder
    private func attendancePill(title: String, isSelected: Bool) -> some View {
        Text(title)
            .font(.posBodySmallBold())
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .foregroundStyle(isSelected ? Color.posOnDefault : Color.posOnSurfaceVariantHighest)
            .padding(.horizontal, POSPadding.small)
            .padding(.vertical, POSPadding.xSmall)
            .background(isSelected ? Color.posDefault : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
            .overlay(
                RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value)
                    .strokeBorder(isSelected ? Color.clear : Color.posOutlineVariant, lineWidth: 1)
            )
    }

    // MARK: - Section 7: Payment Breakdown

    @ViewBuilder
    private var paymentBreakdownSection: some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            if !booking.serviceName.isEmpty {
                detailRow(label: booking.serviceName, value: booking.formattedSubtotal ?? booking.formattedAmount)
            }

            detailRow(label: Localization.taxesLabel, value: booking.formattedTax ?? Localization.taxesZero)
            detailRow(label: Localization.discountLabel, value: booking.order.formattedDiscountTotal ?? Localization.discountNone)

            sectionDivider

            detailRow(label: Localization.totalLabel, value: booking.formattedAmount)
        }
        .sectionCard()
    }

    // MARK: - Section 8: Payment Action / Status

    @ViewBuilder
    private var paymentActionSection: some View {
        if isPaid {
            HStack {
                Text(Localization.paidStatusLabel)
                    .font(.posBodySmallBold())
                    .foregroundStyle(Color.posSuccess)

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.posSuccess)
            }
            .sectionCard()
        } else if lifecycleStatus != .cancelled {
            Button(action: {
                // Payment action — wired in a later milestone
            }) {
                Text(Localization.collectPaymentButton)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(POSFilledButtonStyle(size: .normal))
        }
    }

    // MARK: - Shared Components

    private var sectionDivider: some View {
        Divider()
            .overlay(Color.posOutlineVariant.opacity(0.5))
    }

    @ViewBuilder
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.posBodySmallRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)

            Spacer()

            Text(value)
                .font(.posBodySmallBold())
                .foregroundStyle(Color.posOnSurface)
        }
    }

    // MARK: - Formatting

    private var formattedDate: String {
        DateFormatter.dateOnlyFormatter.string(from: booking.startDate)
    }

    private var formattedTimeRange: String {
        let formatter = DateFormatter.timeOnlyFormatter
        let start = formatter.string(from: booking.startDate)
        let end = formatter.string(from: booking.endDate)
        return "\(start) – \(end)"
    }
}

// MARK: - Section Card Modifier

private struct SectionCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(POSPadding.medium)
            .background(Color.posSurfaceContainerLowest)
            .posItemCardBorderStyles()
    }
}

private extension View {
    func sectionCard() -> some View {
        modifier(SectionCardModifier())
    }
}

// MARK: - Date Formatters

private extension DateFormatter {
    static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let timeOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Navigation

private enum NavigationDestination: Hashable {
    case orderDetail
}

// MARK: - Localization

private enum Localization {
    static let bookingTitle = NSLocalizedString(
        "pos.bookingDetailView.bookingTitle",
        value: "Booking",
        comment: "Default title for the booking detail view when no service name is available."
    )

    static let bookingIdTitle = NSLocalizedString(
        "pos.bookingDetailView.bookingIdTitle",
        value: "Booking #%lld",
        comment: "Section title for booking details showing the booking ID number. %lld is the booking ID."
    )

    static let teamMemberLabel = NSLocalizedString(
        "pos.bookingDetailView.teamMemberLabel",
        value: "Team member",
        comment: "Label for the team member / staff resource in booking details."
    )

    static let locationLabel = NSLocalizedString(
        "pos.bookingDetailView.locationLabel",
        value: "Location",
        comment: "Label for the location in booking details."
    )

    static let durationLabel = NSLocalizedString(
        "pos.bookingDetailView.durationLabel",
        value: "Duration",
        comment: "Label for the duration in booking details."
    )

    static let customerLabel = NSLocalizedString(
        "pos.bookingDetailView.customerLabel",
        value: "Customer",
        comment: "Label for the customer name in booking details."
    )

    static let emailLabel = NSLocalizedString(
        "pos.bookingDetailView.emailLabel",
        value: "Email",
        comment: "Label for the customer email in booking details."
    )

    static let phoneLabel = NSLocalizedString(
        "pos.bookingDetailView.phoneLabel",
        value: "Phone",
        comment: "Label for the customer phone number in booking details."
    )

    static let billingAddressLabel = NSLocalizedString(
        "pos.bookingDetailView.billingAddressLabel",
        value: "Billing address",
        comment: "Label for the billing address in booking details."
    )

    static let customerNoteLabel = NSLocalizedString(
        "pos.bookingDetailView.customerNoteLabel",
        value: "Customer note",
        comment: "Label for the customer note section in booking details."
    )

    static let bookingNoteLabel = NSLocalizedString(
        "pos.bookingDetailView.bookingNoteLabel",
        value: "Booking note",
        comment: "Label for the private booking note section in booking details."
    )

    static let attendanceStatusTitle = NSLocalizedString(
        "pos.bookingDetailView.attendanceStatusTitle",
        value: "Attendance status",
        comment: "Section title for the attendance status in booking details."
    )

    static let attendedPill = NSLocalizedString(
        "pos.bookingDetailView.attendedPill",
        value: "Attended",
        comment: "Label for the attended pill button in booking attendance section."
    )

    static let unattendedPill = NSLocalizedString(
        "pos.bookingDetailView.unattendedPill",
        value: "Unattended",
        comment: "Label for the unattended pill button in booking attendance section."
    )

    static let attendanceSubtitle = NSLocalizedString(
        "pos.bookingDetailView.attendanceSubtitle",
        value: "Mark attendance to keep your reports accurate and spot booking trends.",
        comment: "Subtitle text below the attendance section explaining why marking attendance matters."
    )

    static let taxesLabel = NSLocalizedString(
        "pos.bookingDetailView.taxesLabel",
        value: "Taxes",
        comment: "Label for taxes in booking payment breakdown."
    )

    static let taxesZero = NSLocalizedString(
        "pos.bookingDetailView.taxesZero",
        value: "$0.00",
        comment: "Placeholder for zero taxes in booking payment breakdown."
    )

    static let discountLabel = NSLocalizedString(
        "pos.bookingDetailView.discountLabel",
        value: "Discount",
        comment: "Label for discount in booking payment breakdown."
    )

    static let discountNone = NSLocalizedString(
        "pos.bookingDetailView.discountNone",
        value: "–",
        comment: "Displayed when there is no discount on a booking."
    )

    static let totalLabel = NSLocalizedString(
        "pos.bookingDetailView.totalLabel",
        value: "Total",
        comment: "Label for the total amount in booking payment breakdown."
    )

    static let paidStatusLabel = NSLocalizedString(
        "pos.bookingDetailView.paidStatusLabel",
        value: "Paid",
        comment: "Status label shown when a booking has been paid."
    )

    static let collectPaymentButton = NSLocalizedString(
        "pos.bookingDetailView.collectPaymentButton",
        value: "Collect Payment",
        comment: "Button to initiate payment collection for a booking."
    )

    static let viewOrderAction = NSLocalizedString(
        "pos.bookingDetailView.viewOrderAction",
        value: "View Order",
        comment: "Menu action to view the linked order from a booking detail."
    )
}

// MARK: - Previews

#if DEBUG
#Preview("Paid Booking") {
    POSBookingDetailView(
        booking: POSPreviewHelpers.makePreviewPaidBooking(),
        onBack: {}
    )
}

#Preview("Unpaid Booking") {
    POSBookingDetailView(
        booking: POSPreviewHelpers.makePreviewUnpaidBooking(),
        onBack: {}
    )
}
#endif
