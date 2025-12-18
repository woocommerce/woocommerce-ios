import SwiftUI

struct MarketingEventRowView: View {
    let event: MarketingEvent

    var body: some View {
        HStack(spacing: 12) {
            // Event icon
            Image(systemName: event.type.iconName)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color.accentColor)
                )

            // Event details
            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

        }
        .padding(.vertical, 4)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: event.date)
    }
}

#Preview("Event Row") {
    List {
        MarketingEventRowView(event: MarketingEvent(
            id: "1",
            name: "Black Friday 2025",
            date: Date(),
            type: .blackFriday
        ))

        MarketingEventRowView(event: MarketingEvent(
            id: "2",
            name: "Holiday Sale 2025",
            date: Date().addingTimeInterval(86400 * 30),
            type: .holidaySale
        ))
    }
}
