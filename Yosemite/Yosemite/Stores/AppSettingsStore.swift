import Storage
import Networking
import Combine

// MARK: - AppSettingsStore
//
public class AppSettingsStore: Store {
    /// Loads a plist file at a given URL
    ///
    private let fileStorage: FileStorage

    private let generalSettingsService: GeneralAppSettingsService

    /// Designated initaliser
    ///
    public init(dispatcher: Dispatcher,
                storageManager: StorageManagerType,
                fileStorage: FileStorage,
                generalSettingsService: GeneralAppSettingsService? = nil) {
        self.fileStorage = fileStorage
        if let generalSettingsService = generalSettingsService {
            self.generalSettingsService = generalSettingsService
        } else {
            self.generalSettingsService = GeneralAppSettingsService(fileStorage: fileStorage, fileURL: Self.generalAppSettingsFileURL)
        }
        super.init(dispatcher: dispatcher,
                   storageManager: storageManager,
                   network: NullNetwork())
    }

    /// URL to the plist file that we use to store the user selected
    /// shipment tracing provider. Not declared as `private` so it can
    /// be overridden in tests
    ///
    lazy var selectedProvidersURL: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents!.appendingPathComponent(Constants.shipmentProvidersFileName)
    }()

    /// URL to the plist file that we use to store the user selected
    /// custom shipment tracing provider. Not declared as `private` so it can
    /// be overridden in tests
    ///
    lazy var customSelectedProvidersURL: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents!.appendingPathComponent(Constants.customShipmentProvidersFileName)
    }()

    /// URL to the plist file that we use to determine the visibility for stats version banner.
    ///
    private lazy var statsVersionBannerVisibilityURL: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents!.appendingPathComponent(Constants.statsVersionBannerVisibilityFileName)
    }()

    /// URL to the plist file that we use to store the stats version displayed on Dashboard UI.
    ///
    private lazy var statsVersionLastShownURL: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents!.appendingPathComponent(Constants.statsVersionLastShownFileName)
    }()

    private static let generalAppSettingsFileURL: URL! = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents!.appendingPathComponent(Constants.generalAppSettingsFileName)
    }()

    private lazy var generalStoreSettingsFileURL: URL! = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents!.appendingPathComponent(Constants.generalStoreSettingsFileName)
    }()

    /// URL to the plist file that we use to determine the settings applied in Orders
    ///
    private lazy var ordersSettingsURL: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents!.appendingPathComponent(Constants.ordersSettings)
    }()

    /// URL to the plist file that we use to determine the settings applied in Products
    ///
    private lazy var productsSettingsURL: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents!.appendingPathComponent(Constants.productsSettings)
    }()

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: AppSettingsAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? AppSettingsAction else {
            assertionFailure("ShipmentStore received an unsupported action")
            return
        }

        switch action {
        case .addTrackingProvider(let siteID, let providerName, let onCompletion):
            addTrackingProvider(siteID: siteID,
                                providerName: providerName,
                                onCompletion: onCompletion)
        case .loadTrackingProvider(let siteID, let onCompletion):
            loadTrackingProvider(siteID: siteID,
                                 onCompletion: onCompletion)
        case .addCustomTrackingProvider(let siteID,
                                        let providerName,
                                        let providerURL,
                                        let onCompletion):
            addCustomTrackingProvider(siteID: siteID,
                                      providerName: providerName,
                                      providerURL: providerURL,
                                      onCompletion: onCompletion)
        case .loadCustomTrackingProvider(let siteID,
                                         let onCompletion):
            loadCustomTrackingProvider(siteID: siteID,
                                       onCompletion: onCompletion)
        case .resetStoredProviders(let onCompletion):
            resetStoredProviders(onCompletion: onCompletion)
        case .setStatsVersionLastShown(let siteID, let statsVersion):
            setStatsVersionLastShownOrFromUserPreference(siteID: siteID, statsVersion: statsVersion)
        case .loadInitialStatsVersionToShow(let siteID, let onCompletion):
            loadInitialStatsVersionToShow(siteID: siteID, onCompletion: onCompletion)
        case .loadStatsVersionBannerVisibility(let banner, let onCompletion):
            loadStatsVersionBannerVisibility(banner: banner, onCompletion: onCompletion)
        case .setStatsVersionBannerVisibility(let banner, let shouldShowBanner):
            setStatsVersionBannerVisibility(banner: banner, shouldShowBanner: shouldShowBanner)
        case .resetStatsVersionStates:
            resetStatsVersionStates()
        case .setInstallationDateIfNecessary(let date, let onCompletion):
            setInstallationDateIfNecessary(date: date, onCompletion: onCompletion)
        case .updateFeedbackStatus(let type, let status, let onCompletion):
            updateFeedbackStatus(type: type, status: status, onCompletion: onCompletion)
        case .loadFeedbackVisibility(let type, let onCompletion):
            loadFeedbackVisibility(type: type, onCompletion: onCompletion)
        case .loadOrdersSettings(let siteID, let onCompletion):
            loadOrdersSettings(siteID: siteID, onCompletion: onCompletion)
        case .upsertOrdersSettings(let siteID,
                                   let orderStatusesFilter,
                                   let dateRangeFilter,
                                   let onCompletion):
            upsertOrdersSettings(siteID: siteID,
                                 orderStatusesFilter: orderStatusesFilter,
                                 dateRangeFilter: dateRangeFilter,
                                 onCompletion: onCompletion)
        case .resetOrdersSettings:
            resetOrdersSettings()
        case .loadProductsSettings(let siteID, let onCompletion):
            loadProductsSettings(siteID: siteID, onCompletion: onCompletion)
        case .upsertProductsSettings(let siteID,
                                     let sort,
                                     let stockStatusFilter,
                                     let productStatusFilter,
                                     let productTypeFilter,
                                     let productCategoryFilter,
                                     let onCompletion):
            upsertProductsSettings(siteID: siteID,
                                   sort: sort,
                                   stockStatusFilter: stockStatusFilter,
                                   productStatusFilter: productStatusFilter,
                                   productTypeFilter: productTypeFilter,
                                   productCategoryFilter: productCategoryFilter,
                                   onCompletion: onCompletion)
        case .resetProductsSettings:
            resetProductsSettings()
        case .setOrderAddOnsFeatureSwitchState(isEnabled: let isEnabled, onCompletion: let onCompletion):
            setOrderAddOnsFeatureSwitchState(isEnabled: isEnabled, onCompletion: onCompletion)
        case .loadOrderAddOnsSwitchState(onCompletion: let onCompletion):
            loadOrderAddOnsSwitchState(onCompletion: onCompletion)
        case .setOrderCreationFeatureSwitchState(isEnabled: let isEnabled, onCompletion: let onCompletion):
            setOrderCreationFeatureSwitchState(isEnabled: isEnabled, onCompletion: onCompletion)
        case .loadOrderCreationSwitchState(onCompletion: let onCompletion):
            loadOrderCreationSwitchState(onCompletion: onCompletion)
        case .rememberCardReader(cardReaderID: let cardReaderID, onCompletion: let onCompletion):
            rememberCardReader(cardReaderID: cardReaderID, onCompletion: onCompletion)
        case .forgetCardReader(onCompletion: let onCompletion):
            forgetCardReader(onCompletion: onCompletion)
        case .loadCardReader(onCompletion: let onCompletion):
            loadCardReader(onCompletion: onCompletion)
        case .loadEligibilityErrorInfo(onCompletion: let onCompletion):
            loadEligibilityErrorInfo(onCompletion: onCompletion)
        case .setEligibilityErrorInfo(errorInfo: let errorInfo, onCompletion: let onCompletion):
            setEligibilityErrorInfo(errorInfo: errorInfo, onCompletion: onCompletion)
        case .resetEligibilityErrorInfo:
            setEligibilityErrorInfo(errorInfo: nil)
        case .setJetpackBenefitsBannerLastDismissedTime(time: let time):
            setJetpackBenefitsBannerLastDismissedTime(time: time)
        case .loadJetpackBenefitsBannerVisibility(currentTime: let currentTime, calendar: let calendar, onCompletion: let onCompletion):
            loadJetpackBenefitsBannerVisibility(currentTime: currentTime, calendar: calendar, onCompletion: onCompletion)
        case .setTelemetryAvailability(siteID: let siteID, isAvailable: let isAvailable):
            setTelemetryAvailability(siteID: siteID, isAvailable: isAvailable)
        case .setTelemetryLastReportedTime(siteID: let siteID, time: let time):
            setTelemetryLastReportedTime(siteID: siteID, time: time)
        case .getTelemetryInfo(siteID: let siteID, onCompletion: let onCompletion):
            getTelemetryInfo(siteID: siteID, onCompletion: onCompletion)
        case let .setSimplePaymentsTaxesToggleState(siteID, isOn, onCompletion):
            setSimplePaymentsTaxesToggleState(siteID: siteID, isOn: isOn, onCompletion: onCompletion)
        case let .getSimplePaymentsTaxesToggleState(siteID, onCompletion):
            getSimplePaymentsTaxesToggleState(siteID: siteID, onCompletion: onCompletion)
        case .resetGeneralStoreSettings:
            resetGeneralStoreSettings()
        case .loadStripeInPersonPaymentsSwitchState(onCompletion: let onCompletion):
            loadStripeInPersonPaymentsSwitchState(onCompletion: onCompletion)
        case .observeStripeInPersonPaymentsSwitchState(onCompletion: let onCompletion):
            observeStripeInPersonPaymentsSwitchState(onCompletion: onCompletion)
        case .setStripeInPersonPaymentsSwitchState(isEnabled: let isEnabled, onCompletion: let onCompletion):
            setStripeInPersonPaymentsSwitchState(isEnabled: isEnabled, onCompletion: onCompletion)
        case .loadCanadaInPersonPaymentsSwitchState(onCompletion: let onCompletion):
            loadCanadaInPersonPaymentsSwitchState(onCompletion: onCompletion)
        case .observeCanadaInPersonPaymentsSwitchState(onCompletion: let onCompletion):
            observeCanadaInPersonPaymentsSwitchState(onCompletion: onCompletion)
        case .setCanadaInPersonPaymentsSwitchState(isEnabled: let isEnabled, onCompletion: let onCompletion):
            setCanadaInPersonPaymentsSwitchState(isEnabled: isEnabled, onCompletion: onCompletion)
        case .setProductSKUInputScannerFeatureSwitchState(isEnabled: let isEnabled, onCompletion: let onCompletion):
            setProductSKUInputScannerFeatureSwitchState(isEnabled: isEnabled, onCompletion: onCompletion)
        case .loadProductSKUInputScannerFeatureSwitchState(onCompletion: let onCompletion):
            loadProductSKUInputScannerFeatureSwitchState(onCompletion: onCompletion)
        case .setCouponManagementFeatureSwitchState(let isEnabled, let onCompletion):
            setCouponManagementFeatureSwitchState(isEnabled: isEnabled, onCompletion: onCompletion)
        case .loadCouponManagementFeatureSwitchState(let onCompletion):
            loadCouponManagementFeatureSwitchState(onCompletion: onCompletion)
        }
    }
}

