import SwiftUI
import struct Yosemite.POSBooking

struct POSBookingDetailView: View {
    let booking: POSBooking
    let onBack: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(POSOrderListModel.self) private var orderListModel

    @State private var navigationPath: [NavigationDestination] = []
    @State private var refundModalState: RefundModalState?
    @State private var isShowingEmailReceiptView: Bool = false

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
                title: booking.serviceName.isEmpty ? Localization.bookingTitle : booking.serviceName,
                backButtonConfiguration: shouldShowBackButton ? .init(state: .enabled, action: onBack) : nil,
                trailingContent: {
                    viewOrderMenu
                }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: POSSpacing.medium) {
                    headerSection
                    bookingDetailsSection
                    customerSection
                    customerNoteSection
                    attendanceSection
                    paymentBreakdownSection
                    paymentActionSection
                }
                .padding(.top, POSPadding.xSmall)
                .padding(.horizontal, POSPadding.medium)
                .padding(.bottom, POSPadding.medium)
            }
        }
        .background(Color.posSurface)
        .navigationBarHidden(true)
        .posFullScreenCover(isPresented: $isShowingEmailReceiptView) {
            POSSendReceiptView(isShowingSendReceiptView: $isShowingEmailReceiptView) { email in
                try await orderListModel.sendReceipt(order: booking.order, email: email)
            }
            .posHeaderBackButtonIcon(systemName: "xmark")
        }
        .posModal(item: $refundModalState, onDismiss: {
            orderListModel.ordersController.clearRefundSelection()
        }) { state in
            bookingRefundModalContent(for: state)
        }
    }

    @ViewBuilder
    private var viewOrderMenu: some View {
        Menu {
            Button(Localization.viewOrderAction) {
                navigationPath.append(.orderDetail)
            }
            if isPaid && lifecycleStatus != .cancelled {
                Button(Localization.issueRefundAction) {
                    initiateBookingRefundFlow()
                }
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

    // MARK: - Section 1: Header

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
            Text(formattedTimeRange)
                .font(.posBodySmallRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)

            Text(headerTitle)
                .font(.posBodySmallBold())
                .foregroundStyle(Color.posOnSurface)

            HStack(spacing: POSSpacing.small) {
                Text(attendanceDisplay.localizedTitle)
                    .font(.posBodySmallRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)

                Text(paymentStatus.localizedTitle)
                    .font(.posBodySmallRegular())
                    .foregroundStyle(paymentStatus.color)

                if lifecycleStatus.shouldShowBadge {
                    Text(lifecycleStatus.localizedTitle)
                        .font(.posBodySmallRegular())
                        .foregroundStyle(lifecycleStatus.badgeColor)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sectionCard()
    }

    private var headerTitle: String {
        let parts = [booking.serviceName, booking.customerName].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.joined(separator: " \u{00B7} ")
    }

    // MARK: - Section 2: Booking Details

    @ViewBuilder
    private var bookingDetailsSection: some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            detailRow(label: Localization.dateLabel, value: formattedDate)
            detailRow(label: Localization.timeLabel, value: formattedTimeRange)

            if let resourceName = booking.resourceName {
                detailRow(label: Localization.teamMemberLabel, value: resourceName)
            }

            if let location = booking.location {
                detailRow(label: Localization.locationLabel, value: location)
            }

            if !booking.duration.isEmpty {
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

    // MARK: - Section 4: Customer Note

    @ViewBuilder
    private var customerNoteSection: some View {
        if let note = booking.customerNote {
            VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                Text(Localization.customerNoteLabel)
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

    // MARK: - Section 5: Attendance Status

    @ViewBuilder
    private var attendanceSection: some View {
        HStack {
            Text(Localization.attendanceLabel)
                .font(.posBodySmallRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)

            Spacer()

            Text(attendanceDisplay.localizedTitle)
                .font(.posBodySmallBold())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
        }
        .sectionCard()
    }

    // MARK: - Section 6: Payment Breakdown

    @ViewBuilder
    private var paymentBreakdownSection: some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            if !booking.serviceName.isEmpty {
                detailRow(label: booking.serviceName, value: booking.formattedSubtotal ?? booking.formattedAmount)
            }

            detailRow(label: Localization.taxesLabel, value: booking.formattedTax ?? Localization.taxesZero)
            detailRow(label: Localization.discountLabel, value: Localization.discountNone)

            Divider()
                .overlay(Color.posOutlineVariant.opacity(0.5))

            detailRow(label: Localization.totalLabel, value: booking.formattedAmount)
        }
        .sectionCard()
    }

    // MARK: - Section 7: Payment Action / Status

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

// MARK: - Booking Refund Flow

private extension POSBookingDetailView {
    func initiateBookingRefundFlow() {
        orderListModel.ordersController.selectOrder(booking.order)
        refundModalState = .loading
        Task { @MainActor in
            let result = await orderListModel.ordersController.startRefundFlow()
            switch result {
            case .hasItemsToRefund:
                // Skip item selection state. With POS Bookings we only allow full refunds at the moment
                navigateToRefundReview()
            case .nothingToRefund:
                refundModalState = .nothingToRefund
            case .failed:
                refundModalState = .loadingError
            }
        }
    }

    func navigateToRefundReview() {
        guard let reviewData = orderListModel.ordersController.preparePOSRefundReviewData() else {
            refundModalState = .preparationError
            return
        }
        refundModalState = .review(reviewData)
    }

    @MainActor
    func processRefund(reviewData: POSRefundReviewData) async {
        do {
            try await orderListModel.ordersController.processRefund(reason: reviewData.refundReason)
            refundModalState = .success(reviewData)
        } catch {
            refundModalState = .error(reviewData)
        }
    }

    @ViewBuilder
    func bookingRefundModalContent(for state: RefundModalState) -> some View {
        switch state {
        case .loading:
            POSRefundLoadingView()
        case .loadingError:
            POSRefundErrorView(
                title: Localization.loadRefundErrorTitle,
                subtitle: Localization.loadRefundErrorSubtitle,
                onRetry: { initiateBookingRefundFlow() },
                onCancel: { refundModalState = nil },
                onClose: { refundModalState = nil }
            )
        case .preparationError:
            POSRefundErrorView(
                title: Localization.prepareRefundErrorTitle,
                subtitle: Localization.prepareRefundErrorSubtitle,
                onRetry: { initiateBookingRefundFlow() },
                onCancel: { refundModalState = nil },
                onClose: { refundModalState = nil }
            )
        case .nothingToRefund:
            POSRefundNothingToRefundView(onClose: { refundModalState = nil })
        case .itemSelection:
            // Not used for booking refunds — included for exhaustive switch
            EmptyView()
        case .review(let reviewData):
            POSRefundReviewView(
                onClose: { refundModalState = nil },
                itemsCount: reviewData.itemsCount,
                formattedItemsSubtotal: reviewData.formattedItemsSubtotal,
                formattedTax: reviewData.formattedTax,
                formattedRefundTotal: reviewData.formattedRefundTotal,
                paymentMethodDescription: reviewData.paymentMethodDescription,
                refundReason: reviewData.refundReason,
                onAddReason: { refundModalState = .reasonInput(reviewData) },
                onContinue: { refundModalState = .confirmation(reviewData) },
                onEditRefund: nil
            )
        case .reasonInput(let reviewData):
            POSRefundReasonView(
                initialReason: reviewData.refundReason,
                onSave: { reason in
                    var updated = reviewData
                    updated.refundReason = reason
                    refundModalState = .review(updated)
                },
                onBack: { refundModalState = .review(reviewData) },
                onClose: { refundModalState = nil }
            )
        case .confirmation(let reviewData):
            POSRefundConfirmationView(
                formattedRefundTotal: reviewData.formattedRefundTotal,
                paymentMethodDescription: reviewData.paymentMethodDescription,
                isProcessing: false,
                onClose: { refundModalState = nil },
                onConfirm: {
                    refundModalState = .processing(reviewData)
                    Task { @MainActor in
                        await processRefund(reviewData: reviewData)
                    }
                },
                onBack: { refundModalState = .review(reviewData) }
            )
        case .processing(let reviewData):
            POSRefundConfirmationView(
                formattedRefundTotal: reviewData.formattedRefundTotal,
                paymentMethodDescription: reviewData.paymentMethodDescription,
                isProcessing: true,
                onClose: {},
                onConfirm: {},
                onBack: {}
            )
        case .success(let reviewData):
            POSRefundSuccessView(
                formattedRefundTotal: reviewData.formattedRefundTotal,
                paymentMethodDescription: reviewData.paymentMethodDescription,
                onDone: { refundModalState = nil },
                onEmailReceipt: {
                    refundModalState = nil
                    Task { @MainActor in
                        isShowingEmailReceiptView = true
                    }
                },
                onClose: { refundModalState = nil }
            )
        case .error(let reviewData):
            POSRefundErrorView(
                title: Localization.createRefundErrorTitle,
                subtitle: Localization.createRefundErrorSubtitle,
                onRetry: { refundModalState = .confirmation(reviewData) },
                onCancel: { refundModalState = nil },
                onClose: { refundModalState = nil }
            )
        }
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

    static let dateLabel = NSLocalizedString(
        "pos.bookingDetailView.dateLabel",
        value: "Date",
        comment: "Label for the date in booking details."
    )

    static let timeLabel = NSLocalizedString(
        "pos.bookingDetailView.timeLabel",
        value: "Time",
        comment: "Label for the time range in booking details."
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

    static let attendanceLabel = NSLocalizedString(
        "pos.bookingDetailView.attendanceLabel",
        value: "Attendance",
        comment: "Label for the booking attendance status in booking details."
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

    static let issueRefundAction = NSLocalizedString(
        "pos.bookingDetailView.issueRefundAction",
        value: "Issue Refund",
        comment: "Menu action to issue a full refund for a booking."
    )

    static let loadRefundErrorTitle = NSLocalizedString(
        "pos.bookingDetailView.loadRefundError.title",
        value: "Couldn't load refund details",
        comment: "Title shown when loading refund information for a booking has failed."
    )

    static let loadRefundErrorSubtitle = NSLocalizedString(
        "pos.bookingDetailView.loadRefundError.subtitle",
        value: "Please try again.",
        comment: "Subtitle shown when loading refund information for a booking has failed."
    )

    static let prepareRefundErrorTitle = NSLocalizedString(
        "pos.bookingDetailView.prepareRefundError.title",
        value: "Couldn't prepare refund",
        comment: "Title shown when refund data preparation for a booking fails."
    )

    static let prepareRefundErrorSubtitle = NSLocalizedString(
        "pos.bookingDetailView.prepareRefundError.subtitle",
        value: "Please try again.",
        comment: "Subtitle shown when refund data preparation for a booking fails."
    )

    static let createRefundErrorTitle = NSLocalizedString(
        "pos.bookingDetailView.createRefundError.title",
        value: "Failed to create refund",
        comment: "Title shown when a booking refund creation has failed."
    )

    static let createRefundErrorSubtitle = NSLocalizedString(
        "pos.bookingDetailView.createRefundError.subtitle",
        value: "Please try again.",
        comment: "Subtitle shown when a booking refund creation has failed."
    )
}
