import Storage
import Networking

// MARK: - AppSettingsStore
//
public class AppSettingsStore: Store {
    /// Loads a plist file at a given URL
    ///
    private let fileStorage: FileStorage

    private let generalAppSettings: GeneralAppSettingsStorage

    /// Designated initaliser
    ///
    public init(dispatcher: Dispatcher,
                storageManager: StorageManagerType,
                fileStorage: FileStorage,
                generalAppSettings: GeneralAppSettingsStorage) {
        self.fileStorage = fileStorage
        self.generalAppSettings = generalAppSettings
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
                                   let productFilter,
                                   let customerFilter,
                                   let onCompletion):
            upsertOrdersSettings(siteID: siteID,
                                 orderStatusesFilter: orderStatusesFilter,
                                 dateRangeFilter: dateRangeFilter,
                                 productFilter: productFilter,
                                 customerFilter: customerFilter,
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
        case .setStoreID(let siteID, let id):
            setStoreID(siteID: siteID, id: id)
        case .getStoreID(let siteID, let onCompletion):
            getStoreID(siteID: siteID, onCompletion: onCompletion)
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
        case let .setPreferredInPersonPaymentGateway(siteID: siteID, gateway: gateway):
            setPreferredInPersonPaymentGateway(siteID: siteID, gateway: gateway)
        case let .getPreferredInPersonPaymentGateway(siteID: siteID, onCompletion: onCompletion):
            getPreferredInPersonPaymentGateway(siteID: siteID, onCompletion: onCompletion)
        case let .forgetPreferredInPersonPaymentGateway(siteID: siteID):
            forgetPreferredInPersonPaymentGateway(siteID: siteID)
        case .resetGeneralStoreSettings:
            resetGeneralStoreSettings()
        case .setFeatureAnnouncementDismissed(campaign: let campaign, remindAfterDays: let remindAfterDays, onCompletion: let completion):
            setFeatureAnnouncementDismissed(campaign: campaign, remindAfterDays: remindAfterDays, onCompletion: completion)
        case .getFeatureAnnouncementVisibility(campaign: let campaign, onCompletion: let completion):
            getFeatureAnnouncementVisibility(campaign: campaign, onCompletion: completion)
        case .setSkippedCashOnDeliveryOnboardingStep(siteID: let siteID):
            setSkippedCashOnDeliveryOnboardingStep(siteID: siteID)
        case .getSkippedCashOnDeliveryOnboardingStep(siteID: let siteID, onCompletion: let completion):
            getSkippedCashOnDeliveryOnboardingStep(siteID: siteID, onCompletion: completion)
        case .setLastSelectedStatsTimeRange(let siteID, let timeRange):
            setLastSelectedStatsTimeRange(siteID: siteID, timeRange: timeRange)
        case .loadLastSelectedStatsTimeRange(let siteID, let onCompletion):
            loadLastSelectedStatsTimeRange(siteID: siteID, onCompletion: onCompletion)
        case .loadSiteHasAtLeastOneIPPTransactionFinished(let siteID, let onCompletion):
            loadSiteHasAtLeastOneIPPTransactionFinished(siteID: siteID, onCompletion: onCompletion)
        case .loadFirstInPersonPaymentsTransactionDate(siteID: let siteID, cardReaderType: let cardReaderType, onCompletion: let completion):
            loadFirstInPersonPaymentsTransactionDate(siteID: siteID, using: cardReaderType, onCompletion: completion)
        case .storeInPersonPaymentsTransactionIfFirst(siteID: let siteID, cardReaderType: let cardReaderType):
            storeInPersonPaymentsTransactionIfFirst(siteID: siteID, using: cardReaderType)
        case .dismissEUShippingNotice(let onCompletion):
            setEUShippingNoticeDismissState(isDismissed: true, onCompletion: onCompletion)
        case .loadEUShippingNoticeDismissState(let onCompletion):
            loadEUShippingNoticeDismissState(onCompletion: onCompletion)
        case .setSelectedTaxRateID(let taxRateId, let siteID):
            setSelectedTaxRateID(with: taxRateId, siteID: siteID)
        case .loadSelectedTaxRateID(let siteID, let onCompletion):
            loadSelectedTaxRateID(with: siteID, onCompletion: onCompletion)
        case .setAnalyticsHubCards(let siteID, let cards):
            setAnalyticsHubCards(siteID: siteID, cards: cards)
        case .loadAnalyticsHubCards(let siteID, let onCompletion):
            loadAnalyticsHubCards(siteID: siteID, onCompletion: onCompletion)
        case let .loadCustomStatsTimeRange(siteID, onCompletion):
            loadCustomStatsTimeRange(siteID: siteID, onCompletion: onCompletion)
        case let .setCustomStatsTimeRange(siteID, timeRange):
            setCustomStatsTimeRange(siteID: siteID, timeRange: timeRange)
        case let .loadDashboardCards(siteID, onCompletion):
            loadDashboardCards(siteID: siteID, onCompletion: onCompletion)
        case let .setDashboardCards(siteID, cards):
            setDashboardCards(siteID: siteID, cards: cards)
        case let .setLastSelectedPerformanceTimeRange(siteID, timeRange):
            setLastSelectedPerformanceTimeRange(siteID: siteID, timeRange: timeRange)
        case let .loadLastSelectedPerformanceTimeRange(siteID, onCompletion):
            loadLastSelectedPerformanceTimeRange(siteID: siteID, onCompletion: onCompletion)
        case let .setLastSelectedTopPerformersTimeRange(siteID, timeRange):
            setLastSelectedTopPerformersTimeRange(siteID: siteID, timeRange: timeRange)
        case let .loadLastSelectedTopPerformersTimeRange(siteID, onCompletion):
            loadLastSelectedTopPerformersTimeRange(siteID: siteID, onCompletion: onCompletion)
        case let .setLastSelectedMostActiveCouponsTimeRange(siteID, timeRange):
            setLastSelectedMostActiveCouponsTimeRange(siteID: siteID, timeRange: timeRange)
        case let .loadLastSelectedMostActiveCouponsTimeRange(siteID, onCompletion):
            loadLastSelectedMostActiveCouponsTimeRange(siteID: siteID, onCompletion: onCompletion)
        case let .setLastSelectedStockType(siteID, type):
            setLastSelectedStockType(siteID: siteID, type: type)
        case let .loadLastSelectedStockType(siteID, onCompletion):
            loadLastSelectedStockType(siteID: siteID, onCompletion: onCompletion)
        case let .setLastSelectedOrderStatus(siteID, status):
            setLastSelectedOrderStatus(siteID: siteID, status: status)
        case let .loadLastSelectedOrderStatus(siteID, onCompletion):
            loadLastSelectedOrderStatus(siteID: siteID, onCompletion: onCompletion)
        case .setProductIDAsFavorite(let productID, let siteID):
            setProductIDAsFavorite(productID: productID, siteID: siteID)
        case .removeProductIDAsFavorite(let productID, let siteID):
            removeProductIDAsFavorite(productID: productID, siteID: siteID)
        case .loadFavoriteProductIDs(let siteID, let onCompletion):
            loadFavoriteProductIDs(for: siteID, onCompletion: onCompletion)
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
            if let installationDate = generalAppSettings.value(for: \.installationDate),
               date > installationDate {
                return onCompletion(.success(false))
            }

            try generalAppSettings.setValue(date, for: \.installationDate)

            onCompletion(.success(true))
        } catch {
            onCompletion(.failure(error))
        }
    }

    /// Updates the feedback store  in `GeneralAppSettings` with the given `type` and `status`.
    ///
    func updateFeedbackStatus(type: FeedbackType, status: FeedbackSettings.Status, onCompletion: ((Result<Void, Error>) -> Void)) {
        do {
            let settings = generalAppSettings.settings
            let newFeedback = FeedbackSettings(name: type, status: status)
            let settingsToSave = settings.replacing(feedback: newFeedback)
            try generalAppSettings.saveSettings(settingsToSave)

            onCompletion(.success(()))
        } catch {
            onCompletion(.failure(error))
        }
    }

    func loadFeedbackVisibility(type: FeedbackType, onCompletion: (Result<Bool, Error>) -> Void) {
        let settings = generalAppSettings.settings
        let useCase = InAppFeedbackCardVisibilityUseCase(settings: settings, feedbackType: type)

        onCompletion(Result {
            try useCase.shouldBeVisible()
        })
    }

    /// Sets the provided Order Add-Ons beta feature switch state into `GeneralAppSettings`
    ///
    func setOrderAddOnsFeatureSwitchState(isEnabled: Bool, onCompletion: (Result<Void, Error>) -> Void) {
        do {
            try generalAppSettings.setValue(isEnabled, for: \.isViewAddOnsSwitchEnabled)
            onCompletion(.success(()))
        } catch {
            onCompletion(.failure(error))
        }

    }

    /// Loads the current Order Add-Ons beta feature switch state from `GeneralAppSettings`
    ///
    func loadOrderAddOnsSwitchState(onCompletion: (Result<Bool, Error>) -> Void) {
        onCompletion(.success(generalAppSettings.value(for: \.isViewAddOnsSwitchEnabled)))
    }

    /// Loads the last persisted eligibility error information from `GeneralAppSettings`
    ///
    func loadEligibilityErrorInfo(onCompletion: (Result<EligibilityErrorInfo, Error>) -> Void) {
        guard let errorInfo = generalAppSettings.value(for: \.lastEligibilityErrorInfo) else {
            return onCompletion(.failure(AppSettingsStoreErrors.noEligibilityErrorInfo))
        }

        onCompletion(.success(errorInfo))
    }

    func setEligibilityErrorInfo(errorInfo: EligibilityErrorInfo?, onCompletion: ((Result<Void, Error>) -> Void)? = nil) {
        do {
            try generalAppSettings.setValue(errorInfo, for: \.lastEligibilityErrorInfo)
            onCompletion?(.success(()))
        } catch {
            onCompletion?(.failure(error))
        }
    }

    // Visibility of Jetpack benefits banner in the Dashboard

    func setJetpackBenefitsBannerLastDismissedTime(time: Date, onCompletion: ((Result<Void, Error>) -> Void)? = nil) {
        do {
            try generalAppSettings.setValue(time, for: \.lastJetpackBenefitsBannerDismissedTime)
            onCompletion?(.success(()))
        } catch {
            onCompletion?(.failure(error))
        }
    }

    func loadJetpackBenefitsBannerVisibility(currentTime: Date, calendar: Calendar, onCompletion: (Bool) -> Void) {
        guard let lastDismissedTime = generalAppSettings.value(for: \.lastJetpackBenefitsBannerDismissedTime) else {
            // If the banner has not been dismissed before, the banner is default to be visible.
            return onCompletion(true)
        }

        guard let numberOfDaysSinceLastDismissal = calendar.dateComponents([.day], from: lastDismissedTime, to: currentTime).day else {
            return onCompletion(true)
        }
        onCompletion(numberOfDaysSinceLastDismissal >= 5)
    }

    /// Sets the EU Shipping Notice dismissal state into `GeneralAppSettings`
    ///
    func setEUShippingNoticeDismissState(isDismissed: Bool, onCompletion: (Result<Void, Error>) -> Void) {
        do {
            try generalAppSettings.setValue(isDismissed, for: \.isEUShippingNoticeDismissed)
            onCompletion(.success(()))
        } catch {
            onCompletion(.failure(error))
        }

    }

    /// Loads the EU Shipping Notice dismissal state from `GeneralAppSettings`
    ///
    func loadEUShippingNoticeDismissState(onCompletion: (Result<Bool, Error>) -> Void) {
        onCompletion(.success(generalAppSettings.value(for: \.isEUShippingNoticeDismissed)))
    }
}