// MARK: - General App Settings

private extension AppSettingsStore {
    /// Save the `date` in `GeneralAppSettings` but only if the `date` is older than the existing
    /// `GeneralAppSettings.installationDate`.
    ///
    /// - Parameter onCompletion: The `Result`'s success value will be `true` if the installation
    ///                           date was changed and `false` if not.
    ///
    func setInstallationDateIfNecessary(date: Date, onCompletion: ((Result<Bool, Error>) -> Void)) {
        do {
            if let installationDate = generalSettingsService.value(for: \.installationDate),
               date > installationDate {
                return onCompletion(.success(false))
            }

            try generalSettingsService.update(date, for: \.installationDate)

            onCompletion(.success(true))
        } catch {
            onCompletion(.failure(error))
        }
    }

    /// Updates the feedback store  in `GeneralAppSettings` with the given `type` and `status`.
    ///
    func updateFeedbackStatus(type: FeedbackType, status: FeedbackSettings.Status, onCompletion: ((Result<Void, Error>) -> Void)) {
        do {
            let newFeedback = FeedbackSettings(name: type, status: status)
            try generalSettingsService.patch(newFeedback, into: \.feedbacks, key: type)

            onCompletion(.success(()))
        } catch {
            onCompletion(.failure(error))
        }
    }

