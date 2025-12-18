import SwiftUI
import Foundation
import Combine
import Yosemite


/// Displays a list of marketing events that merchants can schedule actions for
struct MarketingToolsView: View {
    let siteID: Int64

    @StateObject private var viewModel: MarketingToolsViewModel

    init(siteID: Int64) {
        self.siteID = siteID
        _viewModel = StateObject(wrappedValue: MarketingToolsViewModel(siteID: siteID))
    }

    var body: some View {
        List {
            // Action Buttons Section
            Section {
                Button {
                    viewModel.createEvent()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.accentColor)
                        Text("Create Event")
                            .foregroundColor(.primary)
                        Spacer()
                    }
                }

                Button {
                    viewModel.loadSuggestedEvents()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.orange)
                        Text("Suggest Events")
                            .foregroundColor(.primary)
                        Spacer()
                    }
                }
            }

            // Events List Section
            Section {
                if viewModel.events.isEmpty {
                    emptyStateView
                } else {
                    ForEach(viewModel.events) { event in
                        NavigationLink(destination: MarketingEventDetailView(event: event, viewModel: viewModel)) {
                            MarketingEventRowView(event: event)
                        }
                    }
                }
            } header: {
                Text("Marketing Events")
            } footer: {
                Text("Select an event to prepare marketing actions like creating coupons or updating products.")
                    .font(.caption)
            }
        }
        .navigationTitle("Marketing Tools")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No Events Available")
                .font(.headline)

            Text("Marketing events will appear here")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview("Marketing Tools List") {
    NavigationStack {
        MarketingToolsView(siteID: 123)
    }
}

