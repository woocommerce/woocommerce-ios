import SwiftUI
import struct WooFoundation.WooAnalyticsEvent
import struct Yosemite.POSBooking

struct POSBookingDetailView: View {
    let booking: POSBooking
    let onBack: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    @Environment(POSOrderListModel.self) private var orderListModel
    @Environment(POSBookingsModel.self) private var bookingsModel
    @Environment(\.posAnalytics) private var analytics

    @State private var navigationPath: [NavigationDestination] = []
    @State private var cancelModalState: CancelBookingModalState?
    @State private var showPaymentView = false
    @State private var paymentModel: POSPaymentModel?
    @State private var emailCopied = false
    @State private var emailCopiedTask: Task<Void, Never>?
    @State private var inlineButtonMinY: CGFloat = .infinity
    @State private var stickyButtonHeight: CGFloat = 0
    @State private var scrollViewHeight: CGFloat = 0
    @State private var isDetailsUpdating = false
    @State private var isShowingNoteView = false

    private var actionTintColor: Color {
        colorScheme == .dark ? .posSecondary : .posPrimaryContainer
    }

    private var shouldShowBackButton: Bool {
        horizontalSizeClass == .compact
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
                    case .orderDetailRefund:
                        POSOrderDetailsView(
                            order: booking.order,
                            onBack: { navigationPath.removeLast() },
                            autoStartRefund: true,
                            onRefundSuccess: {
                                Task {
                                    isDetailsUpdating = true
                                    await bookingsModel.updateAfterRefund(bookingID: booking.id)
                                    isDetailsUpdating = false
                                }
                            }
                        )
                        .environment(\.posHeaderBackButtonConfiguration, .init(state: .enabled, action: {
                            navigationPath.removeLast()
                        }))
                    }
                }
        }
        .posFullScreenCover(isPresented: $showPaymentView) {
            if let paymentModel {
                POSBookingPaymentView(booking: booking, paymentModel: paymentModel, onDismiss: dismissPayment)
            }
        }
        .posFullScreenCover(isPresented: $isShowingNoteView) {
            POSBookingNoteView(booking: booking, isShowingNoteView: $isShowingNoteView)
                .posHeaderBackButtonIcon(systemName: "xmark")
        }
    }

    @ViewBuilder
    private var bookingDetailContent: some View {
        VStack(spacing: POSSpacing.none) {
            POSPageHeaderView(
                title: POSBookingDateFormatter.formattedTimeRange(for: booking),
                isLoading: isDetailsUpdating,
                backButtonConfiguration: shouldShowBackButton ? .init(state: .enabled, action: onBack) : nil,
                trailingContent: {
                    viewOrderMenu
                },
                bottomContent: {
                    POSBookingSummaryView(booking: booking)
                        .padding(.top, POSPadding.xSmall)
                }
            )
            .fixedSize(horizontal: false, vertical: true)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)

            ScrollView {
                VStack(alignment: .leading, spacing: POSSpacing.large) {
                    bookingDetailsSection
                    if booking.lifecycleStatus != .cancelled {
                        POSBookingAttendanceSectionView(booking: booking)
                    }
                    customerSection
                    paymentBreakdownSection

                    if shouldShowCollectPayment {
                        collectPaymentButton
                            .background(
                                GeometryReader { geo in
                                    Color.clear.preference(
                                        key: InlineButtonMinYPreferenceKey.self,
                                        value: geo.frame(in: .named("bookingDetailScroll")).minY
                                    )
                                }
                            )
                    }

                    bookingNoteSection
                }
                .padding(.top, POSPadding.xSmall)
                .padding(.horizontal, POSPadding.medium)
                .padding(.bottom, shouldShowCollectPayment ? stickyButtonHeight + POSPadding.medium : POSPadding.medium)
            }
            .coordinateSpace(name: "bookingDetailScroll")
            .measureHeight { scrollViewHeight = $0 }
            .onPreferenceChange(InlineButtonMinYPreferenceKey.self) { value in
                inlineButtonMinY = value
            }
            .overlay(alignment: .bottom) {
                if shouldShowCollectPayment {
                    stickyPaymentOverlay
                }
            }
        }
        .background(Color.posSurface)
        .navigationBarHidden(true)
        .posModal(item: $cancelModalState) { state in
            POSCancelBookingModalContent(
                state: state,
                booking: booking,
                cancelModalState: $cancelModalState
            )
        }
    }

    @ViewBuilder
    private var viewOrderMenu: some View {
        Menu {
            Button(Localization.viewOrderAction) {
                analytics.track(event: WooAnalyticsEvent.PointOfSale.bookingViewOrderTapped(bookingID: booking.id))
                navigationPath.append(.orderDetail)
            }
            if booking.isPaid {
                Button(Localization.issueRefundAction) {
                    analytics.track(event: WooAnalyticsEvent.PointOfSale.bookingIssueRefundTapped(bookingID: booking.id))
                    orderListModel.ordersController.selectOrder(booking.order)
                    navigationPath.append(.orderDetailRefund)
                }
            }
            if booking.isCancellable {
                Button(Localization.cancelBookingAction, role: .destructive) {
                    cancelModalState = .confirmation
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.posBodyLargeBold)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                .foregroundColor(.posOnDisabledContainer)
                .padding(POSPadding.small)
                .accessibilityLabel(Localization.moreActionsAccessibilityLabel)
        }
        .menuIndicator(.hidden)
    }

    // MARK: - Booking Details

    @ViewBuilder
    private var bookingDetailsSection: some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            Text(String(format: Localization.bookingIdTitle, booking.id))
                .font(.posBodyXLargeRegular)
                .foregroundStyle(Color.posOnSurface)
                .accessibilityAddTraits(.isHeader)

            ForEach(Array(bookingDetailRows.enumerated()), id: \.offset) { index, row in
                if index > 0 {
                    sectionDivider
                }
                detailRow(label: row.label, value: row.value)
            }
        }
        .sectionCard()
    }

    private var bookingDetailRows: [(label: String, value: String)] {
        var rows: [(label: String, value: String)] = []
        if let resourceName = booking.resourceName {
            rows.append((Localization.teamMemberLabel, resourceName))
        }
        if let location = booking.location {
            rows.append((Localization.locationLabel, location))
        }
        if !booking.duration.isEmpty {
            rows.append((Localization.durationLabel, booking.duration))
        }
        return rows
    }

    // MARK: - Customer

    @ViewBuilder
    private var customerSection: some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            HStack(spacing: POSSpacing.medium) {
                Text(Localization.customerTitle)
                    .font(.posBodyXLargeRegular)
                    .foregroundStyle(Color.posOnSurface)
                    .accessibilityAddTraits(.isHeader)

                if booking.hasNoCustomerDetails {
                    POSBookingBadgeView(
                        title: Localization.guestBadge,
                        textColor: .posOnDefault,
                        backgroundColor: .posDefault
                    )
                }
            }

            if let email = booking.customerEmail {
                HStack {
                    Text(email)
                        .font(.posBodyMediumRegular())
                        .foregroundStyle(Color.posOnSurface)
                    Spacer()
                    Button {
                        UIPasteboard.general.string = email
                        emailCopied = true
                        emailCopiedTask?.cancel()
                        emailCopiedTask = Task {
                            try? await Task.sleep(for: .seconds(1.5))
                            guard !Task.isCancelled else { return }
                            emailCopied = false
                        }
                    } label: {
                        Image(systemName: emailCopied ? "checkmark" : "doc.on.doc")
                            .font(.posBodyMediumRegular())
                            .foregroundStyle(actionTintColor)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Localization.copyEmailAccessibilityLabel)
                    .frame(minHeight: 32)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Localization.emailAccessibilityLabel(email))
            }

            if let phone = booking.customerPhone {
                sectionDivider
                Text(phone)
                    .font(.posBodyMediumRegular())
                    .foregroundStyle(Color.posOnSurface)
                    .accessibilityLabel(Localization.phoneAccessibilityLabel(phone))
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .sectionCard()
    }

    @ViewBuilder
    private func stackedField(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
            Text(label)
                .font(.posCaptionRegular)
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
            Text(value)
                .font(.posBodyMediumRegular())
                .foregroundStyle(Color.posOnSurface)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Booking Note

    @ViewBuilder
    private var bookingNoteSection: some View {
        VStack(alignment: .leading, spacing: POSSpacing.small) {
            VStack(alignment: .leading, spacing: POSSpacing.medium) {
                sectionTitleWithAction(title: Localization.bookingNoteLabel) {
                    Button(noteButtonTitle) {
                        analytics.track(event: WooAnalyticsEvent.PointOfSale.bookingAddNoteTapped(bookingID: booking.id))
                        isShowingNoteView = true
                    }
                    .buttonStyle(POSOutlinedButtonStyle(size: .compact))
                }

                if let note = booking.bookingNote {
                    Text(note)
                        .font(.posBodyMediumRegular())
                        .foregroundStyle(Color.posOnSurfaceVariantHighest)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .sectionCard()

            Text(Localization.bookingNoteSubtitle)
                .font(.posBodySmallRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
                .padding(.horizontal, POSPadding.xSmall)
        }
    }

    // MARK: - Payment Breakdown

    private var paymentBreakdownSection: some View {
        POSTotalsSectionView(
            sectionTitle: Localization.paymentTitle,
            subtotalLabel: Localization.serviceLabel,
            subtotalAmount: booking.formattedSubtotal ?? booking.order.formattedSubtotal,
            discountAmount: booking.order.formattedDiscountTotal,
            taxAmount: booking.order.formattedTotalTax,
            totalAmount: booking.order.formattedTotal,
            paidAmount: booking.order.formattedPaymentTotal,
            paymentMethodTitle: booking.order.paymentMethodTitle,
            refunds: booking.order.refunds,
            netAmount: booking.order.formattedNetAmount
        )
    }

    // MARK: - Payment Action

    private func dismissPayment() {
        showPaymentView = false
        paymentModel = nil
        Task { @MainActor in
            isDetailsUpdating = true
            await bookingsModel.updateAfterPayment(bookingID: booking.id)
            isDetailsUpdating = false
        }
    }

    private func startPaymentCollection() {
        guard booking.orderID != nil else { return }
        paymentModel = bookingsModel.makePaymentModel(
            for: booking, onDismiss: dismissPayment, analytics: analytics)
        showPaymentView = true
    }

    private var noteButtonTitle: String {
        if booking.bookingNote != nil {
            Localization.editNoteButton
        } else {
            Localization.addNoteButton
        }
    }

    private var shouldShowCollectPayment: Bool {
        !booking.isPaid && booking.lifecycleStatus != .cancelled
    }

    private var collectPaymentButton: some View {
        Button(action: { startPaymentCollection() }) {
            Text("\(Localization.collectPaymentButton) \u{00B7} \(booking.formattedAmount)")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(POSFilledButtonStyle(size: .normal))
    }

    @ViewBuilder
    private var stickyPaymentOverlay: some View {
        let stickyButtonY = scrollViewHeight - stickyButtonHeight + POSPadding.medium
        let isVisible = inlineButtonMinY - stickyButtonY > 0

        VStack(spacing: 0) {
            Divider()
                .overlay(Color.posOutlineVariant)

            collectPaymentButton
                .padding(POSPadding.medium)
                .background(Color.posSurfaceContainerLowest)
        }
        .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: -5)
        .shadow(color: .black.opacity(0.04), radius: 18, x: 0, y: -15)
        .opacity(isVisible ? 1 : 0)
        .allowsHitTesting(isVisible)
        .measureHeight { stickyButtonHeight = $0 }
    }

    // MARK: - Shared Components

    private func sectionTitleWithAction<Action: View>(title: String, @ViewBuilder action: () -> Action) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.posBodyXLargeRegular)
                .foregroundStyle(Color.posOnSurface)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            action()
                .fixedSize(horizontal: true, vertical: false)
        }
    }

    private var sectionDivider: some View {
        Divider()
            .overlay(Color.posOutlineVariant.opacity(0.5))
    }

    @ViewBuilder
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.posBodyMediumRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)

            Spacer()

            Text(value)
                .font(.posBodyMediumRegular())
                .foregroundStyle(Color.posOnSurface)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(value)")
    }
}

