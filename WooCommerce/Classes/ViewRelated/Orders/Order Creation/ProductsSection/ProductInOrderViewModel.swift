import Yosemite
import Combine
import WooFoundation

/// View model for `ProductInOrder`.
///
final class ProductInOrderViewModel: Identifiable, ObservableObject {
    /// Encapsulates the necessary information to execute adding discounts to products
    /// 
    struct DiscountConfiguration {
        let addedDiscount: Decimal
        let baseAmountForDiscountPercentage: Decimal
        let onSaveFormattedDiscount: (String?) -> Void
    }

    /// The product being edited.
    ///
    let productRowViewModel: ProductRowViewModel

    let addedDiscount: Decimal

    var formattedDiscount: String? {
        currencyFormatter.formatAmount(addedDiscount)
    }

    let baseAmountForDiscountPercentage: Decimal

    /// Closure invoked when the product is removed.
    ///
    let onRemoveProduct: () -> Void

    /// Analytics engine.
    ///
    private let analytics: Analytics

    private let isAddingDiscountToProductEnabled: Bool

    var showAddDiscountRow: Bool {
        isAddingDiscountToProductEnabled && addedDiscount == 0
    }

    var showCurrentDiscountSection: Bool {
        isAddingDiscountToProductEnabled && addedDiscount != 0
    }

    let onSaveFormattedDiscount: (String?) -> Void

    let showCouponsAndDiscountsAlert: Bool

    var viewDismissPublisher = PassthroughSubject<(), Never>()

    private let currencyFormatter: CurrencyFormatter

    init(productRowViewModel: ProductRowViewModel,
         productDiscountConfiguration: DiscountConfiguration?,
         showCouponsAndDiscountsAlert: Bool,
         storeCurrencySettings: CurrencySettings = ServiceLocator.currencySettings,
         analytics: Analytics = ServiceLocator.analytics,
         onRemoveProduct: @escaping () -> Void) {
        self.productRowViewModel = productRowViewModel
        self.addedDiscount = productDiscountConfiguration?.addedDiscount ?? .zero
        self.baseAmountForDiscountPercentage = productDiscountConfiguration?.baseAmountForDiscountPercentage  ?? .zero
        self.onRemoveProduct = onRemoveProduct
        self.onSaveFormattedDiscount = productDiscountConfiguration?.onSaveFormattedDiscount ?? { _ in }
        self.isAddingDiscountToProductEnabled = productDiscountConfiguration != nil
        self.showCouponsAndDiscountsAlert = showCouponsAndDiscountsAlert
        self.currencyFormatter = CurrencyFormatter(currencySettings: storeCurrencySettings)
        self.analytics = analytics
    }

    lazy var discountDetailsViewModel: FeeOrDiscountLineDetailsViewModel = {
        FeeOrDiscountLineDetailsViewModel(isExistingLine: addedDiscount != 0,
                                          baseAmountForPercentage: baseAmountForDiscountPercentage,
                                          initialTotal: formattedDiscount ?? "0",
                                          lineType: .discount,
                                          didSelectSave: { [weak self] formattedAmount in
            self?.onSaveFormattedDiscount(formattedAmount)
            self?.viewDismissPublisher.send(())
        })
    }()

    func onAddDiscountTapped() {
        analytics.track(event: .Orders.productDiscountAddButtonTapped())
    }

    func onEditDiscountTapped() {
        analytics.track(event: .Orders.productDiscountEditButtonTapped())
    }
}
