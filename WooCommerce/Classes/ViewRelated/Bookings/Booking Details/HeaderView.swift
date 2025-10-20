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
                if !content.serviceAndCustomerLine.isEmpty {
                    Text(content.serviceAndCustomerLine)
                        .font(.footnote.weight(.medium))
                        .foregroundColor(.secondary)
                }
                HStack {
                    ForEach(content.status, id: \.self) { statusString in
                        Text(statusString)
                            .font(.caption2)
                            .padding(.vertical, 4.5)
                            .padding(.horizontal, 8)
                            .background(
                                BookingDetailsView.Layout.defaultBadgeColor
                            )
                            .cornerRadius(4)
                    }
                }
                .padding(.top, Layout.headerBadgesAdditionalTopPadding)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical)
        }
    }
}