    func loadFeedbackVisibility(type: FeedbackType, onCompletion: (Result<Bool, Error>) -> Void) {
        let feedbackSettings = generalSettingsService.pluck(from: \.feedbacks, key: type)
        let installationDate = generalSettingsService.value(for: \.installationDate)
        let useCase = InAppFeedbackCardVisibilityUseCase(feedbackType: type, feedbackSettings: feedbackSettings, installationDate: installationDate)

        onCompletion(Result {
            try useCase.shouldBeVisible()
        })
    }

    /// Sets the provided Order Add-Ons beta feature switch state into `GeneralAppSettings`
    ///
    func setOrderAddOnsFeatureSwitchState(isEnabled: Bool, onCompletion: (Result<Void, Error>) -> Void) {
        do {
            try generalSettingsService.update(isEnabled, for: \.isViewAddOnsSwitchEnabled)
            onCompletion(.success(()))
        } catch {
            onCompletion(.failure(error))
        }

    }

    /// Loads the current Order Add-Ons beta feature switch state from `GeneralAppSettings`
    ///
    func loadOrderAddOnsSwitchState(onCompletion: (Result<Bool, Error>) -> Void) {
        let value = generalSettingsService.value(for: \.isViewAddOnsSwitchEnabled)
        onCompletion(.success(value))
    }

    /// Loads the current Order Creation beta feature switch state from `GeneralAppSettings`
    ///
    func loadOrderCreationSwitchState(onCompletion: (Result<Bool, Error>) -> Void) {
        let value = generalSettingsService.value(for: \.isOrderCreationSwitchEnabled)
        onCompletion(.success(value))
    }

    /// Sets the provided Order Creation beta feature switch state into `GeneralAppSettings`
    ///
    func setOrderCreationFeatureSwitchState(isEnabled: Bool, onCompletion: (Result<Void, Error>) -> Void) {
        do {
            try generalSettingsService.update(isEnabled, for: \.isOrderCreationSwitchEnabled)
            onCompletion(.success(()))
        } catch {
            onCompletion(.failure(error))
        }

    }

