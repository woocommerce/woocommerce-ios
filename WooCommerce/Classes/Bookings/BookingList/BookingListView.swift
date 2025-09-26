import SwiftUI

struct BookingListView: View {
    @ObservedObject private var viewModel: BookingListViewModel

    init(viewModel: BookingListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            VStack {
                headerView
                contentView

                Spacer()
            }
            .navigationTitle(Localization.viewTitle)
            .toolbarBackground(Color.clear, for: .navigationBar)
            .safeAreaInset(edge: .top) {
                Color.clear
                    .frame(height: 0)
                    .background(Material.bar)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        // TODO
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
        }
    }
}

private extension BookingListView {
    var headerView: some View {
        VStack(alignment: .leading) {
            Text(Localization.allBookings)
                .bodyStyle()
                .bold()
            Text(String.localizedStringWithFormat(
                Localization.lastUpdated,
                Date().formatted(date: .omitted, time: .shortened)
            )) // TODO: update date
            .footnoteStyle()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Layout.viewPadding)
    }

    var contentView: some View {
        VStack {
            switch viewModel.syncState {
            case .empty:
                Spacer()
                Text("No bookings found") // TODO: update this
                Spacer()
            case .syncingFirstPage:
                ProgressView().progressViewStyle(.circular)
            case .results:
                bookingList
            }
        }
    }

    var bookingList: some View {
        ScrollView {
            Divider()
            ForEach(viewModel.bookings) { booking in
                VStack(alignment: .leading) {
                    Text(booking.dateCreated.formatted(date: .numeric, time: .shortened))
                        .captionStyle()
                    
                }
            }
            Divider()
        }
    }
}
private extension BookingListView {
    enum Layout {
        static let viewPadding: CGFloat = 16
    }

    enum Localization {
        static let viewTitle = NSLocalizedString(
            "bookingListView.view.title",
            value: "Bookings",
            comment: "Title of the booking list view"
        )
        static let allBookings = NSLocalizedString(
            "bookingListView.tabs.all.title",
            value: "All bookings",
            comment: "Title of the All tab of the booking list view"
        )
        static let lastUpdated = NSLocalizedString(
            "bookingListView.lastUpdated",
            value: "Last updated at %1$@",
            comment: "Text for the timestamp that the booking list was last updated"
        )
    }
}

#Preview {
    BookingListView(viewModel: BookingListViewModel(siteID: 123))
}
