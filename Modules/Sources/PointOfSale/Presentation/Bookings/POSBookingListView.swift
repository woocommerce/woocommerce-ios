// POSBookingListView.swift
import SwiftUI

struct POSBookingListView: View {
    @Environment(POSBookingListController.self) private var controller
    @Environment(\.posAnalytics) private var analytics
    @Environment(\.siteTimezone) private var siteTimezone

    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            POSPageHeaderView(
                title: Localization.title,
                backButtonConfiguration: .init(state: .enabled, action: onClose, buttonIcon: "xmark")
            )

            content
        }
        .background(Color.posSurfaceBright)
        .refreshable {
            await controller.refreshBookings()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch controller.state {
        case .loading:
            bookingsList([])
        case .loaded(let bookings):
            bookingsList(bookings)
        case .empty:
            emptyView
        case .error(let errorState):
            errorView(errorState)
        }
    }

    @ViewBuilder
    private func bookingsList(_ bookings: [POSBooking]) -> some View {
        ScrollView {
            LazyVStack(spacing: POSSpacing.small) {
                ForEach(bookings) { booking in
                    Button {
                        controller.selectBooking(booking)
                    } label: {
                        POSBookingRowView(
                            booking: booking,
                            isSelected: controller.selectedBooking?.bookingID == booking.bookingID,
                            isRefreshing: controller.isRefreshing,
                            siteTimezone: siteTimezone
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Show ghost rows when loading
                if controller.state.isLoading {
                    ForEach(0..<3, id: \.self) { _ in
                        POSGhostBookingRowView()
                    }
                }
            }
            .padding(POSSpacing.medium)
        }
    }

    @ViewBuilder
    private var emptyView: some View {
        POSListEmptyView(viewModel: POSBookingListEmptyViewModel())
    }

    @ViewBuilder
    private func errorView(_ errorState: PointOfSaleErrorState) -> some View {
        POSListErrorView(error: errorState) {
            Task {
                await controller.loadBookings()
            }
        }
    }

    private enum Localization {
        static let title = NSLocalizedString("posBookingList.title", value: "Today's Bookings", comment: "Title for POS bookings list")
    }
}

// MARK: - Empty View Model

struct POSBookingListEmptyViewModel: POSListEmptyViewModelProtocol {
    var title: String {
        Localization.emptyTitle
    }

    var subtitle: String {
        Localization.emptySubtitle
    }

    var buttonTitle: String? {
        nil
    }

    var icon: Image {
        Image(systemName: "calendar.badge.clock")
    }

    private enum Localization {
        static let emptyTitle = NSLocalizedString("posBookingList.emptyTitle", value: "No bookings today", comment: "Empty state title")
        static let emptySubtitle = NSLocalizedString("posBookingList.emptySubtitle", value: "Bookings for today will appear here", comment: "Empty state subtitle")
    }
}

// MARK: - Ghost Loading Row

struct POSGhostBookingRowView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
            // Line 1: Name and amount
            HStack {
                RoundedRectangle(cornerRadius: POSSpacing.xSmall)
                    .fill(Color.posSurfaceContainerLow)
                    .frame(width: 120, height: 20)
                Spacer()
                RoundedRectangle(cornerRadius: POSSpacing.xSmall)
                    .fill(Color.posSurfaceContainerLow)
                    .frame(width: 60, height: 20)
            }
            // Line 2: Service description and time
            HStack {
                RoundedRectangle(cornerRadius: POSSpacing.xSmall)
                    .fill(Color.posSurfaceContainerLow)
                    .frame(width: 180, height: 16)
            }
            // Line 3: Status badge
            RoundedRectangle(cornerRadius: POSSpacing.xSmall)
                .fill(Color.posSurfaceContainerLow)
                .frame(width: 60, height: 24)
        }
        .padding(POSSpacing.medium)
        .background(Color.posSurfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: POSSpacing.small))
        .shimmering()
    }
}
