import SwiftUI
import struct Yosemite.POSBooking
import enum Yosemite.SearchDebounceStrategy

struct POSBookingListView: View {
    @Binding var isSearching: Bool
    @Binding var searchTerm: String
    let onClose: () -> Void

    @Environment(POSBookingsModel.self) private var bookingsModel
    @StateObject private var infiniteScrollTriggerDeterminer = ThresholdInfiniteScrollTriggerDeterminer()

    private var bookingsViewState: POSBookingListState {
        bookingsModel.bookingsController.bookingsViewState
    }

    var body: some View {
        VStack(spacing: 0) {
            POSPageHeaderView(
                items: isSearching ? [] : [.init(
                    title: Localization.bookingsTitle,
                    subtitle: nil,
                    isSelected: true,
                    isLoading: isSearching ? false : {
                        if case .loading(let bookings) = bookingsViewState {
                            return !bookings.isEmpty
                        }
                        return false
                    }()
                )],
                backButtonConfiguration: isSearching ? nil : .init(state: .enabled, action: onClose, buttonIcon: "xmark"),
                trailingContent: {
                    if !isSearching && !bookingsViewState.bookings.isEmpty {
                        POSPageHeaderActionButton(
                            systemName: "magnifyingglass",
                            backgroundColor: .posSurface,
                            imageColor: .posOnSurface
                        ) {
                            setSearch(true)
                        }
                        .accessibilityLabel(Localization.searchButtonAccessibilityLabel)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity)
                                .animation(.easeInOut(duration: Constants.animationDuration).delay(Constants.animationDuration)),
                            removal: .opacity.animation(.easeInOut(duration: Constants.animationDuration * 0.5))
                        ))
                    }

                    if isSearching {
                        POSSearchField(
                            searchTerm: $searchTerm,
                            searchable: POSBookingSearchable(bookingsController: bookingsModel.bookingsController),
                            onBack: {
                                setSearch(false)
                            }
                        )
                        .posSearchTextFieldUnfocusedBorderColor(.posOutlineVariant)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing))
                                .animation(.easeInOut(duration: Constants.animationDuration).delay(Constants.animationDuration * 0.5)),
                            removal: .opacity.combined(with: .move(edge: .trailing))
                                .animation(.easeInOut(duration: Constants.animationDuration))
                        ))
                        .onChange(of: searchTerm) { _, newValue in
                            if newValue.isEmpty {
                                bookingsModel.bookingsController.clearSearchBookings()
                            }
                        }
                    }
                }
            )
            .animation(.easeInOut(duration: Constants.animationDuration), value: isSearching)

            if !isSearching {
                POSBookingDateBarView()
            }

            switch (bookingsViewState, isSearching) {
            case (.empty, _):
                POSListEmptyView(
                    viewModel: POSBookingListEmptyViewModel(isSearching: isSearching)
                )
                .refreshable {
                    await bookingsModel.bookingsController.refreshBookings()
                }
            case (.error(let errorState), _):
                POSListErrorView(error: errorState)
                    .refreshable {
                        await bookingsModel.bookingsController.loadBookings()
                    }
            default:
                listView
            }
        }
        .animation(.default, value: bookingsModel.bookingsController.bookingsViewState.isEmpty)
        .background(Color.posSurfaceBright)
        .navigationBarHidden(true)
        .refreshable {
            await bookingsModel.bookingsController.refreshBookings()
        }
    }

    @ViewBuilder
    private var headerRows: some View {
        switch bookingsViewState {
        case .inlineError(_, let errorState, .refresh):
            POSListInlineErrorView(errorState: errorState) {
                await bookingsModel.bookingsController.loadBookings()
            }
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var listView: some View {
        ScrollViewReader { proxy in
            InfiniteScrollView(
                triggerDeterminer: infiniteScrollTriggerDeterminer,
                loadMore: {
                    guard case .loaded(_, let hasMoreItems) = bookingsViewState, hasMoreItems else { return }
                    await bookingsModel.bookingsController.loadNextBookings()
                },
                content: {
                    LazyVStack(spacing: POSSpacing.medium) {
                        headerRows
                            .id(Constants.scrollTopID)

                        let bookings = bookingsViewState.bookings
                        ForEach(Array(bookings.enumerated()), id: \.element.id) { _, booking in
                            Button(action: {
                                bookingsModel.bookingsController.selectBooking(booking)
                            }) {
                                POSBookingRowView(booking: booking,
                                                  isSelected: bookingsModel.bookingsController.selectedBooking?.id == booking.id)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .accessibilityRemoveTraits(.isButton)
                        }
                        .animation(.default, value: bookings.first?.id)

                        footerRows
                    }
                    .padding(.horizontal)
                    .padding(.top, POSPadding.xSmall)
                    .padding(.bottom, POSPadding.medium)
                }
            )
            .scrollDismissesKeyboard(.immediately)
            .onChange(of: searchTerm) { _, _ in
                withAnimation {
                    proxy.scrollTo(Constants.scrollTopID, anchor: .top)
                }
            }
        }
    }

    @ViewBuilder
    private var footerRows: some View {
        switch bookingsViewState {
        case .loading(let bookings):
            if bookings.isEmpty {
                ForEach(0..<8, id: \.self) { _ in
                    POSBookingGhostRowView()
                }
                .opacity(bookings.isEmpty ? 1 : 0)
                .animation(.default, value: bookings.isEmpty)
            } else {
                POSBookingGhostRowView()
            }
        case .inlineError(_, let errorState, .pagination):
            POSListInlineErrorView(errorState: errorState) {
                await bookingsModel.bookingsController.loadNextBookings()
            }
        default:
            EmptyView()
        }
    }
}

// MARK: - Search

private extension POSBookingListView {
    func setSearch(_ isSearchingValue: Bool) {
        if isSearchingValue {
            isSearching = true
        } else {
            searchTerm = ""
            isSearching = false
            bookingsModel.bookingsController.clearSearchBookings()
        }
    }
}

final class POSBookingSearchable: POSSearchable {
    private let bookingsController: POSSearchingBookingListControllerProtocol

    init(bookingsController: POSSearchingBookingListControllerProtocol) {
        self.bookingsController = bookingsController
    }

    var searchFieldPlaceholder: String {
        Localization.searchFieldPlaceholder
    }

    var searchHistory: [String] {
        []
    }

    var currentDebounceStrategy: SearchDebounceStrategy {
        .smart()
    }

    var searchDebounceStrategy: SearchDebounceStrategy {
        currentDebounceStrategy
    }

    func performSearch(term: String) async {
        await bookingsController.searchBookings(searchTerm: term)
    }

    func clearSearchResults() {
        bookingsController.clearSearchBookings()
    }
}

// MARK: - Constants

private enum Constants {
    static let animationDuration: CGFloat = 0.2
    static let scrollTopID = "bookingListViewTopID"
}

private enum Localization {
    static let bookingsTitle = NSLocalizedString(
        "pos.bookingListView.bookingsTitle",
        value: "Bookings",
        comment: "Title at the header for the Bookings view."
    )

    static let searchButtonAccessibilityLabel = NSLocalizedString(
        "pos.bookingListView.searchButton.accessibilityLabel",
        value: "Search bookings",
        comment: "Accessibility label for the search button in bookings list."
    )

    static let searchFieldPlaceholder = NSLocalizedString(
        "pos.bookingListView.searchFieldPlaceholder",
        value: "Search bookings",
        comment: "Placeholder for a search field in the Bookings view."
    )
}
