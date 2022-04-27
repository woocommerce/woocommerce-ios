import Combine
import Yosemite
import protocol Storage.StorageManagerType
import Experiments

final class EditOrderAddressFormViewModel: AddressFormViewModel, AddressFormViewModelProtocol {

    enum AddressType {
        case shipping
        case billing
    }

    /// Order to be edited.
    ///
    private var order: Yosemite.Order {
        didSet {
            syncFieldsWithOrder()
        }
    }

    /// Type of order address to edit
    ///
    private let type: AddressType

    /// Order update callback
    ///
    private let onOrderUpdate: ((Yosemite.Order) -> Void)?


    /// Presents an error notice in the tab bar context after the update operation fails.
    ///
    private let noticePresenter: NoticePresenter

    init(order: Yosemite.Order,
         type: AddressType,
         onOrderUpdate: ((Yosemite.Order) -> Void)? = nil,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         noticePresenter: NoticePresenter = ServiceLocator.noticePresenter) {
        self.order = order
        self.type = type
        self.onOrderUpdate = onOrderUpdate
        self.noticePresenter = noticePresenter

        let addressToEdit: Address?
        switch type {
        case .shipping:
            addressToEdit = order.shippingAddress
        case .billing:
            addressToEdit = order.billingAddress
        }

        super.init(siteID: order.siteID,
                   address: addressToEdit ?? .empty,
                   storageManager: storageManager,
                   stores: stores,
                   analytics: analytics,
                   featureFlagService: featureFlagService)
    }

    // MARK: - Protocol conformance

    var showEmailField: Bool {
        switch type {
        case .shipping:
            return false
        case .billing:
            return true
        }
    }

    var viewTitle: String {
        switch type {
        case .shipping:
            return Localization.shippingTitle
        case .billing:
            return Localization.billingTitle
        }
    }

    var sectionTitle: String {
        switch type {
        case .shipping:
            return Localization.shippingAddressSection
        case .billing:
            return Localization.billingAddressSection
        }
    }

    var secondarySectionTitle: String {
        ""
    }

    var showAlternativeUsageToggle: Bool {
        true
    }

    var alternativeUsageToggleTitle: String? {
        switch type {
        case .shipping:
            return Localization.useAsBillingToggle
        case .billing:
            return Localization.useAsShippingToggle
        }
    }

    var showDifferentAddressToggle: Bool {
        false
    }

    var differentAddressToggleTitle: String? {
        nil
    }

    func update(order: Order) {
        self.order = order
    }

    /// Update the address remotely and invoke a completion block when finished
    ///
    func saveAddress(onFinish: @escaping (Bool) -> Void) {
        guard validateEmail() else {
            notice = AddressFormViewModel.NoticeFactory.createInvalidEmailNotice()
            return onFinish(false)
        }

        let updatedAddress = fields.toAddress()
        let orderFields: [OrderUpdateField]
        let modifiedOrder: Yosemite.Order
        switch type {
        case .shipping where fields.useAsToggle:
            modifiedOrder = order.copy(billingAddress: updatedAddress.removingEmptyEmail(),
                                       shippingAddress: updatedAddress.removingEmptyEmail())
            orderFields = [.shippingAddress, .billingAddress]
        case .shipping:
            modifiedOrder = order.copy(shippingAddress: updatedAddress.removingEmptyEmail())
            orderFields = [.shippingAddress]
        case .billing where fields.useAsToggle:
            modifiedOrder = order.copy(billingAddress: updatedAddress,
                                       shippingAddress: updatedAddress.copy(email: .some(nil)))
            orderFields = [.billingAddress, .shippingAddress]
        case .billing:
            modifiedOrder = order.copy(billingAddress: updatedAddress)
            orderFields = [.billingAddress]
        }

        if areOptimisticUpdatesEnabled {
            handleOrderUpdate(modifiedOrder, fields: orderFields, updatedAddress: updatedAddress)
            onFinish(true)
        } else {
            handleOrderUpdate(modifiedOrder, fields: orderFields, updatedAddress: updatedAddress, onFinish: onFinish)
        }
    }

    override func trackOnLoad() {
        analytics.track(event: WooAnalyticsEvent.OrderDetailsEdit.orderDetailEditFlowStarted(subject: analyticsFlowType()))
    }

    func userDidCancelFlow() {
        if hasPendingChanges {
            syncFieldsWithOrder()
        }

        analytics.track(event: WooAnalyticsEvent.OrderDetailsEdit.orderDetailEditFlowCanceled(subject: analyticsFlowType()))
    }
}

private extension EditOrderAddressFormViewModel {
    var currentOrderAddress: Address? {
        switch type {
        case .shipping:
            return order.shippingAddress
        case .billing:
            return order.billingAddress
        }
    }

    /// Updates fields with the current order address
    ///
    func syncFieldsWithOrder() {
        syncFieldsWithAddress(currentOrderAddress ?? .empty)
    }

