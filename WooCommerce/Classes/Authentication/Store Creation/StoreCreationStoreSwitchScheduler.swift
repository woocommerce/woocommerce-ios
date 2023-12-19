import Foundation
import Yosemite
import Combine

protocol StoreCreationStoreSwitchScheduler {
    func savePendingStoreSwitch(siteID: Int64, expectedStoreName: String)

    func removePendingStoreSwitch()

    var isPendingStoreSwitch: Bool { get }

    func listenToPendingStoreAndReturnSiteIDOnceReady() async throws -> Int64?
}

/// Stores store creation info and informs once the store is ready
///
final class DefaultStoreCreationStoreSwitchScheduler: StoreCreationStoreSwitchScheduler {
    private let stores: StoresManager
    private let userDefaults: UserDefaults
    private let jetpackCheckRetryInterval: TimeInterval
    private var storeStatusChecker: StoreCreationStatusChecker?
    private var jetpackSiteSubscription: AnyCancellable?

    private var siteIDPendingStoreSwitch: Int64? {
        set {
            userDefaults[.siteIDPendingStoreSwitch] = newValue
        }
        get {
            userDefaults[.siteIDPendingStoreSwitch] as? Int64
        }
    }

    private var expectedStoreNamePendingStoreSwitch: String? {
        set {
            userDefaults[.expectedStoreNamePendingStoreSwitch] = newValue
        }
        get {
            userDefaults[.expectedStoreNamePendingStoreSwitch] as? String
        }
    }

    init(stores: StoresManager = ServiceLocator.stores,
         userDefaults: UserDefaults = .standard,
         jetpackCheckRetryInterval: TimeInterval = 15) {
        self.stores = stores
        self.userDefaults = userDefaults
        self.jetpackCheckRetryInterval = jetpackCheckRetryInterval
    }

    func savePendingStoreSwitch(siteID: Int64, expectedStoreName: String) {
        siteIDPendingStoreSwitch = siteID
        expectedStoreNamePendingStoreSwitch = expectedStoreName
    }

    func removePendingStoreSwitch() {
        siteIDPendingStoreSwitch = nil
        expectedStoreNamePendingStoreSwitch = nil
    }

    var isPendingStoreSwitch: Bool {
        guard siteIDPendingStoreSwitch != stores.sessionManager.defaultStoreID else {
            removePendingStoreSwitch()
            return false
        }

        return siteIDPendingStoreSwitch != nil && expectedStoreNamePendingStoreSwitch != nil
    }

    @MainActor
    func listenToPendingStoreAndReturnSiteIDOnceReady() async throws -> Int64? {
        guard let siteID = userDefaults[.siteIDPendingStoreSwitch] as? Int64,
              let expectedStoreName = userDefaults[.expectedStoreNamePendingStoreSwitch] as? String else {
            return nil
        }

        let statusChecker = StoreCreationStatusChecker(jetpackCheckRetryInterval: jetpackCheckRetryInterval,
                                                       storeName: expectedStoreName,
                                                       stores: stores)
        self.storeStatusChecker = statusChecker
        let site: Site = try await withCheckedThrowingContinuation { continuation in
            jetpackSiteSubscription = statusChecker.waitForSiteToBeReady(siteID: siteID)
            // Retries 15 times with some seconds pause in between to wait for the newly created site to be available as a Jetpack/Woo site.
                .retry(15)
                .sink (receiveCompletion: { completion in
                    guard case .failure = completion else {
                        return
                    }
                    continuation.resume(throwing: StoreCreationStoreSwitchSchedulerError.storeNotReady)
                }, receiveValue: { site in
                    continuation.resume(returning: site)
                })
        }
        return site.siteID
    }
}

enum StoreCreationStoreSwitchSchedulerError: Error {
    case storeNotReady
}