    /// Loads the current WooCommerce Stripe Payment Gateway extension In-Person Payments beta feature switch state from `GeneralAppSettings`
    ///
    func loadStripeInPersonPaymentsSwitchState(onCompletion: (Result<Bool, Error>) -> Void) {
        let value = generalSettingsService.value(for: \.isStripeInPersonPaymentsSwitchEnabled)
        onCompletion(.success(value))
    }

    func observeStripeInPersonPaymentsSwitchState(onCompletion: (AnyPublisher<Bool, Never>) -> Void) {
        let publisher = generalSettingsService.publisher(for: \.isStripeInPersonPaymentsSwitchEnabled)
        onCompletion(publisher)
    }

    /// Sets the provided WooCommerce Stripe Payment Gateway extension In-Person Payments  beta feature switch state into `GeneralAppSettings`
    ///
    func setStripeInPersonPaymentsSwitchState(isEnabled: Bool, onCompletion: (Result<Void, Error>) -> Void) {
        do {
            try generalSettingsService.update(isEnabled, for: \.isStripeInPersonPaymentsSwitchEnabled)
            onCompletion(.success(()))
        } catch {
            onCompletion(.failure(error))
        }
    }

    /// Loads the current In-Person Payments in Canada beta feature switch state from `GeneralAppSettings`
    ///
    func loadCanadaInPersonPaymentsSwitchState(onCompletion: (Result<Bool, Error>) -> Void) {
        let value = generalSettingsService.value(for: \.isCanadaInPersonPaymentsSwitchEnabled)
        onCompletion(.success(value))
    }

    func observeCanadaInPersonPaymentsSwitchState(onCompletion: (AnyPublisher<Bool, Never>) -> Void) {
        let publisher = generalSettingsService.publisher(for: \.isCanadaInPersonPaymentsSwitchEnabled)
        onCompletion(publisher)
    }


    /// Sets the provided In-Person Payments in Canada beta feature switch state into `GeneralAppSettings`
    ///
    func setCanadaInPersonPaymentsSwitchState(isEnabled: Bool, onCompletion: (Result<Void, Error>) -> Void) {
        do {
            try generalSettingsService.update(isEnabled, for: \.isCanadaInPersonPaymentsSwitchEnabled)
            onCompletion(.success(()))
        } catch {
            onCompletion(.failure(error))
        }
    }

    /// Sets the state for the Product SKU Input Scanner beta feature switch into `GeneralAppSettings`.
    ///
    func setProductSKUInputScannerFeatureSwitchState(isEnabled: Bool, onCompletion: (Result<Void, Error>) -> Void) {
        do {
            try generalSettingsService.update(isEnabled, for: \.isProductSKUInputScannerSwitchEnabled)
            onCompletion(.success(()))
        } catch {
            onCompletion(.failure(error))
        }
    }

    /// Loads the most recent state for the Product SKU Input Scanner beta feature switch from `GeneralAppSettings`.
    ///
    func loadProductSKUInputScannerFeatureSwitchState(onCompletion: (Result<Bool, Error>) -> Void) {
        let value = generalSettingsService.value(for: \.isProductSKUInputScannerSwitchEnabled)
        onCompletion(.success(value))
    }

    /// Sets the state for the Coupon Mangagement beta feature switch into `GeneralAppSettings`.
    ///
    func setCouponManagementFeatureSwitchState(isEnabled: Bool, onCompletion: (Result<Void, Error>) -> Void) {
        do {
            try generalSettingsService.update(isEnabled, for: \.isCouponManagementSwitchEnabled)
            onCompletion(.success(()))
        } catch {
            onCompletion(.failure(error))
        }
    }

    /// Loads the most recent state for the Coupon Management beta feature switch from `GeneralAppSettings`.
    ///
    func loadCouponManagementFeatureSwitchState(onCompletion: (Result<Bool, Error>) -> Void) {
        let value = generalSettingsService.value(for: \.isCouponManagementSwitchEnabled)
        onCompletion(.success(value))
    }

    /// Loads the last persisted eligibility error information from `GeneralAppSettings`
    ///
    func loadEligibilityErrorInfo(onCompletion: (Result<EligibilityErrorInfo, Error>) -> Void) {
        guard let errorInfo = generalSettingsService.value(for: \.lastEligibilityErrorInfo) else {
            return onCompletion(.failure(AppSettingsStoreErrors.noEligibilityErrorInfo))
        }

        onCompletion(.success(errorInfo))
    }

    func setEligibilityErrorInfo(errorInfo: EligibilityErrorInfo?, onCompletion: ((Result<Void, Error>) -> Void)? = nil) {
        do {
            try generalSettingsService.update(errorInfo, for: \.lastEligibilityErrorInfo)
            onCompletion?(.success(()))
        } catch {
            onCompletion?(.failure(error))
        }
    }

    // Visibility of Jetpack benefits banner in the Dashboard

