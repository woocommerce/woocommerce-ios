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

    var body: some View {
        RefreshablePlainList(action: {
            print("Refresh triggered")
        }) {
            VStack(alignment: .leading) {
                headerView
                .padding(.horizontal)

                Divider()
//
//                // Appointment Details
//                appointmentDetailsSectionView
//                .padding(.horizontal)
//
//                VStack(spacing: 12) {
//                    Button(action: {
//                        viewModel.rescheduleBooking()
//                    }) {
//                        Text("Reschedule")
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(Color.white)
//                            .border(Color.gray, width: 1)
//                            .cornerRadius(8)
//                    }
//
//                    Button(action: {
//                        viewModel.cancelBooking()
//                    }) {
//                        Text("Cancel booking")
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(Color.white)
//                            .border(Color.gray, width: 1)
//                            .cornerRadius(8)
//                    }
//                }
//                .padding(.horizontal)
//
//                Divider()
//
//                // Payment Details
//                VStack(alignment: .leading, spacing: 16) {
//                    Text("PAYMENT")
//                        .font(.caption)
//                        .foregroundColor(.gray)
//
//                    DetailRow(title: "Services", value: viewModel.servicesCost)
//                    DetailRow(title: "Tax", value: viewModel.tax)
//                    DetailRow(title: "Total", value: viewModel.total, isBold: true)
//                    DetailRow(title: "Paid", value: viewModel.paid, isBold: true)
//                }
//                .padding(.horizontal)
//
//                VStack(spacing: 12) {
//                    Button(action: {
//                        viewModel.markAsPaid()
//                    }) {
//                        Text("Mark as paid")
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(Color.accentColor)
//                            .foregroundColor(.white)
//                            .cornerRadius(8)
//                    }
//
//                    Button(action: {
//                        viewModel.viewOrder()
//                    }) {
//                        Text("View order")
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(Color.white)
//                            .border(Color.gray, width: 1)
//                            .cornerRadius(8)
//                    }
//                }
//                .padding(.horizontal)
//
//                Divider()
//
//                // Customer Details
//                VStack(alignment: .leading, spacing: 16) {
//                    Text("CUSTOMER")
//                        .font(.caption)
//                        .foregroundColor(.gray)
//
//                    Text(viewModel.customerName).font(.headline)
//                    Text(viewModel.customerEmail)
//                    Text(viewModel.customerPhone)
//
//                    Text("Billing address").font(.headline).padding(.top)
//                    Text(viewModel.billingAddress)
//                }
//                .padding(.horizontal)
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

private extension BookingDetailsView {
    var headerView: some View {
        VStack(alignment: .leading, spacing: Layout.headerContentVerticalPadding) {
            Text(viewModel.bookingDate)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(viewModel.serviceName)
                .font(TextFont.headerBodyText)
            Text(viewModel.customerName)
                .font(TextFont.headerBodyText)
                .foregroundColor(.secondary)
            HStack {
                ForEach(viewModel.status, id: \.self) { status in
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

//    var appointmentDetailsSectionView: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            Text("APPOINTMENT DETAILS")
//                .font(.caption)
//                .foregroundColor(.gray)
//
//            DetailRow(title: "Date", value: viewModel.appointmentDate)
//            DetailRow(title: "Time", value: viewModel.appointmentTime)
//            DetailRow(title: "Service", value: viewModel.service)
//            DetailRow(title: "Quantity", value: "\(viewModel.quantity)")
//            DetailRow(title: "Duration", value: viewModel.duration)
//            DetailRow(title: "Cost", value: viewModel.cost)
//        }
//    }
}

extension BookingDetailsViewModel.Status {
    var labelText: String {
        switch self {
        case .booked:
            return "Booked"
        case .paid:
            return "Paid"
        }
    }

    var labelColor: Color {
        switch self {
        case .booked:
            return Color(UIColor.systemGray6)
        case .paid:
            return Color(UIColor.systemGray6)
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
