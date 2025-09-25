import UIKit
import SwiftUI

/// periphery: ignore - will be used after Booking list is ready
final class BookingDetailsViewController: UIHostingController<BookingDetailsView> {

    private let viewModel: BookingDetailsViewModel

    init(viewModel: BookingDetailsViewModel) {
        self.viewModel = viewModel
        super.init(rootView: BookingDetailsView(viewModel))
    }

    @MainActor
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
    }

    private func configureNavigationBar() {
        navigationItem.title = NSLocalizedString("Booking Details", comment: "Booking details screen title")
        navigationItem.largeTitleDisplayMode = .never
    }
}