    func setJetpackBenefitsBannerLastDismissedTime(time: Date, onCompletion: ((Result<Void, Error>) -> Void)? = nil) {        do {
        try generalSettingsService.update(time, for: \.lastJetpackBenefitsBannerDismissedTime)
        onCompletion?(.success(()))
    } catch {
        onCompletion?(.failure(error))
    }

    }

    func loadJetpackBenefitsBannerVisibility(currentTime: Date, calendar: Calendar, onCompletion: (Bool) -> Void) {
        guard let lastDismissedTime = generalSettingsService.value(for: \.lastJetpackBenefitsBannerDismissedTime) else {
            // If the banner has not been dismissed before, the banner is default to be visible.
            return onCompletion(true)
        }

        guard let numberOfDaysSinceLastDismissal = calendar.dateComponents([.day], from: lastDismissedTime, to: currentTime).day else {
            return onCompletion(true)
        }
        onCompletion(numberOfDaysSinceLastDismissal >= 5)
    }
}

// MARK: - Card Reader Actions
//
private extension AppSettingsStore {
    /// Remember the given card reader (to support automatic reconnection)
    /// where `cardReaderID` is a String e.g. "CHB204909005931"
    ///
    func rememberCardReader(cardReaderID: String, onCompletion: (Result<Void, Error>) -> Void) {
        do {
            /// NOTE: We now only persist one card reader maximum, although for backwards compatibility
            /// we still do so as an array
            try generalSettingsService.update([cardReaderID], for: \.knownCardReaders)
            onCompletion(.success(()))
        } catch {
            onCompletion(.failure(error))
        }
    }

    /// Forget any remembered card reader (i.e. automatic reconnection is no longer desired)
    ///
    func forgetCardReader(onCompletion: (Result<Void, Error>) -> Void) {
        do {
            /// NOTE: Since we now only persist one card reader maximum, we no longer use
            /// the argument and always save an empty array to the settings.
            try generalSettingsService.update([], for: \.knownCardReaders)
            onCompletion(.success(()))
        } catch {
            onCompletion(.failure(error))
        }
    }

    /// Loads the most recently remembered card reader, if any (i.e. to reconnect to automatically)
    /// NOTE: We now only persist one card reader maximum.
    /// E.g.  "CHB204909005931"
    ///
    func loadCardReader(onCompletion: (Result<String?, Error>) -> Void) {
        /// NOTE: We now only persist one card reader maximum, although for backwards compatibility
        /// we still do so as an array. We use last here so that we can get the most recently remembered
        /// reader from appSettings if populated by an older version
        guard let knownReader = generalSettingsService.value(for: \.knownCardReaders).last else {
            onCompletion(.success(nil))
            return
        }

        onCompletion(.success(knownReader))
    }
}

// MARK: - Shipment tracking providers!
//
private extension AppSettingsStore {
    func addTrackingProvider(siteID: Int64,
                             providerName: String,
                             onCompletion: (Error?) -> Void) {
        addProvider(siteID: siteID,
                    providerName: providerName,
                    fileURL: selectedProvidersURL,
                    onCompletion: onCompletion)

    }

    func addCustomTrackingProvider(siteID: Int64,
                                   providerName: String,
                                   providerURL: String?,
                                   onCompletion: (Error?) -> Void) {
        addProvider(siteID: siteID,
                    providerName: providerName,
                    providerURL: providerURL,
                    fileURL: customSelectedProvidersURL,
                    onCompletion: onCompletion)
    }

    func addProvider(siteID: Int64,
                     providerName: String,
                     providerURL: String? = nil,
                     fileURL: URL,
                     onCompletion: (Error?) -> Void) {
        guard let settings: [PreselectedProvider] = try? fileStorage.data(for: fileURL) else {
            insertNewProvider(siteID: siteID,
                              providerName: providerName,
                              providerURL: providerURL,
                              toFileURL: fileURL,
                              onCompletion: onCompletion)
            return
        }
        upsertTrackingProvider(siteID: siteID,
                               providerName: providerName,
                               preselectedData: settings,
                               toFileURL: fileURL,
                               onCompletion: onCompletion)
    }

    func loadTrackingProvider(siteID: Int64,
                              onCompletion: (ShipmentTrackingProvider?, ShipmentTrackingProviderGroup?, Error?) -> Void) {
        guard let allSavedProviders: [PreselectedProvider] = try? fileStorage.data(for: selectedProvidersURL) else {
            let error = AppSettingsStoreErrors.readPreselectedProvider
            onCompletion(nil, nil, error)
            return
        }

        let providerName = allSavedProviders.filter {
            $0.siteID == siteID
        }.first?.providerName

        guard let name = providerName else {
            let error = AppSettingsStoreErrors.readPreselectedProvider
            onCompletion(nil, nil, error)
            return
        }

        let provider = storageManager
            .viewStorage
            .loadShipmentTrackingProvider(siteID: siteID,
                                          name: name)

        onCompletion(provider?.toReadOnly(), provider?.group?.toReadOnly(), nil)
    }