// MARK: - POSBooking Presentation Helpers

private extension POSBooking {
    var hasNoCustomerDetails: Bool {
        customerName == nil && customerEmail == nil && customerPhone == nil
            && billingAddress == nil && customerNote == nil
    }
}

// MARK: - Section Card Modifier

struct POSBookingSectionCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(POSPadding.medium)
            .background(Color.posSurfaceContainerLowest)
            .posItemCardBorderStyles()
    }
}

extension View {
    func sectionCard() -> some View {
        modifier(POSBookingSectionCardModifier())
    }
}

// MARK: - Preference Keys

private struct InlineButtonMinYPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .infinity
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = min(value, nextValue())
    }
}

// MARK: - Navigation

private enum NavigationDestination: Hashable {
    case orderDetail
    case orderDetailRefund
}

// MARK: - Localization

private enum Localization {
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

    static let guestBadge = NSLocalizedString(
        "pos.bookingDetailView.guestBadge",
        value: "Guest",
        comment: "Badge label shown next to the customer section title when there is no customer info for a booking."
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

    static let editNoteButton = NSLocalizedString(
        "pos.bookingDetailView.editNoteButton",
        value: "Edit note",
        comment: "Button to edit an existing private note on a booking."
    )

    static let bookingNoteSubtitle = NSLocalizedString(
        "pos.bookingDetailView.bookingNoteSubtitle",
        value: "This is a private note. It'll not be shared with the customer.",
        comment: "Subtitle text below the booking note section explaining the note is private."
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

    static let collectPaymentButton = NSLocalizedString(
        "pos.bookingDetailView.collectPaymentButton",
        value: "Collect payment",
        comment: "Button to initiate payment collection for a booking. The amount is appended after a separator."
    )

    static let viewOrderAction = NSLocalizedString(
        "pos.bookingDetailView.viewOrderAction",
        value: "View Order",
        comment: "Menu action to view the linked order from a booking detail."
    )

    // MARK: - Accessibility

    static func emailAccessibilityLabel(_ email: String) -> String {
        let format = NSLocalizedString(
            "pos.bookingDetailView.email.accessibilityLabel",
            value: "Email: %1$@",
            comment: "Accessibility label for customer email row in booking details. %1$@ is the email address."
        )
        return String(format: format, email)
    }

    static func phoneAccessibilityLabel(_ phone: String) -> String {
        let format = NSLocalizedString(
            "pos.bookingDetailView.phone.accessibilityLabel",
            value: "Phone: %1$@",
            comment: "Accessibility label for customer phone row in booking details. %1$@ is the phone number."
        )
        return String(format: format, phone)
    }

    static let copyEmailAccessibilityLabel = NSLocalizedString(
        "pos.bookingDetailView.copyEmail.accessibilityLabel",
        value: "Copy email address",
        comment: "Accessibility label for the copy email button in booking details."
    )

    static let moreActionsAccessibilityLabel = NSLocalizedString(
        "pos.bookingDetailView.moreActions.accessibilityLabel",
        value: "More actions",
        comment: "Accessibility label for the overflow actions menu button in booking details."
    )

    static let issueRefundAction = NSLocalizedString(
        "pos.bookingDetailView.issueRefundAction",
        value: "Issue Refund",
        comment: "Menu action to issue a full refund for a booking."
    )

    static let cancelBookingAction = NSLocalizedString(
        "pos.bookingDetailView.cancelBookingAction",
        value: "Cancel Booking",
        comment: "Menu action to cancel a booking from the POS booking detail view."
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

#Preview("Guest Booking") {
    POSBookingDetailView(
        booking: POSPreviewHelpers.makePreviewGuestBooking(),
        onBack: {}
    )
}

#Preview("Cancelled Booking") {
    POSBookingDetailView(
        booking: POSPreviewHelpers.makePreviewCancelledBooking(),
        onBack: {}
    )
}
#endif
