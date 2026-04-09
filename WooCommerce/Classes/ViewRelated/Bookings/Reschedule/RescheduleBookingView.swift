import SwiftUI

/// Placeholder view for the reschedule booking flow.
/// UI will be implemented in a separate task.
struct RescheduleBookingView: View {
    @State private var viewModel: RescheduleBookingViewModel

    init(viewModel: RescheduleBookingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            Text("")
                .navigationTitle(Localization.title)
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private extension RescheduleBookingView {
    enum Localization {
        static let title = NSLocalizedString(
            "RescheduleBookingView.title",
            value: "Reschedule Booking",
            comment: "Navigation bar title for the reschedule booking screen."
        )
    }
}