    func loadCustomTrackingProvider(siteID: Int64,
                                    onCompletion: (ShipmentTrackingProvider?, Error?) -> Void) {
        guard let allSavedProviders: [PreselectedProvider] = try? fileStorage.data(for: customSelectedProvidersURL) else {
            let error = AppSettingsStoreErrors.readPreselectedProvider
            onCompletion(nil, error)
            return
        }

        let providerName = allSavedProviders.filter {
            $0.siteID == siteID
        }.first?.providerName

        let providerURL = allSavedProviders.filter {
            $0.siteID == siteID
        }.first?.providerURL

        guard let name = providerName else {
            let error = AppSettingsStoreErrors.readPreselectedProvider
            onCompletion(nil, error)
            return
        }

        let customProvider = ShipmentTrackingProvider(siteID: siteID,
                                                      name: name,
                                                      url: providerURL ?? "")
        onCompletion(customProvider, nil)
    }

    func upsertTrackingProvider(siteID: Int64,
                                providerName: String,
                                providerURL: String? = nil,
                                preselectedData: [PreselectedProvider],
                                toFileURL: URL,
                                onCompletion: (Error?) -> Void) {
        let newPreselectedProvider = PreselectedProvider(siteID: siteID,
                                                         providerName: providerName,
                                                         providerURL: providerURL)

        var dataToSave = preselectedData

        if preselectedData.contains(newPreselectedProvider),
           let index = preselectedData.firstIndex(of: newPreselectedProvider) {
            dataToSave[index] = newPreselectedProvider
        } else {
            dataToSave.append(newPreselectedProvider)
        }

        do {
            try fileStorage.write(dataToSave, to: toFileURL)
            onCompletion(nil)
        } catch {
            onCompletion(error)
        }
    }

    func insertNewProvider(siteID: Int64,
                           providerName: String,
                           providerURL: String? = nil,
                           toFileURL: URL,
                           onCompletion: (Error?) -> Void) {
        let preselectedProvider = PreselectedProvider(siteID: siteID,
                                                      providerName: providerName,
                                                      providerURL: providerURL)

        do {
            try fileStorage.write([preselectedProvider], to: toFileURL)
            onCompletion(nil)
        } catch {
            onCompletion(error)
        }
    }

    func resetStoredProviders(onCompletion: ((Error?) -> Void)? = nil) {
        do {
            try fileStorage.deleteFile(at: selectedProvidersURL)
            try fileStorage.deleteFile(at: customSelectedProvidersURL)
            onCompletion?(nil)
        } catch {
            let error = AppSettingsStoreErrors.deletePreselectedProvider
            onCompletion?(error)
        }
    }
}

// MARK: - Stats version
//
private extension AppSettingsStore {
    func setStatsVersionLastShownOrFromUserPreference(siteID: Int64,
                                                      statsVersion: StatsVersion) {
        set(statsVersion: statsVersion, for: siteID, to: statsVersionLastShownURL, onCompletion: { error in
            if let error = error {
                DDLogError("⛔️ Saving the last shown stats version failed: siteID \(siteID). Error: \(error)")
            }
        })
    }

    func loadInitialStatsVersionToShow(siteID: Int64, onCompletion: (StatsVersion?) -> Void) {
        guard let existingData: StatsVersionBySite = try? fileStorage.data(for: statsVersionLastShownURL),
              let statsVersion = existingData.statsVersionBySite[siteID] else {
            onCompletion(nil)
            return
        }
        onCompletion(statsVersion)
    }

    func set(statsVersion: StatsVersion, for siteID: Int64, to fileURL: URL, onCompletion: (Error?) -> Void) {
        guard let existingData: StatsVersionBySite = try? fileStorage.data(for: fileURL) else {
            let statsVersionBySite: StatsVersionBySite = StatsVersionBySite(statsVersionBySite: [siteID: statsVersion])
            do {
                try fileStorage.write(statsVersionBySite, to: fileURL)
                onCompletion(nil)
            } catch {
                onCompletion(error)
            }
            return
        }

        var statsVersionBySite = existingData.statsVersionBySite
        statsVersionBySite[siteID] = statsVersion
        do {
            try fileStorage.write(StatsVersionBySite(statsVersionBySite: statsVersionBySite), to: fileURL)
            onCompletion(nil)
        } catch {
            onCompletion(error)
        }
    }

    func loadStatsVersionBannerVisibility(banner: StatsVersionBannerVisibility.StatsVersionBanner,
                                          onCompletion: (Bool) -> Void) {
        guard let existingData: StatsVersionBannerVisibility = try? fileStorage.data(for: statsVersionBannerVisibilityURL),
              let shouldShowBanner = existingData.visibilityByBanner[banner] else {
            onCompletion(true)
            return
        }
        onCompletion(shouldShowBanner)
    }

