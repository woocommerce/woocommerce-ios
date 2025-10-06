import SwiftUI
import struct Yosemite.Booking

struct BookingListView: View {
    @ObservedObject private var viewModel: BookingListViewModel

    init(viewModel: BookingListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            switch viewModel.syncState {
            case .empty:
                emptyStateView
            case .syncingFirstPage:
                Spacer()
                ProgressView().progressViewStyle(.circular)
                Spacer()
            case .results:
                bookingList
            }
        }
        .task {
            viewModel.loadBookings()
        }
    }
}

private extension BookingListView {
    var bookingList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.bookings) { item in
                    NavigationLink(value: item) {
                        bookingItem(item)
                    }
                    .buttonStyle(.plain)
                }

                InfiniteScrollIndicator(showContent: viewModel.shouldShowBottomActivityIndicator)
                    .padding(.top, Layout.viewPadding)
                    .onAppear {
                        viewModel.onLoadNextPageAction()
                    }
            }
        }
        .refreshable {
            await viewModel.onRefreshAction()
        }
    }

    func bookingItem(_ booking: Booking) -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading) {
                Text(booking.startDate.toString(dateStyle: .short,
                                                timeStyle: .short,
                                                timeZone: BookingListTab.utcTimeZone))
                    .font(.body)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // TODO: fetch bookable products & customer to get names or wait for API update
                Text(String(format: "%@  •  %@", "Women's Hair cut", "Marianne"))
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.secondary)

                HStack {
                    // TODO: update this when attendance status is available
                    // Update badge colors if design changes as statuses are not clarified now.
                    statusBadge(text: "Booked", color: Layout.defaultBadgeColor)
                    statusBadge(text: booking.bookingStatus.localizedTitle, color: Layout.defaultBadgeColor)
                    Spacer()
                }
            }
            .padding(Layout.viewPadding)

            Divider()
                .padding(.leading, Layout.viewPadding)
        }
        .background(Color(.listForeground(modal: false))) // TODO: update selected background color as part of selection handling
    }

    func statusBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.clipShape(RoundedRectangle(cornerRadius: 4)))
    }

    var emptyStateView: some View {
        VStack(spacing: Layout.emptyStatePadding) {
            Spacer()
            Image(uiImage: .noBookings)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Layout.emptyStateImageWidth)
                .padding(.bottom, Layout.viewPadding)
            VStack(spacing: Layout.textVerticalPadding) {
                Text(viewModel.emptyStateTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text(viewModel.emptyStateDescription)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            if viewModel.hasFilters {
                VStack(spacing: Layout.textVerticalPadding) {
                    Button("Change filters") {
                        // TODO
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button("Clear filters") {
                        // TODO
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            Spacer()
        }
        .padding(.horizontal, Layout.emptyStatePadding)
        .scrollVerticallyIfNeeded()
    }
}

private extension BookingListView {
    enum Layout {
        static let textVerticalPadding: CGFloat = 8
        static let viewPadding: CGFloat = 16
        static let emptyStatePadding: CGFloat = 24
        static let emptyStateImageWidth: CGFloat = 67
        static let defaultBadgeColor = Color(uiColor: .init(light: .systemGray6, dark: .systemGray5))
    }
}
