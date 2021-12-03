import Foundation
import Yosemite
import Combine

/// View Model for the Edit Customer Note screen
///
final class EditCustomerNoteViewModel: EditCustomerNoteViewModelProtocol {

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

    /// A closure to be called when this view wants its creator to update the order customer note and dismiss it.
    ///
    var didSelectDone: ((String) -> Void)?

    /// Stores the original note content.
    /// Temporarily empty.
    ///
    private var originalNote: String

    /// Order to be edited.
    ///
    private let order: Order

    /// Action dispatcher
    ///
    private let stores: StoresManager

    /// Analytics center.
    ///
    private let analytics: Analytics

    init(order: Order, stores: StoresManager = ServiceLocator.stores, analytics: Analytics = ServiceLocator.analytics) {
        self.order = order
        self.newNote = order.customerNote ?? ""
        self.stores = stores
        self.analytics = analytics
        self.originalNote = order.customerNote ?? ""
        bindCustomerNoteChanges()
    }

    /// NO-OP:
    /// Since we have optistic update now customer note update action not done here.
    ///
    func updateNote(onFinish: @escaping (Bool) -> Void) { }

    /// Track the flow cancel scenario.
    ///
    func userDidCancelFlow() {
        analytics.track(event: WooAnalyticsEvent.OrderDetailsEdit.orderDetailEditFlowCanceled(subject: .customerNote))
    }
}

// MARK: Helper Methods
private extension EditCustomerNoteViewModel {
    /// Assigns the correct navigation trailing item as the new customer note content changes.
    ///
    private func bindCustomerNoteChanges() {
        $newNote
            .map { editedContent -> EditCustomerNoteNavigationItem in
            .done(enabled: editedContent != self.originalNote)
            }
            .assign(to: &$navigationTrailingItem)
    }
}

private extension EditCustomerNoteViewModel {
    enum Localization {
        enum CustomerNoteUpdateNotice {
            static let success = NSLocalizedString("Successfully updated", comment: "Notice text after updating the order successfully")
            static let error = NSLocalizedString("There was an error updating the order", comment: "Notice text after failing to update the order successfully")
        }
    }
}
