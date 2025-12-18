import SwiftUI

/// Detail view for a marketing event showing available actions
struct MarketingEventDetailView: View {
    let event: MarketingEvent
    @ObservedObject var viewModel: MarketingToolsViewModel

    var body: some View {
        List {
            Section {
                LabeledContent("Date", value: formattedDate)
                LabeledContent("Type", value: event.type.displayName)
            } header: {
                Text("Event Details")
            }

            // Actions
            Section {
                ForEach(viewModel.availableActions(for: event)) { action in
                    Button {
                        viewModel.handleActionTap(action: action, for: event)
                    } label: {
                        MarketingActionRowView(action: action)
                    }
                }
            } header: {
                Text("Choose Action")
            } footer: {
                Text("Select an action to prepare for this marketing event.")
                    .font(.caption)
            }
        }
        .navigationTitle(event.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: event.date)
    }
}

/// Row view for displaying an action option
private struct MarketingActionRowView: View {
    let action: MarketingAction

    var body: some View {
        HStack(spacing: 12) {
            // Action icon
            Image(systemName: action.iconName)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 30)

            // Action details
            VStack(alignment: .leading, spacing: 4) {
                Text(action.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(action.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview("Event Detail") {
    NavigationStack {
        MarketingEventDetailView(
            event: MarketingEvent(
                id: "1",
                name: "Black Friday 2025",
                date: Date(),
                type: .blackFriday
            ),
            viewModel: MarketingToolsViewModel(siteID: 123)
        )
    }
}