    func setStatsVersionBannerVisibility(banner: StatsVersionBannerVisibility.StatsVersionBanner,
                                         shouldShowBanner: Bool) {
        let fileURL = statsVersionBannerVisibilityURL
        guard let existingData: StatsVersionBannerVisibility = try? fileStorage.data(for: statsVersionBannerVisibilityURL) else {
            let statsVersionBySite: StatsVersionBannerVisibility = StatsVersionBannerVisibility(visibilityByBanner: [banner: shouldShowBanner])
            try? fileStorage.write(statsVersionBySite, to: fileURL)
            return
        }

        var visibilityByBanner = existingData.visibilityByBanner
        visibilityByBanner[banner] = shouldShowBanner
        try? fileStorage.write(StatsVersionBannerVisibility(visibilityByBanner: visibilityByBanner), to: fileURL)
    }

    func resetStatsVersionStates() {
        do {
            try fileStorage.deleteFile(at: statsVersionBannerVisibilityURL)
            try fileStorage.deleteFile(at: statsVersionLastShownURL)
        } catch {
            let error = AppSettingsStoreErrors.deleteStatsVersionStates
            DDLogError("⛔️ Deleting the stats version files failed. Error: \(error)")
        }
    }
}

// MARK: - Orders Settings
//
private extension AppSettingsStore {
    func loadOrdersSettings(siteID: Int64, onCompletion: (Result<StoredOrderSettings.Setting, Error>) -> Void) {
        guard let allSavedSettings: StoredOrderSettings = try? fileStorage.data(for: ordersSettingsURL),
                let settingsUnwrapped = allSavedSettings.settings[siteID] else {
            let error = AppSettingsStoreErrors.noOrdersSettings
            onCompletion(.failure(error))
            return
        }

        onCompletion(.success(settingsUnwrapped))
    }

    func upsertOrdersSettings(siteID: Int64,
                              orderStatusesFilter: [OrderStatusEnum]?,
                              dateRangeFilter: OrderDateRangeFilter?,
                              onCompletion: (Error?) -> Void) {
        var existingSettings: [Int64: StoredOrderSettings.Setting] = [:]
        if let storedSettings: StoredOrderSettings = try? fileStorage.data(for: ordersSettingsURL) {
            existingSettings = storedSettings.settings
        }

        let newSettings = StoredOrderSettings.Setting(siteID: siteID,
                                                      orderStatusesFilter: orderStatusesFilter,
                                                      dateRangeFilter: dateRangeFilter)
        existingSettings[siteID] = newSettings

        let newStoredOrderSettings = StoredOrderSettings(settings: existingSettings)
        do {
            try fileStorage.write(newStoredOrderSettings, to: ordersSettingsURL)
            onCompletion(nil)
        } catch {
            onCompletion(AppSettingsStoreErrors.writeOrdersSettings)
        }
    }

    func resetOrdersSettings() {
        do {
            try fileStorage.deleteFile(at: ordersSettingsURL)
        } catch {
            DDLogError("⛔️ Deleting the orders settings files failed. Error: \(error)")
        }
    }
}

// MARK: - Products Settings
//
private extension AppSettingsStore {
    func loadProductsSettings(siteID: Int64, onCompletion: (Result<StoredProductSettings.Setting, Error>) -> Void) {
        guard let allSavedSettings: StoredProductSettings = try? fileStorage.data(for: productsSettingsURL) else {
            let error = AppSettingsStoreErrors.noProductsSettings
            onCompletion(.failure(error))
            return
        }

        guard let settingsUnwrapped = allSavedSettings.settings[siteID] else {
            let error = AppSettingsStoreErrors.noProductsSettings
            onCompletion(.failure(error))
            return
        }

        onCompletion(.success(settingsUnwrapped))
    }

    func upsertProductsSettings(siteID: Int64,
                                sort: String? = nil,
                                stockStatusFilter: ProductStockStatus? = nil,
                                productStatusFilter: ProductStatus? = nil,
                                productTypeFilter: ProductType? = nil,
                                productCategoryFilter: ProductCategory? = nil,
                                onCompletion: (Error?) -> Void) {
        var existingSettings: [Int64: StoredProductSettings.Setting] = [:]
        if let storedSettings: StoredProductSettings = try? fileStorage.data(for: productsSettingsURL) {
            existingSettings = storedSettings.settings
        }

        let newSetting = StoredProductSettings.Setting(siteID: siteID,
                                                       sort: sort,
                                                       stockStatusFilter: stockStatusFilter,
                                                       productStatusFilter: productStatusFilter,
                                                       productTypeFilter: productTypeFilter,
                                                       productCategoryFilter: productCategoryFilter)
        existingSettings[siteID] = newSetting

        let newStoredProductSettings = StoredProductSettings(settings: existingSettings)
        do {
            try fileStorage.write(newStoredProductSettings, to: productsSettingsURL)
            onCompletion(nil)
        } catch {
            onCompletion(AppSettingsStoreErrors.writeProductsSettings)
        }
    }

