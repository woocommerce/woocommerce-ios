import SwiftUI

extension BookingDetailsView {
    struct HeaderView: View {
        @ObservedObject var content: BookingDetailsViewModel.HeaderContent

        var body: some View {
            VStack(alignment: .leading, spacing: Layout.headerContentVerticalPadding) {
                if !content.bookingDate.isEmpty {
                    Text(content.bookingDate)
                        .font(TextFont.bodyMedium)
                        .foregroundColor(.primary)
                }
                if !content.serviceLine.isEmpty {
                    Text(content.serviceLine)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                if !content.customerLine.isEmpty {
                    Text(content.customerLine)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                BookingBadgeView(content.statusBadge)
                .padding(.top, Layout.headerBadgesAdditionalTopPadding)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical)
        }
    }
}