// MARK: - In Person Payments Actions
//
private extension AppSettingsStore {
    /// Remember the given card reader (to support automatic reconnection)
    /// where `cardReaderID` is a String e.g. "CHB204909005931"
    ///
    func rememberCardReader(cardReaderID: String, onCompletion: (Result<Void, Error>) -> Void) {
        do {
            guard !generalAppSettings.value(for: \.knownCardReaders).contains(cardReaderID) else {
                return onCompletion(.success(()))
            }

            /// NOTE: We now only persist one card reader maximum, although for backwards compatibility
            /// we still do so as an array
            let knownCardReadersToSave = [cardReaderID]
            try generalAppSettings.setValue(knownCardReadersToSave, for: \.knownCardReaders)

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
            try generalAppSettings.setValue([], for: \.knownCardReaders)
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
        guard let knownReader = generalAppSettings.value(for: \.knownCardReaders).last else {
            onCompletion(.success(nil))
            return
        }

        onCompletion(.success(knownReader))
    }

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

    /// Sets the preferred payment gateway for In-Person Payments
    ///
    func setPreferredInPersonPaymentGateway(siteID: Int64, gateway: String) {
        let storeSettings = getStoreSettings(for: siteID)
        let newSettings = storeSettings.copy(preferredInPersonPaymentGateway: gateway)
        setStoreSettings(settings: newSettings, for: siteID, onCompletion: nil)
    }

    /// Gets the preferred payment gateway for In-Person Payments
    ///
    func getPreferredInPersonPaymentGateway(siteID: Int64, onCompletion: (String?) -> Void) {
        let storeSettings = getStoreSettings(for: siteID)
        onCompletion(storeSettings.preferredInPersonPaymentGateway)
    }

    /// Forgets the preferred payment gateway for In-Person Payments
    ///
    func forgetPreferredInPersonPaymentGateway(siteID: Int64) {
        let storeSettings = getStoreSettings(for: siteID)
        let newSettings = storeSettings.copy(preferredInPersonPaymentGateway: .some(nil))
        setStoreSettings(settings: newSettings, for: siteID, onCompletion: nil)
    }

    /// Marks the Enable Cash on Delivery In-Person Payments Onboarding step as skipped
    ///
    func setSkippedCashOnDeliveryOnboardingStep(siteID: Int64) {
        let storeSettings = getStoreSettings(for: siteID)
        let newSettings = storeSettings.copy(skippedCashOnDeliveryOnboardingStep: true)
        setStoreSettings(settings: newSettings, for: siteID)
    }

    /// Gets whether the Enable Cash on Delivery In-Person Payments Onboarding step has been skipped
    ///
    func getSkippedCashOnDeliveryOnboardingStep(siteID: Int64, onCompletion: (Bool) -> Void) {
        let storeSettings = getStoreSettings(for: siteID)
        onCompletion(storeSettings.skippedCashOnDeliveryOnboardingStep)
    }

    func loadFirstInPersonPaymentsTransactionDate(siteID: Int64, using cardReaderType: CardReaderType, onCompletion: (Date?) -> Void) {
        let storeSettings = getStoreSettings(for: siteID)
        onCompletion(storeSettings.firstInPersonPaymentsTransactionsByReaderType[StorageCardReaderType(from: cardReaderType)])
    }

    func storeInPersonPaymentsTransactionIfFirst(siteID: Int64, using cardReaderType: CardReaderType) {
        let storeSettings = getStoreSettings(for: siteID)
        let updatedDictionary = storeSettings.firstInPersonPaymentsTransactionsByReaderType
            .merging([StorageCardReaderType(from: cardReaderType): Date()]) { (current, _) in
                // We never want to update stored value, because we keep the first transaction date for each site/reader pair.
                return current
            }

        guard updatedDictionary != storeSettings.firstInPersonPaymentsTransactionsByReaderType else {
            return
        }

        let updatedSettings = storeSettings.copy(firstInPersonPaymentsTransactionsByReaderType: updatedDictionary)
        setStoreSettings(settings: updatedSettings, for: siteID)
        NotificationCenter.default.post(name: .firstInPersonPaymentsTransactionsWereUpdated, object: nil)
    }
}

extension Notification.Name {
    public static let firstInPersonPaymentsTransactionsWereUpdated = Notification.Name(
        rawValue: "com.woocommerce.ios.firstInPersonPaymentsTransactionsWereUpdated")
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
        saveTrackingProvider(siteID: siteID,
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

    func saveTrackingProvider(siteID: Int64,
                                providerName: String,
                                providerURL: String? = nil,
                                preselectedData: [PreselectedProvider],
                                toFileURL: URL,
                                onCompletion: (Error?) -> Void) {
        let newPreselectedProvider = PreselectedProvider(siteID: siteID,
                                                         providerName: providerName,
                                                         providerURL: providerURL)
        let dataToSave = [newPreselectedProvider]

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
                              productFilter: FilterOrdersByProduct?,
                              customerFilter: CustomerFilter?,
                              onCompletion: (Error?) -> Void) {
        var existingSettings: [Int64: StoredOrderSettings.Setting] = [:]
        if let storedSettings: StoredOrderSettings = try? fileStorage.data(for: ordersSettingsURL) {
            existingSettings = storedSettings.settings
        }

        let newSettings = StoredOrderSettings.Setting(siteID: siteID,
                                                      orderStatusesFilter: orderStatusesFilter,
                                                      dateRangeFilter: dateRangeFilter,
                                                      productFilter: productFilter,
                                                      customerFilter: customerFilter)
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

    // Store unique identifier

    func setStoreID(siteID: Int64, id: String?) {
        let storeSettings = getStoreSettings(for: siteID)
        let updatedSettings = storeSettings.copy(storeID: id)
        setStoreSettings(settings: updatedSettings, for: siteID)
    }

    func getStoreID(siteID: Int64, onCompletion: (String?) -> Void) {
        let storeSettings = getStoreSettings(for: siteID)
        onCompletion(storeSettings.storeID)
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
}


// MARK: - Feature Announcement Card Visibility

extension AppSettingsStore {

    /// Dismisses a feature announcement campaign, optionally reminding the user after the specified number of days elapses,
    /// by marking the campaign as visible again.
    /// - Parameters:
    ///   - campaign: campaign to dismiss
    ///   - remindAfterDays: optionally remind the user after this many days. If nil is passed, the campaign is permanently dismissed
    ///   - onCompletion: completion handler
    func setFeatureAnnouncementDismissed(
        campaign: FeatureAnnouncementCampaign,
        remindAfterDays: Int?,
        onCompletion: ((Result<Bool, Error>) -> ())?) {
            do {
                let newSettings = FeatureAnnouncementCampaignSettings(dismissedDate: Date(), remindAfter: date(adding: remindAfterDays))

                let settings = generalAppSettings.settings
                let settingsToSave = settings.replacing(featureAnnouncementSettings: newSettings, for: campaign)
                try generalAppSettings.saveSettings(settingsToSave)

                onCompletion?(.success(true))
            } catch {
                onCompletion?(.failure(error))
            }
        }

    private func date(adding days: Int?) -> Date? {
        guard let days else {
            return nil
        }
        return NSCalendar.current.date(byAdding: .day, value: days, to: Date())
    }

    func getFeatureAnnouncementVisibility(campaign: FeatureAnnouncementCampaign, onCompletion: (Result<Bool, Error>) -> ()) {
        guard let campaignSettings = generalAppSettings.value(for: \.featureAnnouncementCampaignSettings)[campaign] else {
            return onCompletion(.success(true))
        }

        if let remindAfter = campaignSettings.remindAfter {
            let remindAfterHasPassed = remindAfter < Date()
            onCompletion(.success(remindAfterHasPassed))
        } else {
            let neverDismissed = campaignSettings.dismissedDate == nil
            onCompletion(.success(neverDismissed))
        }
    }

    func loadSiteHasAtLeastOneIPPTransactionFinished(siteID: Int64, onCompletion: (Bool) -> Void) {
        let storeSettings = getStoreSettings(for: siteID)
        let hasStoredTransactionsByReader = storeSettings.firstInPersonPaymentsTransactionsByReaderType.count > 0
        let hasLegacyIPPTransactionStored = generalAppSettings.value(for: \.sitesWithAtLeastOneIPPTransactionFinished).contains(siteID)
        onCompletion(hasStoredTransactionsByReader || hasLegacyIPPTransactionStored)
    }
}

private extension AppSettingsStore {
    func setLastSelectedStatsTimeRange(siteID: Int64, timeRange: StatsTimeRangeV4) {
        let storeSettings = getStoreSettings(for: siteID)
        let updatedSettings = storeSettings.copy(lastSelectedStatsTimeRange: timeRange.rawValue)
        setStoreSettings(settings: updatedSettings, for: siteID)
    }

    func loadLastSelectedStatsTimeRange(siteID: Int64, onCompletion: (StatsTimeRangeV4?) -> Void) {
        let storeSettings = getStoreSettings(for: siteID)
        let timeRangeRawValue = storeSettings.lastSelectedStatsTimeRange
        let timeRange = StatsTimeRangeV4(rawValue: timeRangeRawValue)
        onCompletion(timeRange)
    }
}

private extension AppSettingsStore {
    func setCustomStatsTimeRange(siteID: Int64, timeRange: StatsTimeRangeV4) {
        let storeSettings = getStoreSettings(for: siteID)
        let updatedSettings = storeSettings.copy(customStatsTimeRange: timeRange.rawValue)
        setStoreSettings(settings: updatedSettings, for: siteID)
    }

    func loadCustomStatsTimeRange(siteID: Int64, onCompletion: @escaping (StatsTimeRangeV4?) -> Void) {
        let storeSettings = getStoreSettings(for: siteID)
        let timeRangeRawValue = storeSettings.customStatsTimeRange
        let timeRange = StatsTimeRangeV4(rawValue: timeRangeRawValue)
        onCompletion(timeRange)
    }
}

// MARK: - Tax Rate

private extension AppSettingsStore {
    func setSelectedTaxRateID(with id: Int64?, siteID: Int64) {
        let storeSettings = getStoreSettings(for: siteID)

        let updatedSettings: GeneralStoreSettings
        if let taxRateID = id {
            updatedSettings = storeSettings.copy(selectedTaxRateID: taxRateID)
        } else {
            updatedSettings = storeSettings.erasingSelectedTaxRateID()
        }

        setStoreSettings(settings: updatedSettings, for: siteID)
    }

    func loadSelectedTaxRateID(with siteID: Int64, onCompletion: (Int64?) -> Void) {
        onCompletion(getStoreSettings(for: siteID).selectedTaxRateID)
    }
}

// MARK: - Analytics Hub Cards

private extension AppSettingsStore {
    func setAnalyticsHubCards(siteID: Int64, cards: [AnalyticsCard]) {
        let storeSettings = getStoreSettings(for: siteID)
        let updatedSettings = storeSettings.copy(analyticsHubCards: cards)
        setStoreSettings(settings: updatedSettings, for: siteID)
    }

    func loadAnalyticsHubCards(siteID: Int64, onCompletion: ([AnalyticsCard]?) -> Void) {
        onCompletion(getStoreSettings(for: siteID).analyticsHubCards)
    }
}

// MARK: - Dashboard Cards

private extension AppSettingsStore {
    func setDashboardCards(siteID: Int64, cards: [DashboardCard]) {
        let storeSettings = getStoreSettings(for: siteID)
        let updatedSettings = storeSettings.copy(dashboardCards: cards)
        setStoreSettings(settings: updatedSettings, for: siteID)
    }

    func loadDashboardCards(siteID: Int64, onCompletion: ([DashboardCard]?) -> Void) {
        onCompletion(getStoreSettings(for: siteID).dashboardCards)
    }

    func setLastSelectedPerformanceTimeRange(siteID: Int64, timeRange: StatsTimeRangeV4) {
        let storeSettings = getStoreSettings(for: siteID)
        let updatedSettings = storeSettings.copy(lastSelectedPerformanceTimeRange: timeRange.rawValue)
        setStoreSettings(settings: updatedSettings, for: siteID)
    }

    func loadLastSelectedPerformanceTimeRange(siteID: Int64, onCompletion: (StatsTimeRangeV4?) -> Void) {
        let storeSettings = getStoreSettings(for: siteID)
        let timeRangeRawValue = storeSettings.lastSelectedPerformanceTimeRange
        let timeRange = StatsTimeRangeV4(rawValue: timeRangeRawValue)
        onCompletion(timeRange)
    }

    func setLastSelectedTopPerformersTimeRange(siteID: Int64, timeRange: StatsTimeRangeV4) {
        let storeSettings = getStoreSettings(for: siteID)
        let updatedSettings = storeSettings.copy(lastSelectedTopPerformersTimeRange: timeRange.rawValue)
        setStoreSettings(settings: updatedSettings, for: siteID)
    }

    func loadLastSelectedTopPerformersTimeRange(siteID: Int64, onCompletion: (StatsTimeRangeV4?) -> Void) {
        let storeSettings = getStoreSettings(for: siteID)
        let timeRangeRawValue = storeSettings.lastSelectedTopPerformersTimeRange
        let timeRange = StatsTimeRangeV4(rawValue: timeRangeRawValue)
        onCompletion(timeRange)
    }

    func setLastSelectedMostActiveCouponsTimeRange(siteID: Int64, timeRange: StatsTimeRangeV4) {
        let storeSettings = getStoreSettings(for: siteID)
        let updatedSettings = storeSettings.copy(lastSelectedMostActiveCouponsTimeRange: timeRange.rawValue)
        setStoreSettings(settings: updatedSettings, for: siteID)
    }

    func loadLastSelectedMostActiveCouponsTimeRange(siteID: Int64, onCompletion: (StatsTimeRangeV4?) -> Void) {
        let storeSettings = getStoreSettings(for: siteID)
        let timeRangeRawValue = storeSettings.lastSelectedMostActiveCouponsTimeRange
        let timeRange = StatsTimeRangeV4(rawValue: timeRangeRawValue)
        onCompletion(timeRange)
    }

    func setLastSelectedStockType(siteID: Int64, type: String) {
        let storeSettings = getStoreSettings(for: siteID)
        let updatedSettings = storeSettings.copy(lastSelectedStockType: type)
        setStoreSettings(settings: updatedSettings, for: siteID)
    }

    func loadLastSelectedStockType(siteID: Int64, onCompletion: (String?) -> Void) {
        let storeSettings = getStoreSettings(for: siteID)
        let stockType = storeSettings.lastSelectedStockType
        onCompletion(stockType)
    }

    func setLastSelectedOrderStatus(siteID: Int64, status: String?) {
        let storeSettings = getStoreSettings(for: siteID)
        let updatedSettings = storeSettings.copy(lastSelectedOrderStatus: status)
        setStoreSettings(settings: updatedSettings, for: siteID)
    }

    func loadLastSelectedOrderStatus(siteID: Int64, onCompletion: (String?) -> Void) {
        let storeSettings = getStoreSettings(for: siteID)
        let orderStatus = storeSettings.lastSelectedOrderStatus
        onCompletion(orderStatus)
    }
}

// MARK: - Favorites Products
//
private extension AppSettingsStore {
    func setProductIDAsFavorite(productID: Int64, siteID: Int64) {
        let storeSettings = getStoreSettings(for: siteID)

        let updatedSettings: GeneralStoreSettings
        updatedSettings = storeSettings.copy(favoriteProductIDs: Array(Set(storeSettings.favoriteProductIDs + [productID])))

        setStoreSettings(settings: updatedSettings, for: siteID)
    }

    func removeProductIDAsFavorite(productID: Int64, siteID: Int64) {
        let storeSettings = getStoreSettings(for: siteID)
        var savedFavProductIDs = storeSettings.favoriteProductIDs

        guard let indexOfFavProductToBeRemoved = savedFavProductIDs.firstIndex(of: productID) else {
            return
        }
        savedFavProductIDs.remove(at: indexOfFavProductToBeRemoved)

        let updatedSettings: GeneralStoreSettings
        updatedSettings = storeSettings.copy(favoriteProductIDs: savedFavProductIDs)
        setStoreSettings(settings: updatedSettings, for: siteID)
    }

    func loadFavoriteProductIDs(for siteID: Int64, onCompletion: ([Int64]) -> Void) {
        onCompletion(getStoreSettings(for: siteID).favoriteProductIDs)
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
    static let generalStoreSettingsFileName = "general-store-settings.plist"
    static let ordersSettings = "orders-settings.plist"
    static let productsSettings = "products-settings.plist"
}
