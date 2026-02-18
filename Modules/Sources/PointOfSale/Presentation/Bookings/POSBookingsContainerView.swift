import SwiftUI
import struct Yosemite.POSBooking

struct POSBookingsContainerView: View {
    @Binding var isPresented: Bool
    @Environment(POSBookingsModel.self) private var bookingsModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isSearching: Bool = false
    @State private var searchTerm: String = ""

    var body: some View {
        contentView
            .task {
                await bookingsModel.bookingsController.loadBookings()
            }
    }

    @ViewBuilder
    private var contentView: some View {
        switch (bookingsModel.bookingsController.bookingsViewState, isSearching) {
        case (.error(let error), false):
            errorView(error)
        case (.empty, false):
            emptyView()
        default:
            POSNavigationSplitView(selection: Binding(
                get: { bookingsModel.bookingsController.selectedBooking },
                set: { bookingsModel.bookingsController.selectBooking($0) }
            )) { _ in
                POSBookingListView(isSearching: $isSearching, searchTerm: $searchTerm) {
                    isPresented = false
                }
                .environment(bookingsModel)
            } detail: { selection in
                POSBookingDetailView(
                    booking: selection,
                    onBack: {
                        bookingsModel.bookingsController.selectBooking(nil)
                    }
                )
                .id(selection.id)
                .environment(bookingsModel)
            } detailPlaceholderView: {
                if bookingsModel.bookingsController.bookingsViewState.isLoading {
                    POSBookingDetailsLoadingView()
                } else {
                    POSBookingDetailsEmptyView()
                }
            } setDefaultValue: {
                if bookingsModel.bookingsController.selectedBooking == nil,
                   let firstBooking = bookingsModel.bookingsController.bookingsViewState.bookings.first {
                    bookingsModel.bookingsController.selectBooking(firstBooking)
                }
            }
            .onChange(of: bookingsModel.bookingsController.bookingsViewState.bookings) { _, newBookings in
                guard horizontalSizeClass == .regular else { return }

                guard let firstBooking = newBookings.first else {
                    bookingsModel.bookingsController.selectBooking(nil)
                    return
                }

                if let selectedBooking = bookingsModel.bookingsController.selectedBooking,
                   newBookings.map(\.id).contains(selectedBooking.id) {
                    return
                }

                bookingsModel.bookingsController.selectBooking(firstBooking)
            }
            .animation(.default, value: bookingsModel.bookingsController.bookingsViewState.bookings.isEmpty)
            .onDisappear {
                bookingsModel.bookingsController.selectBooking(nil)
            }
        }
    }

    @ViewBuilder
    private func errorView(_ error: PointOfSaleErrorState) -> some View {
        ZStack {
            VStack {
                Spacer()
                POSListErrorView(error: error) {
                    Task { @MainActor in
                        await bookingsModel.bookingsController.loadBookings()
                    }
                }
                Spacer()
            }

            VStack {
                POSPageHeaderView(
                    title: Localization.bookingsTitle,
                    backButtonConfiguration: .init(state: .enabled, action: {
                        isPresented = false
                    }))
                Spacer()
            }
        }
    }

    @ViewBuilder
    private func emptyView() -> some View {
        ZStack {
            VStack {
                Spacer()
                POSListEmptyView(
                    viewModel: POSBookingListEmptyViewModel(isSearching: false)
                ) {}
                Spacer()
            }

            VStack {
                POSPageHeaderView(
                    title: Localization.bookingsTitle,
                    backButtonConfiguration: .init(state: .enabled, action: {
                        isPresented = false
                    }))
                Spacer()
            }
        }
    }
}

private enum Localization {
    static let bookingsTitle = NSLocalizedString(
        "pos.bookingsContainerView.bookingsTitle",
        value: "Bookings",
        comment: "Title at the header for the Bookings view."
    )
}

// MARK: - Previews

#if DEBUG
#Preview("Empty List") {
    POSBookingsContainerView(isPresented: .constant(true))
        .environment(POSPreviewHelpers.makePreviewBookingsModel(state: .empty))
}

#Preview("Loaded - No Selection") {
    let bookings = POSPreviewHelpers.makePreviewBookings()
    let model = POSPreviewHelpers.makePreviewBookingsModel(state: .loaded(bookings, hasMoreItems: false))
    model.bookingsController.selectBooking(nil)
    return POSBookingsContainerView(isPresented: .constant(true))
        .environment(model)
}

#Preview("Loaded - Booking Selected") {
    let bookings = POSPreviewHelpers.makePreviewBookings()
    return POSBookingsContainerView(isPresented: .constant(true))
        .environment(POSPreviewHelpers.makePreviewBookingsModel(state: .loaded(bookings, hasMoreItems: false)))
}

#Preview("Loading") {
    POSBookingsContainerView(isPresented: .constant(true))
        .environment(POSPreviewHelpers.makePreviewBookingsModel(state: .loading([])))
}

#Preview("Loading with Cached Bookings") {
    let bookings = POSPreviewHelpers.makePreviewBookings()
    return POSBookingsContainerView(isPresented: .constant(true))
        .environment(POSPreviewHelpers.makePreviewBookingsModel(state: .loading(bookings)))
}

#Preview("Error") {
    POSBookingsContainerView(isPresented: .constant(true))
        .environment(POSPreviewHelpers.makePreviewBookingsModel(state: .error(.errorOnLoadingBookings())))
}

#Preview("Inline Error") {
    let bookings = POSPreviewHelpers.makePreviewBookings()
    return POSBookingsContainerView(isPresented: .constant(true))
        .environment(POSPreviewHelpers.makePreviewBookingsModel(
            state: .inlineError(bookings, error: .errorOnLoadingBookingsNextPage(), context: .pagination)))
}
#endif
