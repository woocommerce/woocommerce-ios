import SwiftUI
import Networking

struct BookingDetailsView: View {
    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    @State private var showingOptions = false
    @State private var showingCancelAlert = false
    @State private var cancellingBooking = false
    @State private var updatingAttendance = false
    @State private var markingAsPaid = false
    @State private var notice: Notice?

    @ObservedObject private var viewModel: BookingDetailsViewModel

    enum Layout {
        static let contentSidePadding: CGFloat = 16
        static let contentVerticalPadding: CGFloat = 16
        static let headerContentVerticalPadding: CGFloat = 2
        static let headerBadgeSpacing: CGFloat = 8
        static let headerBadgesAdditionalTopPadding: CGFloat = 6
        static let sectionFooterTextVerticalPadding: CGFloat = 8
        static let rowTextVerticalPadding: CGFloat = 11
        static let contentContainerMaxWidth: CGFloat = 525
    }

    enum TextFont {
        static var bodyMedium: Font {
            Font.body.weight(.medium)
        }
    }

    init(_ viewModel: BookingDetailsViewModel) {
        self.viewModel = viewModel

        /// Trigger remote data sync
        Task {
            await viewModel.syncData()
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .zero) {
                ForEach(viewModel.sections) { section in
                    sectionView(with: section)
                }
            }
        }
        .verticalHairlineBorders()
        .frame(maxWidth: Layout.contentContainerMaxWidth)
        .refreshable {
            await viewModel.syncData()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(viewModel.navigationTitle)
        .background(Color(uiColor: .systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingOptions = true
                } label: {
                    Image(systemName: "ellipsis")
                }
                .confirmationDialog("", isPresented: $showingOptions, titleVisibility: .hidden) {
                    Button(Localization.markAsPaid) {
                        markBookingAsPaid()
                    }
                    .renderedIf(viewModel.shouldShowMarkAsPaid)

                    Button(Localization.viewOrder) {
                        viewModel.navigateToOrderDetails()
                    }
                    .renderedIf(viewModel.isViewOrderAvailable)

                    Button(Localization.cancelBookingAction, role: .destructive) {
                        showingCancelAlert = true
                    }
                    .renderedIf(viewModel.isBookingCancellable)
                }
            }
        }
        .if(UIDevice.current.userInterfaceIdiom == .phone) {
            /// Removes back button title for iPhone layout
            /// Applied only for phones because it affects navigation title positioning on tablets
            $0.toolbarRole(.editor)
        }
        .alert(
            Localization.cancelBookingAlertTitle,
            isPresented: $showingCancelAlert
        ) {
            Button(Localization.cancelBookingAlertCancelAction, role: .cancel) {}
            Button(Localization.cancelBookingAlertConfirmAction, role: .destructive) {
                cancelBooking()
            }
        } message: {
            Text(viewModel.cancellationAlertMessage)
        }
        .notice($notice)
        .notice($viewModel.notice)
    }
}

private extension BookingDetailsView {
    func sectionView(with section: BookingDetailsViewModel.Section) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let header = section.header {
                let text = {
                    switch header {
                    case .empty:
                        return ""
                    case .title(let text):
                        return text
                    }
                }()

                ListHeaderView(
                    text: text,
                    alignment: .left
                )
                .padding(.horizontal, insets: safeAreaInsets)
                .accessibility(addTraits: .isHeader)
            }

            sectionContentView(section.content)
                .padding(.horizontal, Layout.contentSidePadding)
                .background(Color(.listForeground(modal: false)))
                .addingTopAndBottomDividers()

            if let footerText = section.footerText {
                Text(footerText)
                    .padding(.horizontal, Layout.contentSidePadding)
                    .padding(.vertical, Layout.sectionFooterTextVerticalPadding)
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
        }
    }

    @ViewBuilder
    func sectionContentView(_ content: BookingDetailsViewModel.SectionContent) -> some View {
        switch content {
        case .header(let content):
            HeaderView(content: content)
        case .appointmentDetails(let content):
            appointmentDetailsView(with: content)
        case .customer(let content):
            CustomerDetailsView(content: content, showNotice: {
                notice = $0
            })
        case .payment(let content):
            paymentDetailsView(with: content)
        case .bookingNotes(let content):
            BookingNotesRowView(content: content) {
                viewModel.notesTapped()
            } onCommit: { newNote in
                await viewModel.updateNote(to: newNote)
            }

        }
    }

    func appointmentDetailsView(with content: BookingDetailsViewModel.AppointmentDetailsContent)  -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(content.rows) { row in
                TitleAndValueRow(
                    title: row.title,
                    value: .placeholder(row.value),
                    horizontalPadding: 0,
                    isMultiline: false
                )

                Divider()
                    .padding(.trailing, -Layout.contentSidePadding)
            }

            Button {
                updateAttendance()
            } label: {
                Text(viewModel.attendanceButtonTitle)
            }
            .buttonStyle(SecondaryLoadingButtonStyle(isLoading: updatingAttendance))
            .padding(.top, Layout.contentVerticalPadding)
            .renderedIf(viewModel.shouldShowAttendanceButton)

            Button {
                showingCancelAlert = true
            } label: {
                Text(Localization.cancelBooking)
            }
            .buttonStyle(SecondaryLoadingButtonStyle(isLoading: cancellingBooking))
            .padding(.vertical, Layout.contentVerticalPadding)
            .renderedIf(viewModel.isBookingCancellable)
        }
    }

    func paymentDetailsView(with content: BookingDetailsViewModel.PaymentContent) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(content.amounts) { amount in
                    HStack {
                        Text(amount.title)
                        Spacer()
                        Text(amount.value)
                    }
                    .if(!amount.emphasized) { view in
                        view.rowTextStyle()
                    }
                    .if(amount.emphasized) { view in
                        view.font(.body.weight(.bold))
                    }
                }
            }
            .padding(.bottom)

            Divider()
                .padding(.trailing, -Layout.contentSidePadding)

            VStack(alignment: .leading, spacing: Layout.contentVerticalPadding) {
                ForEach(content.actions) { action in
                    switch action {
                    case .viewOrder:
                        Button(action.buttonTitle) {
                            viewModel.navigateToOrderDetails()
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    case .markAsPaid:
                        Button(action.buttonTitle, action: markBookingAsPaid)
                            .buttonStyle(PrimaryLoadingButtonStyle(isLoading: markingAsPaid))
                            .renderedIf(viewModel.shouldShowMarkAsPaid)
                    }
                }
            }
            .padding(.top)
        }
        .padding(.vertical)
    }
}

