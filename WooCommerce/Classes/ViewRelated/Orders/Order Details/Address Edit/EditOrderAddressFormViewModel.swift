import Combine
import Yosemite
import protocol Storage.StorageManagerType

final class EditOrderAddressFormViewModel: AddressFormViewModel, AddressFormViewModelProtocol {

    enum AddressType {
        case shipping
        case billing
    }

    /// Order to be edited.
    ///
    private let order: Yosemite.Order

    /// Type of order address to edit
    ///
    private let type: AddressType

    /// Order update callback
    ///
    private let onOrderUpdate: ((Yosemite.Order) -> Void)?

    init(order: Yosemite.Order,
         type: AddressType,
         onOrderUpdate: ((Yosemite.Order) -> Void)? = nil,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.order = order
        self.type = type
        self.onOrderUpdate = onOrderUpdate

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
                   analytics: analytics)
    }

    /// Returns `true` if there are changes pending to commit. `False` otherwise.
    ///
    func hasPendingChanges() -> Bool {
        return navigationTrailingItem == .done(enabled: true)
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

    var toggleTitle: String {
        switch type {
        case .shipping:
            return Localization.useAsBillingToggle
        case .billing:
            return Localization.useAsShippingToggle
        }
    }

    /// Update the address remotely and invoke a completion block when finished
    ///
    func saveAddress(onFinish: @escaping (Bool) -> Void) {
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

        let action = OrderAction.updateOrder(siteID: order.siteID, order: modifiedOrder, fields: orderFields) { [weak self] result in
            guard let self = self else { return }

            self.performingNetworkRequest.send(false)
            switch result {
            case .success(let updatedOrder):
                self.onOrderUpdate?(updatedOrder)
                self.presentNotice = .success
                self.analytics.track(event: WooAnalyticsEvent.OrderDetailsEdit.orderDetailEditFlowCompleted(subject: self.analyticsFlowType()))

            case .failure(let error):
                DDLogError("⛔️ Error updating order: \(error)")
                if self.type == .billing, self.updatedAddress.hasEmailAddress == false {
                    DDLogError("⛔️ Email is nil in address. It won't work in WC < 5.9.0 (https://git.io/J68Gl)")
                }
                self.presentNotice = .error(.unableToUpdateAddress)
                self.analytics.track(event: WooAnalyticsEvent.OrderDetailsEdit.orderDetailEditFlowFailed(subject: self.analyticsFlowType()))
            }
            onFinish(result.isSuccess)
        }

        performingNetworkRequest.send(true)
        stores.dispatch(action)
    }

    override func trackOnLoad() {
        analytics.track(event: WooAnalyticsEvent.OrderDetailsEdit.orderDetailEditFlowStarted(subject: self.analyticsFlowType()))
    }

    func userDidCancelFlow() {
        analytics.track(event: WooAnalyticsEvent.OrderDetailsEdit.orderDetailEditFlowCanceled(subject: self.analyticsFlowType()))
    }
}

private extension EditOrderAddressFormViewModel {

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
