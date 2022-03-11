import Foundation
import Yosemite

final class OrderNotesViewModel: EditCustomerNoteViewModelProtocol {

    /// Binding property modified at the view level.
    ///
    @Published var newNote: String

    /// Defaults to a disabled done button.
    ///
    @Published private(set) var navigationTrailingItem: EditCustomerNoteNavigationItem = .done(enabled: false)

    /// Defaults to `nil`.
    ///
    @Published var presentNotice: EditCustomerNoteNotice?

    /// Publisher accessor for `presentNotice`. Needed for the protocol conformance.
    ///
    var presentNoticePublisher: Published<EditCustomerNoteNotice?>.Publisher {
        $presentNotice
    }

    /// Order to be edited.
    ///
    private let order: Order

    /// Action dispatcher
    ///
    private let stores: StoresManager = ServiceLocator.stores

    /// Analytics center.
    ///
    private let analytics: Analytics = ServiceLocator.analytics

    init(order: Order) {
        self.order = order
        self.newNote = order.customerNote ?? ""
    }

    func updateNote(onFinish: @escaping (Bool) -> Void) {
        onFinish(true)
    }

    func userDidCancelFlow() {
        DDLogDebug("Cancel clicked")
    }
}
