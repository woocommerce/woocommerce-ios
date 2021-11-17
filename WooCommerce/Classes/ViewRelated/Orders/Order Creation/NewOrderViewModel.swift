import Yosemite

/// View model for `NewOrder`.
///
final class NewOrderViewModel {
    /// Order to create remotely
    ///
    private var order: Order = .empty {
        didSet {
            isCreateButtonEnabled = true
        }
    }

    /// Whether to enable the Create button
    ///
    private(set) var isCreateButtonEnabled: Bool = false
}
