import Foundation

/// View model for `WPComEmailLoginView`
final class WPComEmailLoginViewModel: ObservableObject {
    @Published var emailAddress: String = ""

    /// The closure to be triggered when the Install Jetpack button is tapped.
    private let onSubmit: (String) -> Void

    init(onSubmit: @escaping (String) -> Void) {
        self.onSubmit = onSubmit
    }

    func handleSubmission() {
        // TODO
    }
}
