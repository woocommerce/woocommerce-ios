import SwiftUI
import Networking

struct BookingDetailsView: View {
    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    @State private var showingOptions = false
    @State private var showingStatusSheet = false
    @State private var showingCancelAlert = false

    @ObservedObject private var viewModel: BookingDetailsViewModel

    private enum Layout {
        static let contentSidePadding: CGFloat = 16
        static let contentVerticalPadding: CGFloat = 16
        static let headerContentVerticalPadding: CGFloat = 6
        static let headerBadgesAdditionalTopPadding: CGFloat = 4
        static let sectionFooterTextVerticalPadding: CGFloat = 8
        static let rowTextVerticalPadding: CGFloat = 11
    }

    fileprivate enum TextFont {
        static var bodyMedium: Font {
            Font.body.weight(.medium)
        }
    }

    init(_ viewModel: BookingDetailsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .zero) {
                ForEach(viewModel.sections) { section in
                    sectionView(with: section)
                }
            }
        }
        .refreshable {
            print("Refresh triggered")
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
                        print("On mark as paid tap")
                    }
                    Button(Localization.viewOrder) {
                        print("On view order tap")
                    }
                    Button(Localization.cancelBookingAction, role: .destructive) {
                        print("On cancel booking tap")
                    }
                }
            }
        }
        .if(UIDevice.current.userInterfaceIdiom == .phone) {
            /// Removes back button title for iPhone layout
            /// Applied only for phones because it affects navigation title positioning on tablets
            $0.toolbarRole(.editor)
        }
        .sheet(isPresented: $showingStatusSheet) {
            UpdateAttendanceStatusView { selectedStatus in
                print("Selected status: \(selectedStatus)")
            }
            .padding(.top)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .alert(
            Localization.cancelBookingAlertTitle,
            isPresented: $showingCancelAlert
        ) {
            Button(Localization.cancelBookingAlertCancelAction, role: .cancel) {}
            Button(Localization.cancelBookingAlertConfirmAction, role: .destructive) {
                print("On cancel booking confirmation tap")
            }
        } message: {
            Text(viewModel.cancellationAlertMessage)
        }
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
                .background(Color(.systemBackground))
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
            headerView(with: content)
        case .appointmentDetails(let content):
            appointmentDetailsView(with: content)
        case .attendance(let content):
            attendanceView(with: content)
        case .customer(let content):
            customerDetailsView(with: content)
        case .payment(let content):
            paymentDetailsView(with: content)
        case .bookingNotes:
            bookingNotesView()
        }
    }

    func headerView(with headerContent: BookingDetailsViewModel.HeaderContent) -> some View {
        VStack(alignment: .leading, spacing: Layout.headerContentVerticalPadding) {
            Text(headerContent.bookingDate)
                .font(TextFont.bodyMedium)
                .foregroundColor(.primary)
            Text(headerContent.serviceAndCustomerLine)
                .font(.footnote.weight(.medium))
                .foregroundColor(.secondary)
            HStack {
                ForEach(headerContent.status, id: \.self) { status in
                    Text(status.labelText)
                        .font(.caption2)
                        .padding(.vertical, 4.5)
                        .padding(.horizontal, 8)
                        .background(status.labelColor)
                        .cornerRadius(4)
                }
            }
            .padding(.top, Layout.headerBadgesAdditionalTopPadding)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical)
    }

    func attendanceView(with content: BookingDetailsViewModel.AttendanceContent) -> some View {
        TitleAndValueRow(
            title: Localization.statusRowTitle,
            value: .placeholder(content.value),
            selectionStyle: .disclosure,
            horizontalPadding: 0
        ) {
            showingStatusSheet = true
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
                showingCancelAlert = true
            } label: {
                Text(Localization.cancelBooking)
            }
            .buttonStyle(SecondaryButtonStyle())
            .padding(.vertical, Layout.contentVerticalPadding)
        }
    }

    func customerDetailsView(with content: BookingDetailsViewModel.CustomerContent) -> some View {
        VStack(spacing: 0) {
            /// Name
            HStack {
                Text(content.nameText)
                    .rowTextStyle()
                Spacer()
            }
            .padding(.vertical, Layout.rowTextVerticalPadding)

            Divider()
                .padding(.trailing, -Layout.contentSidePadding)

            /// Email
            HStack {
                Text(content.emailText)
                    .rowTextStyle()
                Spacer()
                Image(systemName: "doc.on.doc")
                    .font(TextFont.bodyMedium)
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.vertical, Layout.rowTextVerticalPadding)
            .tappable {
                print("On email copy")
            }

            Divider()
                .padding(.trailing, -Layout.contentSidePadding)

            /// Phone
            HStack {
                Text(content.phoneText)
                    .rowTextStyle()
                Spacer()
                Image(systemName: "ellipsis")
                    .font(TextFont.bodyMedium)
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.vertical, Layout.rowTextVerticalPadding)
            .tappable {
                print("On phone ellipsis")
            }

            Divider()
                .padding(.trailing, -Layout.contentSidePadding)

            /// Billing address
            if let billingAddressText = content.billingAddressText, !billingAddressText.isEmpty {
                HStack {
                    VStack(alignment: .leading) {
                        Text(Localization.billingAddressRowTitle)
                            .rowTextStyle()
                        Text(billingAddressText)
                            .font(TextFont.bodyMedium)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                }
                .padding(.vertical, Layout.rowTextVerticalPadding)
            }
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
                    Button {
                        /// On action tap
                    } label: {
                        Text(action.buttonTitle)
                    }
                    .if(action.isEmphasized) {
                        $0.buttonStyle(PrimaryButtonStyle())
                    }
                    .if(!action.isEmphasized) {
                        $0.buttonStyle(SecondaryButtonStyle())
                    }
                }
            }
            .padding(.top)
        }
        .padding(.vertical)
    }

    func bookingNotesView() -> some View {
        HStack(spacing: Layout.contentSidePadding) {
            Image(systemName: "plus")
                .font(.title3.weight(.medium))
            Text(Localization.bookingNotesRowText)
                .rowTextStyle()
            Spacer()
        }
        .foregroundStyle(Color.accentColor)
        .padding(.vertical, Layout.rowTextVerticalPadding)
        .tappable {
            print("On Add a note tap")
        }
    }
}

private struct RowTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(BookingDetailsView.TextFont.bodyMedium)
            .foregroundStyle(.primary)
            .multilineTextAlignment(.leading)
    }
}

private extension View {
    func rowTextStyle() -> some View {
        self.modifier(RowTextStyle())
    }
}

private extension BookingDetailsView {
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

        /// Attendance section
        static let statusRowTitle = NSLocalizedString(
            "BookingDetailsView.customer.status.title",
            value: "Status",
            comment: "'Status' row title in attendance section in booking details view."
        )

        /// Customer section
        static let billingAddressRowTitle = NSLocalizedString(
            "BookingDetailsView.customer.billingAddress.title",
            value: "Billing address",
            comment: "Billing address row title in customer section in booking details view."
        )

        /// Booking notes
        static let bookingNotesRowText = NSLocalizedString(
            "BookingDetailsView.bookingNotes.addANoteRow.title",
            value: "Add a note",
            comment: "Add a note row title in booking notes section in booking details view."
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
            localTimezone: "America/New_York",
            currency: "USD"
        )
        let viewModel = BookingDetailsViewModel(booking: sampleBooking)
        return BookingDetailsView(viewModel)
    }
}
#endif