extension BookingDetailsView {
    func updateAttendance() {
        updatingAttendance = true
        viewModel.updateAttendanceStatus(to: viewModel.targetAttendanceStatus)
        updatingAttendance = false
    }

    func cancelBooking() {
        Task { @MainActor in
            cancellingBooking = true
            do {
                try await viewModel.cancelBooking()
            } catch {
                viewModel.displayBookingCancellationErrorNotice(onRetry: cancelBooking)
            }
            cancellingBooking = false
        }
    }

    func markBookingAsPaid() {
        Task { @MainActor in
            markingAsPaid = true
            do {
                try await viewModel.markBookingAsPaid()
            } catch {
                viewModel.displayMarkingAsPaidErrorNotice(onRetry: markBookingAsPaid)
            }
            markingAsPaid = false
        }
    }
}

extension BookingDetailsView {
    enum Localization {
        static let markAsPaid = NSLocalizedString(
            "BookingDetailsView.options.markAsPaid",
            value: "Mark as paid",
            comment: "Action sheet option to mark a booking as paid."
        )
        static let viewOrder = NSLocalizedString(
            "BookingDetailsView.options.viewOrder",
            value: "View order",
            comment: "Action sheet option to view the order for a booking."
        )
        static let cancelBookingAction = NSLocalizedString(
            "BookingDetailsView.options.cancelBooking",
            value: "Cancel booking",
            comment: "Action sheet option to cancel a booking."
        )

        static let cancelBooking = NSLocalizedString(
            "BookingDetailsView.customer.cancelBookingButton.title",
            value: "Cancel booking",
            comment: "'Cancel booking' button title in appointment details section in booking details view."
        )

        static let cancelBookingAlertTitle = NSLocalizedString(
            "BookingDetailsView.cancelation.alert.title",
            value: "Cancel booking",
            comment: "Title for the booking cancellation confirmation alert."
        )

        static let cancelBookingAlertConfirmAction = NSLocalizedString(
            "BookingDetailsView.cancelation.alert.confirmAction",
            value: "Yes, cancel it",
            comment: "Confirm button title for the booking cancellation confirmation alert."
        )

        static let cancelBookingAlertCancelAction = NSLocalizedString(
            "BookingDetailsView.cancelation.alert.cancelAction",
            value: "No, keep it",
            comment: "Cancel button title for the booking cancellation confirmation alert."
        )

        /// Booking notes
        static let bookingNotesRowText = NSLocalizedString(
            "BookingDetailsView.bookingNote.addNoteRow.title",
            value: "Add note",
            comment: "Add a booking note section in booking details view."
        )

        static let bookingNoteNavbarText = NSLocalizedString(
            "BookingDetailsView.bookingNote.navbar.title",
            value: "Booking note",
            comment: "Title of navigation bar when editing a booking note."
        )
    }
}

#if DEBUG
struct BookingDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        let now = Date()
        let hourFromNow = now.addingTimeInterval(3600)
        let sampleBooking = Booking(
            siteID: 1,
            bookingID: 123,
            allDay: false,
            cost: "$70.00",
            customerID: 456,
            dateCreated: now,
            dateModified: now,
            endDate: hourFromNow,
            googleCalendarEventID: nil,
            orderID: 789,
            orderItemID: 101,
            parentID: 0,
            productID: 112,
            resourceID: 113,
            startDate: now,
            statusKey: "paid",
            attendanceStatusKey: "unattended",
            localTimezone: "America/New_York",
            currency: "USD",
            orderInfo: nil,
            note: ""
        )
        let viewModel = BookingDetailsViewModel(booking: sampleBooking)
        return BookingDetailsView(viewModel)
    }
}
#endif