    func resetProductsSettings() {
        do {
            try fileStorage.deleteFile(at: productsSettingsURL)
        } catch {
            DDLogError("⛔️ Deleting the product settings files failed. Error: \(error)")
        }
    }
}

// MARK: - Store settings
//
private extension AppSettingsStore {

    func getStoreSettings(for siteID: Int64) -> GeneralStoreSettings {
        guard let existingData: GeneralStoreSettingsBySite = try? fileStorage.data(for: generalStoreSettingsFileURL),
              let storeSettings = existingData.storeSettingsBySite[siteID] else {
            return GeneralStoreSettings()
        }

        return storeSettings
    }

    func setStoreSettings(settings: GeneralStoreSettings, for siteID: Int64, onCompletion: ((Result<Void, Error>) -> Void)? = nil) {
        var storeSettingsBySite: [Int64: GeneralStoreSettings] = [:]
        if let existingData: GeneralStoreSettingsBySite = try? fileStorage.data(for: generalStoreSettingsFileURL) {
            storeSettingsBySite = existingData.storeSettingsBySite
        }

        storeSettingsBySite[siteID] = settings

        do {
            try fileStorage.write(GeneralStoreSettingsBySite(storeSettingsBySite: storeSettingsBySite), to: generalStoreSettingsFileURL)
            onCompletion?(.success(()))
        } catch {
            onCompletion?(.failure(error))
            DDLogError("⛔️ Saving store settings to file failed. Error: \(error)")
        }
    }

    // Telemetry data

    func setTelemetryAvailability(siteID: Int64, isAvailable: Bool, onCompletion: ((Result<Void, Error>) -> Void)? = nil) {
        let storeSettings = getStoreSettings(for: siteID)
        let updatedSettings = storeSettings.copy(isTelemetryAvailable: isAvailable)
        setStoreSettings(settings: updatedSettings, for: siteID, onCompletion: onCompletion)
    }

    func setTelemetryLastReportedTime(siteID: Int64, time: Date, onCompletion: ((Result<Void, Error>) -> Void)? = nil) {
        let storeSettings = getStoreSettings(for: siteID)
        let updatedSettings = storeSettings.copy(telemetryLastReportedTime: time)
        setStoreSettings(settings: updatedSettings, for: siteID, onCompletion: onCompletion)
    }

    func getTelemetryInfo(siteID: Int64, onCompletion: (Bool, Date?) -> Void) {
        let storeSettings = getStoreSettings(for: siteID)
        onCompletion(storeSettings.isTelemetryAvailable, storeSettings.telemetryLastReportedTime)
    }

    func resetGeneralStoreSettings() {
        do {
            try fileStorage.deleteFile(at: generalStoreSettingsFileURL)
        } catch {
            DDLogError("⛔️ Deleting store settings file failed. Error: \(error)")
        }
    }

    // Simple Payments data

    /// Sets the last state of the simple payments taxes toggle for a provided store.
    ///
    func setSimplePaymentsTaxesToggleState(siteID: Int64, isOn: Bool, onCompletion: @escaping (Result<Void, Error>) -> Void) {
        let storeSettings = getStoreSettings(for: siteID)
        let newSettings = storeSettings.copy(areSimplePaymentTaxesEnabled: isOn)
        setStoreSettings(settings: newSettings, for: siteID, onCompletion: onCompletion)
    }

    /// Get the last state of the simple payments taxes toggle for a provided store.
    ///
    func getSimplePaymentsTaxesToggleState(siteID: Int64, onCompletion: @escaping (Result<Bool, Error>) -> Void) {
        let storeSettings = getStoreSettings(for: siteID)
        onCompletion(.success(storeSettings.areSimplePaymentTaxesEnabled))
    }
}

// MARK: - Errors

/// Errors
///
enum AppSettingsStoreErrors: Error {
    case parsePreselectedProvider
    case writePreselectedProvider
    case readPreselectedProvider
    case deletePreselectedProvider
    case readPListFromFileStorage
    case writePListToFileStorage
    case deleteStatsVersionStates
    case noOrdersSettings
    case noProductsSettings
    case writeOrdersSettings
    case writeProductsSettings
    case noEligibilityErrorInfo
}


// MARK: - Constants

/// Constants
///
private enum Constants {

    // MARK: File Names
    static let shipmentProvidersFileName = "shipment-providers.plist"
    static let customShipmentProvidersFileName = "custom-shipment-providers.plist"
    static let statsVersionBannerVisibilityFileName = "stats-version-banner-visibility.plist"
    static let statsVersionLastShownFileName = "stats-version-last-shown.plist"
    static let generalAppSettingsFileName = "general-app-settings.plist"
    static let generalStoreSettingsFileName = "general-store-settings.plist"
    static let ordersSettings = "orders-settings.plist"
    static let productsSettings = "products-settings.plist"
}
