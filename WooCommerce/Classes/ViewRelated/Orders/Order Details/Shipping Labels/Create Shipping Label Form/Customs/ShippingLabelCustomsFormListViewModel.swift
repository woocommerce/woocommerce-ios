import Combine
import Foundation
import Yosemite
import WooFoundation

/// View model for ShippingLabelsCustomsFormList
///
final class ShippingLabelCustomsFormListViewModel: ObservableObject {
    /// Whether multiple packages are found.
    ///
    let multiplePackagesDetected: Bool

    /// References of input view models.
    ///
    let inputViewModels: [ShippingLabelCustomsFormInputViewModel]

    /// Whether done button should be enabled.
    ///
    @Published private(set) var doneButtonEnabled: Bool = false

    /// Whether shipping notice banner should be displayed.
    ///
    @Published private(set) var isShippingNoticeVisible: Bool = false

    /// Associated order of the shipping label.
    ///
    private let order: Order

    /// Stores to sync data of products and variations.
    ///
    private let stores: StoresManager

    /// Persisted countries to send to item details form.
    ///
    private let allCountries: [Country]

    /// Destination country for the shipment.
    ///
    private let destinationCountry: Country

    var validatedCustomsForms: [ShippingLabelCustomsForm] {
        inputViewModels.compactMap { $0.validatedCustomsForm }
    }

    /// Symbol of currency in the order.
    ///
    private let currencySymbol: String

    /// Flags if it's a EU Shipping requiring specific Customs configuration
    ///
    private let isEUShippingScenario: Bool

    /// Validation states of all customs forms by indices of the forms.
    ///
    private var customsFormValidation: [Int: Bool] = [:] {
        didSet {
            configureDoneButton()
        }
    }

    /// References to keep the Combine subscriptions alive with the class.
    ///
    private var cancellables: Set<AnyCancellable> = []

    init(order: Order,
         customsForms: [ShippingLabelCustomsForm],
         destinationCountry: Country,
         countries: [Country],
         isEUShippingScenario: Bool = false,
         stores: StoresManager = ServiceLocator.stores) {
        self.order = order
        self.multiplePackagesDetected = customsForms.count > 1
        self.stores = stores
        self.allCountries = countries
        self.destinationCountry = destinationCountry
        let currencySymbol: String = {
            guard let currencyCode = CurrencyCode(rawValue: order.currency) else {
                return ""
            }
            return ServiceLocator.currencySettings.symbol(from: currencyCode)
        }()
        self.currencySymbol = currencySymbol
        self.isEUShippingScenario = isEUShippingScenario
        self.isShippingNoticeVisible = isEUShippingScenario
        self.inputViewModels = customsForms.map { .init(customsForm: $0,
                                                        destinationCountry: destinationCountry,
                                                        countries: countries,
                                                        currency: currencySymbol) }
        configureFormsValidation()
    }
}

// MARK: - Banner
//
extension ShippingLabelCustomsFormListViewModel {
    func bannerDismissTapped() {
        isShippingNoticeVisible = false
    }

    func onInfoTooltipTapped() {
        isShippingNoticeVisible = true
    }
}

// MARK: - Validation
//
private extension ShippingLabelCustomsFormListViewModel {
    /// Observe changes in all customs forms and save their validation states by package ID.
    ///
    func configureFormsValidation() {
        inputViewModels.enumerated().forEach { (index, viewModel) in
            viewModel.$validForm
                .sink { [weak self] isValid in
                    self?.customsFormValidation[index] = isValid
                }
                .store(in: &cancellables)
        }
    }

    /// Check if all forms are validated to enable Done button.
    ///
    func configureDoneButton() {
        doneButtonEnabled = customsFormValidation.values.first(where: { !$0 }) == nil
    }
}
