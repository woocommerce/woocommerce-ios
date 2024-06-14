import Foundation
import CocoaLumberjack
import Experiments
import Storage
import Yosemite
import Hardware
import WooFoundation
import WordPressShared

/// Provides global dependencies.
///
final class ServiceLocator {

    // MARK: - Private properties

    /// WooAnalytics Wrapper
    ///
    private static var _analytics: Analytics = WooAnalytics(analyticsProvider: TracksProvider())

    /// StoresManager
    ///
    private static var _stores: StoresManager = DefaultStoresManager(sessionManager: SessionManager.standard)

    /// WordPressAuthenticator Wrapper
    ///
    private static var _authenticationManager: Authentication = AuthenticationManager()

    /// FeatureFlagService
    ///
    private static var _featureFlagService: FeatureFlagService = DefaultFeatureFlagService()

    /// ImageService
    ///
    private static var _imageService: ImageService = DefaultImageService()

    /// In-App Notifications Presenter
    ///
    private static var _noticePresenter: NoticePresenter = DefaultNoticePresenter()

    /// Product image uploader
    ///
    private static var _productImageUploader: ProductImageUploaderProtocol = ProductImageUploader()

    /// Push Notifications Manager
    ///
    private static var _pushNotesManager: PushNotesManager = PushNotificationsManager()

    /// Shipping Settings
    ///
    private static var _shippingSettingsService: ShippingSettingsService?

    /// Selected Site Settings
    ///
    private static var _selectedSiteSettings: SelectedSiteSettings = SelectedSiteSettings()

    /// Currency Settings
    ///
    private static var _currencySettings: CurrencySettings = CurrencySettings()

    /// CoreData Stack
    ///
    private static var _storageManager = CoreDataManager(name: WooConstants.databaseStackName, crashLogger: crashLogging)

    /// Cocoalumberjack DDLog
    ///
    private static var _fileLogger: Logs = DDFileLogger()

    /// Crash Logging Stack
    ///
    private static var _crashLogging: CrashLoggingStack = WooCrashLoggingStack(
        featureFlagService: featureFlagService
    )

    /// Support for external Card Readers
    ///
    #if !targetEnvironment(macCatalyst)
    private static var _cardReader: CardReaderService = StripeCardReaderService()
    #else
    private static var _cardReader: CardReaderService = NoOpCardReaderService()
    #endif

    private static var _cardReaderConfigProvider: CommonReaderConfigProviding = CommonReaderConfigProvider()

    /// Support for printing receipts
    ///
    private static var _receiptPrinter: PrinterService = AirPrintReceiptPrinterService()

    /// Observer for network connectivity
    ///
    private static var _connectivityObserver: ConnectivityObserver = DefaultConnectivityObserver()

    /// Store WPCom plan synchronizer.
    ///
    private static var _storePlanSynchronizer: StorePlanSynchronizing = StorePlanSynchronizer()

    /// Storage for general app settings
    ///
    private static var _generalAppSettings: GeneralAppSettingsStorage = GeneralAppSettingsStorage()

    private static var _cardPresentPaymentsOnboardingIPPUsersRefresher: CardPresentPaymentsOnboardingIPPUsersRefresher =
    CardPresentPaymentsOnboardingIPPUsersRefresher()

    private static var _tapToPayReconnectionController = TapToPayReconnectionController<BuiltInReaderConnectionAlertsProvider, CardPresentPaymentAlertsPresenter>(
            connectionControllerFactory: BuiltInCardReaderConnectionControllerFactory(
                alertProvider: BuiltInReaderConnectionAlertsProvider()))

    /// Tracker for app startup waiting time
    ///
    private static var _startupWaitingTimeTracker: AppStartupWaitingTimeTracker = AppStartupWaitingTimeTracker()

    // MARK: - Getters

    /// Provides the access point to the analytics.
    /// - Returns: An implementation of the Analytics protocol. It defaults to WooAnalytics
    static var analytics: Analytics {
        return _analytics
    }

    /// Provides the access point to the feature flag service.
    /// - Returns: An implementation of the FeatureFlagService protocol. It defaults to DefaultFeatureFlagService
    static var featureFlagService: FeatureFlagService {
        return _featureFlagService
    }

