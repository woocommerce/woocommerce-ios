import SwiftUI
import Networking

struct BookingDetailsView: View {
    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    @ObservedObject private var viewModel: BookingDetailsViewModel

    private enum Layout {
        static let contentSidePadding: CGFloat = 16
        static let contentVerticalPadding: CGFloat = 16
        static let headerContentVerticalPadding: CGFloat = 6
        static let headerBadgesAdditionalTopPadding: CGFloat = 4
        static let sectionFooterTextVerticalPadding: CGFloat = 8
    }

    fileprivate enum TextFont {
        static var bodyMedium: Font {
            Font.body.weight(.medium)
        }

        static var bodyRegular: Font {
            Font.body.weight(.regular)
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
        .background(Color(uiColor: .systemGroupedBackground))
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
        default:
            EmptyView()
        }
    }

    func headerView(with headerContent: BookingDetailsViewModel.HeaderContent) -> some View {
        VStack(alignment: .leading, spacing: Layout.headerContentVerticalPadding) {
            Text(headerContent.bookingDate)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(headerContent.serviceName)
                .font(TextFont.bodyMedium)
            Text(headerContent.customerName)
                .font(TextFont.bodyMedium)
                .foregroundColor(.secondary)
            HStack {
                ForEach(headerContent.status, id: \.self) { status in
                    Text(status.labelText)
                        .font(.caption)
                        .padding(4)
                        .background(status.labelColor)
                        .cornerRadius(4)
                }
            }
            .padding(.top, Layout.headerBadgesAdditionalTopPadding)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
    }

    func attendanceView(with content: BookingDetailsViewModel.AttendanceContent) -> some View {
        TitleAndValueRow(
            title: Localization.statusRowTitle,
            value: .placeholder(content.value),
            selectionStyle: .disclosure,
            horizontalPadding: 0
        )
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
                /// On cancel booking button tap
            } label: {
                Text(Localization.cancelBooking)
            }
            .buttonStyle(SecondaryButtonStyle())
            .padding(.vertical, Layout.contentVerticalPadding)
        }
    }
}

private extension BookingDetailsView {
    enum Localization {
        static let cancelBooking = "Cancel booking"

        /// Attendance section
        static let statusRowTitle = "Status"
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
            cost: "70.00",
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
            localTimezone: "America/New_York"
        )
        let viewModel = BookingDetailsViewModel(booking: sampleBooking)
        return BookingDetailsView(viewModel)
    }
}
#endif