    /// Handles the action to update the order.
    /// - Parameters:
    ///   - modifiedOrder: Given modified order to be updated.
    ///   - fields: The fields that should be updated.
    ///   - updatedAddress: The address that has been updated.
    ///   - onFinish: Callback to notify when the action has finished.
    ///
    func handleOrderUpdate(_ modifiedOrder: Yosemite.Order, fields: [OrderUpdateField], updatedAddress: Address, onFinish: ((Bool) -> Void)? = nil) {
        let updateAction = makeUpdateAction(order: modifiedOrder, fields: fields) { [weak self] result in
            guard let self = self else { return }

            self.performingNetworkRequest.send(false)
            switch result {
            case .success(let updatedOrder):
                self.onOrderUpdate?(updatedOrder)
                self.displayAddressUpdatedNoticeIfNeeded()
                self.analytics.track(event: WooAnalyticsEvent.OrderDetailsEdit.orderDetailEditFlowCompleted(subject: self.analyticsFlowType()))

            case .failure(let error):
                DDLogError("⛔️ Error updating order: \(error)")
                if self.type == .billing, updatedAddress.hasEmailAddress == false {
                    DDLogError("⛔️ Email is nil in address. It won't work in WC < 5.9.0 (https://git.io/J68Gl)")
                }
                self.displayUpdateErrorNotice(modifiedOrder: modifiedOrder,
                                              fields: fields,
                                              updatedAddress: updatedAddress)
                self.analytics.track(event: WooAnalyticsEvent.OrderDetailsEdit.orderDetailEditFlowFailed(subject: self.analyticsFlowType()))
            }
            onFinish?(result.isSuccess)
        }

        performingNetworkRequest.send(true)
        stores.dispatch(updateAction)
    }

    /// Returns the update action based on the value of the `updateOrderOptimistically` feature flag.
    ///
    func makeUpdateAction(order: Order, fields: [OrderUpdateField], onCompletion: @escaping (Result<Order, Error>) -> Void) -> Action {
        if areOptimisticUpdatesEnabled {
            return OrderAction.updateOrderOptimistically(siteID: order.siteID, order: order, fields: fields, onCompletion: onCompletion)
        } else {
            return OrderAction.updateOrder(siteID: order.siteID, order: order, fields: fields, onCompletion: onCompletion)
        }
    }

    /// Enqueues the success notice on successful updating only when
    /// optimistic updates are not enabled.
    ///
    func displayAddressUpdatedNoticeIfNeeded() {
        guard !areOptimisticUpdatesEnabled else {
            return
        }

        notice = NoticeFactory.createSuccessNotice()
    }

    /// Enqueues the `Unable to Update Order` Notice.
    ///
    func displayUpdateErrorNotice(modifiedOrder: Yosemite.Order, fields: [OrderUpdateField], updatedAddress: Address) {
        let noticeIdentifier = UUID().uuidString
        let errorNotice = NoticeFactory.createRetriableErrorNotice(from: .unableToUpdateAddress,
                                                                   info: NoticeNotificationInfo(identifier: noticeIdentifier)) { [weak self] in
            self?.handleOrderUpdate(modifiedOrder, fields: fields, updatedAddress: updatedAddress)
        }

        if areOptimisticUpdatesEnabled {
            noticePresenter.enqueue(notice: errorNotice)
        } else {
            /// If optimistic updates are not enabled the modal is not dismissed
            /// upon failure, so we have to use notice modifier for this modal.
            notice = errorNotice
        }
    }

    /// Returns the correct analytics subject for the current address form type.
    ///
    func analyticsFlowType() -> WooAnalyticsEvent.OrderDetailsEdit.Subject {
        switch type {
        case .shipping:
            return .shippingAddress
        case .billing:
            return .billingAddress
        }
    }

    // MARK: Constants
    enum Localization {
        static let shippingTitle = NSLocalizedString("Shipping Address", comment: "Title for the Edit Shipping Address Form")
        static let billingTitle = NSLocalizedString("Billing Address", comment: "Title for the Edit Billing Address Form")

        static let shippingAddressSection = NSLocalizedString("SHIPPING ADDRESS", comment: "Details section title in the Edit Address Form")
        static let billingAddressSection = NSLocalizedString("BILLING ADDRESS", comment: "Details section title in the Edit Address Form")

        static let useAsBillingToggle = NSLocalizedString("Use as Billing Address",
                                                          comment: "Title for the Use as Billing Address switch in the Address form")
        static let useAsShippingToggle = NSLocalizedString("Use as Shipping Address",
                                                           comment: "Title for the Use as Shipping Address switch in the Address form")
        static let success = NSLocalizedString("Address successfully updated.", comment: "Notice text after updating the shipping or billing address")
        static let retry = NSLocalizedString("Retry", comment: "Retry Action")
    }
}

extension EditOrderAddressFormViewModel {
    /// Representation of possible errors that can happen
    enum EditAddressError: LocalizedError {
        case unableToUpdateAddress

        var errorDescription: String? {
            switch self {
            case .unableToUpdateAddress:
                return NSLocalizedString("Unable to update address.",
                                         comment: "Error notice title when we fail to update an address in the edit address screen.")
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .unableToUpdateAddress:
                return NSLocalizedString("Please make sure you are running the latest version of WooCommerce and try again later.",
                                         comment: "Error notice recovery suggestion when we fail to update an address in the edit address screen.")
            }
        }
    }

    /// Creates edit address form notices.
    ///
    enum NoticeFactory {
        /// Creates an error notice with retry based on the provided edit address error.
        ///
        static func createRetriableErrorNotice(from error: EditAddressError, info: NoticeNotificationInfo, retryAction: @escaping () -> Void) -> Notice {
            Notice(title: error.errorDescription ?? "",
                   message: error.recoverySuggestion,
                   feedbackType: .error,
                   notificationInfo: info,
                   actionTitle: Localization.retry,
                   actionHandler: retryAction)
        }

        /// Creates a success notice for editing an address.
        ///
        static func createSuccessNotice() -> Notice {
            .init(title: Localization.success, feedbackType: .success)
        }
    }
}

private extension Address {
    /// Sets the email value to `nil` when it is empty.
    /// Needed because core has a validation where a billing address can only be a valid email or `nil`(instead of empty).
    ///
    func removingEmptyEmail() -> Yosemite.Address {
        guard let email = email, email.isEmpty else {
            return self
        }
        return copy(email: .some(nil))
    }
}
