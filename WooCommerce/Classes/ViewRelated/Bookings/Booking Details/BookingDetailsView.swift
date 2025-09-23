import SwiftUI
import WooFoundation
import Networking

struct BookingDetailsView: View {
    @ObservedObject var viewModel: BookingDetailsViewModel

    enum Layout {
        static let contentSidePadding: CGFloat = 16
        static let headerContentVerticalPadding: CGFloat = 6
        static let headerBadgesAdditionalTopPadding: CGFloat = 4
    }

    enum TextFont {
        static let headerBodyText = Font.body.weight(.medium)
    }

    enum ColorConstants {
        static let bookingStatusLabel: Color = .gray
    }

    func sectionView(with section: BookingDetailsViewModel.Section) -> some View {
        VStack(alignment: .leading, spacing: Layout.headerContentVerticalPadding) {
            if let headerText = section.headerText {
                Text(headerText)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            switch section.content {
            case .header(let content):
                headerView(with: content)
            case .appointmentDetails(let content):
                appointmentDetailsView(with: content)
            default:
                EmptyView()
            }

            if let footerText = section.footerText {
                Text(footerText)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }

    func headerView(with headerContent: BookingDetailsViewModel.HeaderContent) -> some View {
        VStack(alignment: .leading, spacing: Layout.headerContentVerticalPadding) {
            Text(headerContent.bookingDate)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(headerContent.serviceName)
                .font(TextFont.headerBodyText)
            Text(headerContent.customerName)
                .font(TextFont.headerBodyText)
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
    }

    func appointmentDetailsView(with content: BookingDetailsViewModel.AppointmentDetailsContent)  -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(content.rows) { row in
                DetailRow(title: row.title, value: row.value)
                Divider()
            }
        }
    }

    var body: some View {
        RefreshablePlainList(action: {
            print("Refresh triggered")
        }) {
            VStack(alignment: .leading) {
                ForEach(viewModel.sections) { section in
                    sectionView(with: section)
                        .padding(.horizontal)

                    Divider()
                }
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(uiColor: .listBackground))
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    var isBold: Bool = false

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(isBold ? .bold : .regular)
        }
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
        return BookingDetailsView(viewModel: viewModel)
    }
}
#endif
