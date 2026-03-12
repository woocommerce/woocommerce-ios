import SwiftUI
import struct Yosemite.POSBooking

struct POSBookingsContainerView: View {
    @Binding var isPresented: Bool
    @Environment(POSBookingsModel.self) private var bookingsModel
    @Environment(POSOrderListModel.self) private var orderListModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isSearching: Bool = false
    @State private var searchTerm: String = ""

    var body: some View {
        contentView
            .overlay(alignment: .bottom) {
                cancelSuccessSnackbar
            }
            .animation(.easeInOut, value: bookingsModel.showCancelSuccessNotice)
            .task {
                await bookingsModel.bookingsController.loadBookings()
            }
    }

    @ViewBuilder
    private var cancelSuccessSnackbar: some View {
        if bookingsModel.showCancelSuccessNotice {
            HStack(spacing: POSSpacing.medium) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.posButtonSymbolXSmall)
                    .foregroundColor(.posSuccess)
                Text(Localization.cancelBookingSuccessNotice)
                    .font(.posBodyMediumRegular())
                    .foregroundColor(.posSurface)
            }
            .padding(.vertical, POSPadding.medium)
            .padding(.horizontal, POSPadding.large)
            .background(Color.posOnSurface)
            .cornerRadius(POSCornerRadiusStyle.medium.value)
            .posShadow(.medium, cornerRadius: POSCornerRadiusStyle.medium.value)
            .padding(.bottom, POSPadding.large)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    @ViewBuilder
    private var contentView: some View {
        POSNavigationSplitView(selection: Binding(
            get: { bookingsModel.bookingsController.selectedBooking },
            set: { bookingsModel.bookingsController.selectBooking($0) }
        )) { _ in
            POSBookingListView(isSearching: $isSearching, searchTerm: $searchTerm) {
                isPresented = false
            }
            .environment(bookingsModel)
        } detail: { selection, navigationPath in
            POSBookingDetailView(
                booking: Binding(
                    get: { bookingsModel.bookingsController.selectedBooking ?? selection },
                    set: { bookingsModel.bookingsController.selectBooking($0) }
                ),
                navigationPath: navigationPath,
                onBack: {
                    bookingsModel.bookingsController.selectBooking(nil)
                }
            )
            .id(selection.id)
            .environment(bookingsModel)
            .environment(orderListModel)
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
            bookingsModel.bookingsController.reset()
        }
    }
}

// MARK: - Localization

private enum Localization {
    static let cancelBookingSuccessNotice = NSLocalizedString(
        "pos.bookingsContainer.cancelBookingSuccess.notice",
        value: "Booking cancelled successfully.",
        comment: "Success notice shown at the bottom of the bookings screen after a booking is cancelled in POS."
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
