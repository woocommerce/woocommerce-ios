import SwiftUI

/// View model for `AddProductFromImageView` to handle user actions from the view and provide data for the view.
@MainActor
final class AddProductFromImageViewModel: ObservableObject {
    // MARK: - Product Details

    @Published var name: String = ""
    @Published var description: String = ""
}