    /// Provides the access point to the image service.
    /// - Returns: An implementation of the ImageService protocol. It defaults to DefaultImageService
    static var imageService: ImageService {
        return _imageService
    }

    /// Provides the access point to the stores.
    /// - Returns: An implementation of the StoresManager protocol. It defaults to DefaultStoresManager
    static var stores: StoresManager {
        return _stores
    }

    /// Provides the access point to the NoticePresenter.
    /// - Returns: An implementation of the NoticePresenter protocol. It defaults to DefaultNoticePresenter
    static var noticePresenter: NoticePresenter {
        return _noticePresenter
    }

    /// Provides the access point to the ProductImageUploaderProtocol.
    /// - Returns: An implementation of the ProductImageUploaderProtocol. It defaults to ProductImageUploader
    static var productImageUploader: ProductImageUploaderProtocol {
        return _productImageUploader
    }

    /// Provides the access point to the PushNotesManager.
    /// - Returns: An implementation of the PushNotesManager protocol. It defaults to PushNotificationsManager
    static var pushNotesManager: PushNotesManager {
        return _pushNotesManager
    }

    /// Provides the access point to the AuthenticationManager.
    /// - Returns: An implementation of the AuthenticationManager protocol. It defaults to DefaultAuthenticationManager
    static var authenticationManager: Authentication {
        return _authenticationManager
    }

    /// Shipping Settings
    ///
    static var shippingSettingsService: ShippingSettingsService {
        guard let shippingSettingsService = _shippingSettingsService else {
            let siteID = stores.sessionManager.defaultStoreID ?? Int64.min
            let service = StorageShippingSettingsService(siteID: siteID,
                                                         storageManager: storageManager)
            _shippingSettingsService = service
            return service
        }
        return shippingSettingsService
    }

    /// Provides the access point to the Site Settings for the current Site.
    /// - Returns: An instance of SelectedSiteSettings.
    static var selectedSiteSettings: SelectedSiteSettings {
        return _selectedSiteSettings
    }

    /// Provides the access point to the Currency Settings for the current Site.
    /// - Returns: An instance of CurrencySettings.
    static var currencySettings: CurrencySettings {
        return _currencySettings
    }

    /// Provides the access point to the StorageManager.
    /// - Returns: An instance of CoreDataManager. Notice how we break the pattern we
    /// use in all other properties provided by the ServiceLocator. Mocked implementations
    /// of the CoreDataManager should be subclasses
    static var storageManager: CoreDataManager {
        return _storageManager
    }

    /// Provides the access point to the FileLogger.
    /// - Returns: An implementation of the Logs protocol. It defaults to DDFileLogger
    static var fileLogger: Logs {
        return _fileLogger
    }

    /// Provides an instance of `WordPressLoggingDelegate` for logging in WordPress libraries.
    static let wordPressLibraryLogger: WordPressLoggingDelegate = WordPressLibraryLogger()

    /// Provides the access point to the CrashLogger
    /// - Returns: An implementation
    static var crashLogging: CrashLoggingStack {
        return _crashLogging
    }

    /// Provides the last known `KeyboardState`.
    ///
    /// Because `static let` is lazy, this should be accessed when the app is started
    /// (i.e. AppDelegate) for it to accurately provide the last known state.
    ///
    static let keyboardStateProvider: KeyboardStateProviding = KeyboardStateProvider()

    /// The main object to use for presenting SMS (`MessageUI`) ViewControllers.
    ///
    static let messageComposerPresenter = MessageComposerPresenter()


    /// Provides the access point to the CardReaderService.
    /// - Returns: An implementation of the CardReaderService protocol.
    static var cardReaderService: CardReaderService {
        _cardReader
    }

    static var cardReaderConfigProvider: CommonReaderConfigProviding {
        _cardReaderConfigProvider
    }

    /// Provides the access point to the ReceiptPrinterService.
    /// - Returns: An implementation of the ReceiptPrinterService protocol.
    static var receiptPrinterService: PrinterService {
        _receiptPrinter
    }

    /// Provides access point to the ConnectivityObserver.
    /// - Returns: An implementation of the ConnectivityObserver protocol.
    static var connectivityObserver: ConnectivityObserver {
        _connectivityObserver
    }

