import SwiftUI

extension BookingDetailsView {
    struct HeaderView: View {
        @ObservedObject var content: BookingDetailsViewModel.HeaderContent

        var body: some View {
            VStack(alignment: .leading, spacing: Layout.headerContentVerticalPadding) {
                Text(content.bookingDate)
                    .font(TextFont.bodyMedium)
                    .foregroundColor(.primary)
                Text(content.serviceAndCustomerLine)
                    .font(.footnote.weight(.medium))
                    .foregroundColor(.secondary)
                HStack {
                    ForEach(content.status, id: \.self) { status in
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
    }
}
