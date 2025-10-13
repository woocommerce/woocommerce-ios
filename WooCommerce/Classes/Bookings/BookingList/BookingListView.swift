import SwiftUI
import struct Yosemite.Booking

struct BookingListView: View {
    @ObservedObject private var viewModel: BookingListViewModel
    @StateObject private var connectivityMonitor = ConnectivityMonitor()
    @ScaledMetric private var scale: CGFloat = 1.0
    @Binding var selectedBooking: Booking?

    init(viewModel: BookingListViewModel, selectedBooking: Binding<Booking?>) {
        self.viewModel = viewModel
        self._selectedBooking = selectedBooking
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
        .overlay(alignment: .bottom) {
            if viewModel.errorFetching {
                errorSnackBar
                    .transition(.move(edge: .bottom))
            }
        }
    }
}

private extension BookingListView {
    var bookingList: some View {
        List(selection: $selectedBooking) {
            ForEach(viewModel.bookings) { item in
                bookingItem(item)
                    .tag(item)
            }

            InfiniteScrollIndicator(showContent: viewModel.shouldShowBottomActivityIndicator)
                .padding(.top, Layout.viewPadding)
                .onAppear {
                    viewModel.onLoadNextPageAction()
                }
        }
        .listStyle(.plain)
        .background(Color(.listBackground))
        .accentColor(Color(.listSelectedBackground))
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
                    .foregroundStyle(Color.primary)

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
        }
    }

    func statusBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(Color.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.clipShape(RoundedRectangle(cornerRadius: 4)))
    }

    var emptyStateView: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: Layout.emptyStatePadding) {
                    Spacer()
                    Image(uiImage: .noBookings)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: Layout.emptyStateImageWidth * scale)
                        .padding(.bottom, Layout.viewPadding)
                    VStack(spacing: Layout.textVerticalPadding) {
                        Text(viewModel.emptyStateTitle)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        Text(viewModel.emptyStateDescription)
                            .font(.title3)
                            .foregroundStyle(.secondary)
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
                .multilineTextAlignment(.center)
                .padding(.horizontal, Layout.emptyStatePadding)
                .frame(minWidth: proxy.size.width, minHeight: proxy.size.height)
            }
            .refreshable {
                await viewModel.onRefreshAction()
            }
        }
    }

    var errorSnackBar: some View {
        Text(Localization.errorMessage)
            .foregroundStyle(Color(.listForeground(modal: false)))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Layout.viewPadding)
            .background {
                RoundedRectangle(cornerRadius: Layout.cornerRadius)
                    .fill(Color(.text))
            }
            .padding(Layout.viewPadding)
            .padding(.bottom, connectivityMonitor.isOffline ? OfflineBannerView.height : 0)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    viewModel.errorFetching = false
                }
            }
    }
}

private extension BookingListView {
    enum Layout {
        static let textVerticalPadding: CGFloat = 8
        static let viewPadding: CGFloat = 16
        static let emptyStatePadding: CGFloat = 24
        static let emptyStateImageWidth: CGFloat = 67
        static let defaultBadgeColor = Color(uiColor: .init(light: .systemGray6, dark: .systemGray5))
        static let cornerRadius: CGFloat = 8
    }

    enum Localization {
        static let errorMessage = NSLocalizedString(
            "bookingList.errorMessage",
            value: "Error fetching bookings",
            comment: "Error message when fetching bookings fails"
        )
    }
}
