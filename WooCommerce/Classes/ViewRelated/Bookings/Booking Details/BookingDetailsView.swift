import SwiftUI
import WooFoundation
import Networking

struct BookingDetailsView: View {
    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    @ObservedObject private var viewModel: BookingDetailsViewModel

    private enum Layout {
        static let contentSidePadding: CGFloat = 16
        static let headerContentVerticalPadding: CGFloat = 6
        static let headerBadgesAdditionalTopPadding: CGFloat = 4
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
        RefreshablePlainList(action: {
            print("Refresh triggered")
        }) {
            VStack(alignment: .leading, spacing: .zero) {
                ForEach(viewModel.sections) { section in
                    sectionView(with: section)
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
                ListHeaderView(
                    text: headerText,
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
        VStack(alignment: .leading, spacing: 0) {
            ForEach(content.rows) { row in
                TitleAndTextFieldRow(
                    title: row.title,
                    placeholder: String(),
                    text: .constant(row.value),
                    fieldAlignment: .trailing,
                    keyboardType: .default,
                    titleFont: BookingDetailsView.TextFont.bodyMedium,
                    valueColor: .secondary,
                    valueFont: BookingDetailsView.TextFont.bodyRegular,
                    horizontalPadding: 0 // Parent section padding is added elsewhere,
                )

                if row.id != content.rows.last?.id {
                    Divider()
                        .padding(.trailing, -Layout.contentSidePadding)
                }
            }
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
