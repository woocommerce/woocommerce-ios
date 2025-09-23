import SwiftUI
import WooFoundation
import Networking

struct BookingDetailsView: View {
    @ObservedObject private var viewModel: BookingDetailsViewModel

    private enum Layout {
        static let contentSidePadding: CGFloat = 16
        static let headerContentVerticalPadding: CGFloat = 6
        static let headerBadgesAdditionalTopPadding: CGFloat = 4
        static let appointmentDetailsRowVerticalPadding: CGFloat = 6
    }

    fileprivate enum TextFont {
        static var bodyMedium: Font {
            Font.body.weight(.medium)
        }

        static var bodyRegular: Font {
            Font.body.weight(.regular)
        }
    }

    private enum ColorConstants {
        static var bookingStatusLabel: Color {
            return .gray
        }
    }

    init(_ viewModel: BookingDetailsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        RefreshablePlainList(action: {
            print("Refresh triggered")
        }) {
            VStack(alignment: .leading, spacing: .zero) {
                ForEach(viewModel.sections) { section in
                    sectionView(with: section)
                    Divider()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

private extension BookingDetailsView {
    func sectionView(with section: BookingDetailsViewModel.Section) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let headerText = section.headerText {
                Text(headerText)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.vertical)
                    .padding(.horizontal, Layout.contentSidePadding)
                Divider()
            }

            sectionContentView(section.content)
                .padding(.horizontal, Layout.contentSidePadding)
                .padding(.vertical, 10)
                .background(Color(uiColor: .listBackground))

            if let footerText = section.footerText {
                Divider()
                Text(footerText)
                    .padding(.horizontal, Layout.contentSidePadding)
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

    func appointmentDetailsView(with content: BookingDetailsViewModel.AppointmentDetailsContent)  -> some View {
        VStack(alignment: .leading) {
            ForEach(content.rows) { row in
                DetailRow(title: row.title, value: row.value)
                    .padding(.vertical, Layout.appointmentDetailsRowVerticalPadding)

                if row.id != content.rows.last?.id {
                    Divider()
                        .padding(.trailing, -Layout.contentSidePadding)
                }
            }
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    var body: some View {
        HStack {
            Text(title)
                .font(BookingDetailsView.TextFont.bodyMedium)
            Spacer()
            Text(value)
                .font(BookingDetailsView.TextFont.bodyRegular)
                .foregroundColor(.secondary)
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
        return BookingDetailsView(viewModel)
    }
}
#endif
