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
                title: formattedTimeRange,
                backButtonConfiguration: shouldShowBackButton ? .init(state: .enabled, action: onBack) : nil,
                trailingContent: {
                    viewOrderMenu
                },
                bottomContent: {
                    headerSubtitleWithBadges
                }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: POSSpacing.medium) {
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

    // MARK: - Header Subtitle with Badges

    @ViewBuilder
    private var headerSubtitleWithBadges: some View {
        HStack(spacing: POSSpacing.small) {
            if !headerTitle.isEmpty {
                Text(headerTitle)
                    .font(.posBodySmallRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
                    .lineLimit(1)
            }

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
        .padding(.leading, POSPadding.medium)
        .padding(.top, POSPadding.xSmall)
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
                .font(.posBodyMediumBold)
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

    // MARK: - Customer

    @ViewBuilder
    private var customerSection: some View {
        let hasCustomerDetails = booking.customerEmail != nil || booking.customerPhone != nil
            || booking.billingAddress != nil || booking.customerNote != nil
        if hasCustomerDetails {
            VStack(alignment: .leading, spacing: POSSpacing.medium) {
                Text(Localization.customerTitle)
                    .font(.posBodyMediumBold)
                    .foregroundStyle(Color.posOnSurface)

                if let email = booking.customerEmail {
                    HStack {
                        Text(email)
                            .font(.posBodySmallRegular())
                            .foregroundStyle(Color.posOnSurface)
                        Spacer()
                        Image(systemName: "doc.on.doc")
                            .font(.posBodySmallRegular())
                            .foregroundStyle(Color.posOnSurfaceVariantHighest)
                    }
                }

                if let phone = booking.customerPhone {
                    sectionDivider
                    HStack {
                        Text(phone)
                            .font(.posBodySmallRegular())
                            .foregroundStyle(Color.posOnSurface)
                        Spacer()
                        Image(systemName: "ellipsis")
                            .font(.posBodySmallRegular())
                            .foregroundStyle(Color.posOnSurfaceVariantHighest)
                    }
                }

                if let address = booking.billingAddress {
                    sectionDivider
                    stackedField(label: Localization.billingAddressLabel, value: address)
                }

                if let note = booking.customerNote {
                    sectionDivider
                    stackedField(label: Localization.noteLabel, value: note)
                }
            }
            .sectionCard()
        }
    }

    @ViewBuilder
    private func stackedField(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
            Text(label)
                .font(.posCaptionRegular)
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
            Text(value)
                .font(.posBodySmallRegular())
                .foregroundStyle(Color.posOnSurface)
        }
    }

    // MARK: - Booking Note

    @ViewBuilder
    private var bookingNoteSection: some View {
        VStack(alignment: .leading, spacing: POSSpacing.small) {
            VStack(alignment: .leading, spacing: POSSpacing.medium) {
                HStack {
                    Text(Localization.bookingNoteLabel)
                        .font(.posBodyMediumBold)
                        .foregroundStyle(Color.posOnSurface)

                    Spacer()

                    Button(Localization.addNoteButton) {
                        // Add note action — wired in a later milestone
                    }
                    .buttonStyle(POSOutlinedButtonStyle(size: .compact))
                }

                if let note = booking.bookingNote {
                    Text(note)
                        .font(.posBodySmallRegular())
                        .foregroundStyle(Color.posOnSurfaceVariantHighest)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .sectionCard()

            Text(Localization.bookingNoteSubtitle)
                .font(.posCaptionRegular)
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
                .padding(.horizontal, POSPadding.xSmall)
        }
    }

    // MARK: - Attendance Status

    @ViewBuilder
    private var attendanceSection: some View {
        VStack(alignment: .leading, spacing: POSSpacing.small) {
            HStack {
                Text(Localization.attendanceStatusTitle)
                    .font(.posBodyMediumBold)
                    .foregroundStyle(Color.posOnSurface)
                    .lineLimit(1)

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

    // MARK: - Payment Breakdown

    @ViewBuilder
    private var paymentBreakdownSection: some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            Text(Localization.paymentTitle)
                .font(.posBodyMediumBold)
                .foregroundStyle(Color.posOnSurface)

            if !booking.serviceName.isEmpty {
                detailRow(label: Localization.serviceLabel, value: booking.formattedSubtotal ?? booking.formattedAmount)
            }

            detailRow(label: Localization.taxesLabel, value: booking.formattedTax ?? Localization.taxesZero)
            detailRow(label: Localization.discountLabel, value: booking.order.formattedDiscountTotal ?? Localization.discountNone)

            sectionDivider

            HStack {
                Text(Localization.totalLabel)
                    .font(.posBodySmallBold())
                    .foregroundStyle(Color.posOnSurface)
                Spacer()
                Text(booking.formattedAmount)
                    .font(.posBodySmallBold())
                    .foregroundStyle(Color.posOnSurface)
            }
        }
        .sectionCard()
    }

    // MARK: - Payment Action

    @ViewBuilder
    private var paymentActionSection: some View {
        if !isPaid && lifecycleStatus != .cancelled {
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

    static let customerTitle = NSLocalizedString(
        "pos.bookingDetailView.customerTitle",
        value: "Customer",
        comment: "Section title for the customer details in booking details."
    )

    static let noteLabel = NSLocalizedString(
        "pos.bookingDetailView.noteLabel",
        value: "Note",
        comment: "Label for the customer note in booking details."
    )

    static let billingAddressLabel = NSLocalizedString(
        "pos.bookingDetailView.billingAddressLabel",
        value: "Billing address",
        comment: "Label for the billing address in booking details."
    )

    static let bookingNoteLabel = NSLocalizedString(
        "pos.bookingDetailView.bookingNoteLabel",
        value: "Booking note",
        comment: "Label for the private booking note section in booking details."
    )

    static let addNoteButton = NSLocalizedString(
        "pos.bookingDetailView.addNoteButton",
        value: "Add note",
        comment: "Button to add a private note to a booking."
    )

    static let bookingNoteSubtitle = NSLocalizedString(
        "pos.bookingDetailView.bookingNoteSubtitle",
        value: "This is a private note. It'll not be shared with the customer.",
        comment: "Subtitle text below the booking note section explaining the note is private."
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

    static let paymentTitle = NSLocalizedString(
        "pos.bookingDetailView.paymentTitle",
        value: "Payment",
        comment: "Section title for the payment breakdown in booking details."
    )

    static let serviceLabel = NSLocalizedString(
        "pos.bookingDetailView.serviceLabel",
        value: "Service",
        comment: "Label for the service cost in booking payment breakdown."
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

    static let collectPaymentButton = NSLocalizedString(
        "pos.bookingDetailView.collectPaymentButton",
        value: "Collect payment",
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