    /// Provides access point to the `StorePlanSynchronizer`.
    ///
    static var storePlanSynchronizer: StorePlanSynchronizing {
        _storePlanSynchronizer
    }

    /// Provides access point to GeneralAppSettingsStorage
    /// - Returns: An instance of GeneralAppSetingsStorage
    static var generalAppSettings: GeneralAppSettingsStorage {
        _generalAppSettings
    }

    static var cardPresentPaymentsOnboardingIPPUsersRefresher: CardPresentPaymentsOnboardingIPPUsersRefresher {
        _cardPresentPaymentsOnboardingIPPUsersRefresher
    }

    static var tapToPayReconnectionController: TapToPayReconnectionController<BuiltInReaderConnectionAlertsProvider,
                                                                                CardPresentPaymentAlertsPresenter> {
        _tapToPayReconnectionController
    }

    /// Provides access point to the `AppStartupWaitingTimeTracker`.
    ///
    static var startupWaitingTimeTracker: AppStartupWaitingTimeTracker {
        _startupWaitingTimeTracker
    }
}


// MARK: - Testability

/// The setters declared in this extension are meant to be used only from the test bundle
extension ServiceLocator {
    static func setAnalytics(_ mock: Analytics) {
        guard isRunningTests() else {
            return
        }

        _analytics = mock
    }

    static func setFeatureFlagService(_ mock: FeatureFlagService) {
        guard isRunningTests() else {
            return
        }

        _featureFlagService = mock
    }

    static func setStores(_ mock: StoresManager) {
        guard isRunningTests() || ProcessConfiguration.shouldUseScreenshotsNetworkLayer else {
            return
        }

        _stores = mock
    }

    static func setNoticePresenter(_ mock: NoticePresenter) {
        guard isRunningTests() else {
            return
        }

        _noticePresenter = mock
    }

    static func setPushNotesManager(_ mock: PushNotesManager) {
        guard isRunningTests() else {
            return
        }

        _pushNotesManager = mock
    }

    static func setAuthenticationManager(_ mock: Authentication) {
        guard isRunningTests() else {
            return
        }

        _authenticationManager = mock
    }

    static func setShippingSettingsService(_ mock: ShippingSettingsService) {
        guard isRunningTests() else {
            return
        }

        _shippingSettingsService = mock
    }

    static func setSelectedSiteSettings(_ mock: SelectedSiteSettings) {
        guard isRunningTests() else {
            return
        }

        _selectedSiteSettings = mock
    }

    static func setCurrencySettings(_ mock: CurrencySettings) {
        guard isRunningTests() else {
            return
        }

        _currencySettings = mock
    }

    static func setStorageManager(_ mock: CoreDataManager) {
        guard isRunningTests() else {
            return
        }

        _storageManager = mock
    }

    static func setFileLogger(_ mock: Logs) {
        guard isRunningTests() else {
            return
        }

        _fileLogger = mock
    }

    static func setCrashLogging(_ mock: CrashLoggingStack) {
        guard isRunningTests() else {
            return
        }

        _crashLogging = mock
    }

    static func setCardReader(_ mock: CardReaderService) {
        guard isRunningTests() else {
            return
        }
        #if !targetEnvironment(macCatalyst)
        _cardReader = mock
        #endif
    }

    static func setCardReaderConfigProvider(_ mock: CommonReaderConfigProviding) {
        guard isRunningTests() else {
            return
        }

        _cardReaderConfigProvider = mock
    }

    static func setReceiptPrinter(_ mock: PrinterService) {
        guard isRunningTests() else {
            return
        }

        _receiptPrinter = mock
    }

    static func setConnectivityObserver(_ mock: ConnectivityObserver) {
        guard isRunningTests() else {
            return
        }

        _connectivityObserver = mock
    }

    static func setGeneralAppSettingsStorage(_ mock: GeneralAppSettingsStorage) {
        guard isRunningTests() else {
            return
        }

        _generalAppSettings = mock
    }

    static func setProductImageUploader(_ mock: ProductImageUploaderProtocol) {
        guard isRunningTests() else {
            return
        }

        _productImageUploader = mock
    }
}


private extension ServiceLocator {
    static func isRunningTests() -> Bool {
        return NSClassFromString("XCTestCase") != nil
    }
}
