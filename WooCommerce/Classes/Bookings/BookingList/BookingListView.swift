import SwiftUI
import struct Yosemite.Booking

struct BookingListView: View {
    @ObservedObject private var viewModel: BookingListViewModel
    @State private var selectedTabIndex = 0

    private let tabs = ["Today", "Upcoming", "All"]

    init(viewModel: BookingListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            VStack {
                switch viewModel.syncState {
                case .empty:
                    headerView
                    Spacer()
                    Text("No bookings found") // TODO: update this
                    Spacer()
                case .syncingFirstPage:
                    headerView
                    ProgressView().progressViewStyle(.circular)
                case .results:
                    bookingList
                }
            }
            .navigationTitle(Localization.viewTitle)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        // TODO
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
            .task {
                viewModel.loadBookings()
            }
        }
    }
}

private extension BookingListView {
    var headerView: some View {
        VStack(spacing: 0) {
            topTabView
            Divider()
            HStack {
                Button {
                    // TODO
                } label: {
                    Text(Localization.sortBy)
                        .font(.body)
                        .foregroundStyle(Color.accentColor)
                }
                Spacer()
                Button {
                    // TODO
                } label: {
                    Text(Localization.filter)
                        .font(.body)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding()
            .background(Color(.listForeground(modal: false)))
            Divider()
        }
    }

    var topTabView: some View {
        HStack {
            ForEach(Array(tabs.enumerated()), id: \.element) { (index, title) in
                Button {
                    selectedTabIndex = index
                } label: {
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(selectedTabIndex == index ? Color.accentColor : Color.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .overlay {
                    VStack {
                        Spacer()
                        if selectedTabIndex == index {
                            Color.accentColor
                                .frame(height: Layout.selectedTabIndicatorHeight)
                        }
                    }
                }
            }
        }
        .background(Color(.listForeground(modal: false)))
    }

    var bookingList: some View {
        ScrollView {
            LazyVStack(spacing: Layout.viewPadding, pinnedViews: .sectionHeaders) {
                Section {
                    ForEach(viewModel.bookings) { item in
                        bookingItem(item)
                            .padding([.top, .horizontal], Layout.viewPadding)
                        Divider()
                            .padding(.leading, Layout.viewPadding)
                    }
                } header: {
                    headerView
                }
                InfiniteScrollIndicator(showContent: viewModel.shouldShowBottomActivityIndicator)
                    .onAppear {
                        viewModel.onLoadNextPageAction()
                    }
            }
        }
        .refreshable {
            viewModel.onRefreshAction(completion: {
                // TODO: show/hide ghost animation if needed
            })
        }
    }

    func bookingItem(_ booking: Booking) -> some View {
        VStack(alignment: .leading) {
            Text(booking.dateCreated.formatted(date: .numeric, time: .shortened))
                .captionStyle()
                .foregroundStyle(Color.secondary)

            HStack {
                Text("Women's Hair cut")
                    .font(.body)
                    .fontWeight(.medium)
                Spacer()
                Text(String(format: "$%@", booking.cost))
                Image(systemName: "chevron.forward")
                    .fontWeight(.medium)
                    .foregroundStyle(Color.secondary)
            }

            Text("Marianne")
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(Color.secondary)
        }
    }
}
private extension BookingListView {
    enum Layout {
        static let viewPadding: CGFloat = 16
        static let selectedTabIndicatorHeight: CGFloat = 3.0
    }

    enum Localization {
        static let viewTitle = NSLocalizedString(
            "bookingListView.view.title",
            value: "Bookings",
            comment: "Title of the booking list view"
        )
        static let sortBy = NSLocalizedString(
            "bookingListView.sortBy",
            value: "Sort by",
            comment: "Button to select the order of the booking list"
        )
        static let filter = NSLocalizedString(
            "bookingListView.filter",
            value: "Filter",
            comment: "Button to filter the booking list"
        )
    }
}

#Preview {
    BookingListView(viewModel: BookingListViewModel(siteID: 123))
}
