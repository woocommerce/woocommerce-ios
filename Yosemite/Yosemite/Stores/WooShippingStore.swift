import Foundation
import Networking
import Storage

/// Implements `WooShippingAction` actions
///
public final class WooShippingStore: Store {
    private let remote: WooShippingRemoteProtocol

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = WooShippingRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network, remote: WooShippingRemoteProtocol) {
        self.remote = remote
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Registers for supported Actions.
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: WooShippingAction.self)
    }

    /// Receives and executes Actions.
    override public func onAction(_ action: Action) {
        guard let action = action as? WooShippingAction else {
            assertionFailure("WooShippingStore received an unsupported action")
            return
        }

        switch action {
        case .createPackage(let siteID, let customPackage, let predefinedOption, let completion):
            createPackage(siteID: siteID, customPackage: customPackage, predefinedOption: predefinedOption, completion: completion)
        case .deletePackage(let siteID, let packageID, let completion):
            deletePackage(siteID: siteID, packageID: packageID, completion: completion)
        case .loadLabelRates(let siteID, let orderID, let originAddress, let destinationAddress, let packages, let completion):
            loadLabelRates(siteID: siteID,
                           orderID: orderID,
                           originAddress: originAddress,
                           destinationAddress: destinationAddress,
                           packages: packages,
                           completion: completion)
        case .loadPackages(let siteID, completion: let completion):
            loadPackages(siteID: siteID, completion: completion)
        case .loadAccountSettings(let siteID, completion: let completion):
            loadAccountSettings(siteID: siteID, completion: completion)
        case let .purchaseShippingLabel(siteID,
                                        orderID,
                                        originAddress,
                                        destinationAddress,
                                        package,
                                        backendProcessingDelay,
                                        pollingDelay,
                                        pollingMaximumRetries,
                                        completion):
            purchaseShippingLabel(siteID: siteID,
                                  orderID: orderID,
                                  originAddress: originAddress,
                                  destinationAddress: destinationAddress,
                                  package: package,
                                  backendProcessingDelay: backendProcessingDelay,
                                  pollingDelay: pollingDelay,
                                  pollingMaximumRetries: pollingMaximumRetries,
                                  completion: completion)
        case let .printLabel(siteID, labelIDs, paperSize, completion):
            printLabel(siteID: siteID, labelIDs: labelIDs, paperSize: paperSize, completion: completion)
        }
    }
}

private extension WooShippingStore {
    func createPackage(siteID: Int64,
                       customPackage: WooShippingCustomPackage? = nil,
                       predefinedOption: WooShippingPredefinedSavedOption? = nil,
                       completion: @escaping (Result<WooShippingCreatePackageResponse, PackageCreationError>) -> Void) {
        remote.createPackage(siteID: siteID, customPackage: customPackage, predefinedOption: predefinedOption) { result in
            switch result {
            case .success(let packages):
                completion(.success(packages))
            case .failure(let error):
                completion(.failure(PackageCreationError(error: error)))
            }
        }
    }

    func deletePackage(siteID: Int64,
                       packageID: String,
                       completion: @escaping (Result<WooShippingCreatePackageResponse, Error>) -> Void) {
        remote.deletePackage(siteID: siteID, packageID: packageID) { result in
            switch result {
            case .success(let packages):
                completion(.success(packages))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func loadLabelRates(siteID: Int64,
                        orderID: Int64,
                        originAddress: ShippingLabelAddress,
                        destinationAddress: ShippingLabelAddress,
                        packages: [ShippingLabelPackageSelected],
                        completion: @escaping (Result<[ShippingLabelCarriersAndRates], Error>) -> Void) {
        remote.loadLabelRates(siteID: siteID,
                              orderID: orderID,
                              originAddress: originAddress,
                              destinationAddress: destinationAddress,
                              packages: packages,
                              completion: completion)
    }

    func loadPackages(siteID: Int64,
                      completion: @escaping (Result<WooShippingPackagesResponse, Error>) -> Void) {
        remote.loadPackages(siteID: siteID, completion: completion)
    }

    func loadAccountSettings(siteID: Int64,
                             completion: @escaping (Result<WooShippingAccountSettings, Error>) -> Void) {
        remote.loadAccountSettings(siteID: siteID, completion: completion)
    }

    func purchaseShippingLabel(siteID: Int64,
                               orderID: Int64,
                               originAddress: ShippingLabelAddress,
                               destinationAddress: ShippingLabelAddress,
                               package: WooShippingPackagePurchase,
                               backendProcessingDelay: TimeInterval,
                               pollingDelay: TimeInterval,
                               pollingMaximumRetries: Int64,
                               completion: @escaping (Result<ShippingLabel, Error>) -> Void) {
        // Make the initial purchase request.
        remote.purchaseShippingLabel(siteID: siteID,
                                     orderID: orderID,
                                     originAddress: originAddress,
                                     destinationAddress: destinationAddress,
                                     package: package) { result in
            switch result {
            case .success(let labelPurchases):
                // Purchase endpoint returns an array of labels, but the polling endpoint only takes a single label at a time.
                // Since we only expect to purchase one label at a time, we get the first label from the response.
                guard let labelID = labelPurchases.first?.shippingLabelID else {
                    DDLogError("⛔️ No labels in Woo Shipping label purchase response")
                    return completion(.failure(WooShippingLabelPurchaseError.purchaseMissingLabels))
                }

                // Wait to give the backend time to process the purchase
                DispatchQueue.main.asyncAfter(deadline: .now() + backendProcessingDelay) { [weak self] in
                    guard let self else { return }

                    // Poll the status of the label purchase from the response above
                    pollLabelStatus(withDelayInSeconds: pollingDelay,
                                    maxErrorRetries: pollingMaximumRetries,
                                    siteID: siteID,
                                    orderID: orderID,
                                    labelID: labelID,
                                    completion: completion)
                }
            case .failure(let error):
                DDLogError("⛔️ Error purchasing shipping label for order \(orderID): \(error)")
                completion(.failure(error))
            }
        }
    }

    func printLabel(siteID: Int64,
                    labelIDs: [Int64],
                    paperSize: ShippingLabelPaperSize,
                    completion: @escaping (Result<ShippingLabelPrintData, Error>) -> Void) {
        remote.printLabel(siteID: siteID, labelIDs: labelIDs, paperSize: paperSize, completion: completion)
    }
}

// MARK: Helpers
private extension WooShippingStore {
    /// Polls the status of the purchase for the provided label ID,
    /// with a delay of 1 second each time, and a maximum of 3 retries for failed requests.
    func pollLabelStatus(withDelayInSeconds delay: Double,
                         maxErrorRetries: Int64,
                         siteID: Int64,
                         orderID: Int64,
                         labelID: Int64,
                         completion: @escaping (Result<ShippingLabel, Error>) -> Void) {
        remote.checkLabelStatus(siteID: siteID, orderID: orderID, labelID: labelID) { [weak self] result in
            switch result {
            case .success(let labelStatusResponse):
                // If label has PURCHASED status, stop polling
                if labelStatusResponse.status == .purchased,
                   let label = labelStatusResponse.getPurchasedLabel() {
                    completion(.success(label))
                }

                // If label has PURCHASE_ERROR status, return error and stop polling
                else if labelStatusResponse.status == .purchaseError {
                    DDLogError("⛔️ Error purchasing shipping label for order \(orderID)")
                    completion(.failure(WooShippingLabelPurchaseError.purchaseErrorStatus))
                }

                // If no error but status is not PURCHASED, poll again after delay
                else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                        self?.pollLabelStatus(withDelayInSeconds: delay,
                                              maxErrorRetries: maxErrorRetries,
                                              siteID: siteID,
                                              orderID: orderID,
                                              labelID: labelID,
                                              completion: completion)
                    }
                }

            case .failure(let error):
                // If there are retries left, poll again after delay
                if maxErrorRetries > 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                        self?.pollLabelStatus(withDelayInSeconds: delay,
                                              maxErrorRetries: maxErrorRetries - 1,
                                              siteID: siteID,
                                              orderID: orderID,
                                              labelID: labelID,
                                              completion: completion)
                    }
                }

                // If there are no retries left, stop polling
                else {
                    DDLogError("⛔️ Error checking shipping label status for order \(orderID): \(error)")
                    completion(.failure(error))
                }
            }
        }
    }
}

/// Represents errors that can be returned when purchasing a shipping label
public enum WooShippingLabelPurchaseError: Error {
    /// API returns a `PURCHASE_ERROR` status for a label
    case purchaseErrorStatus
    /// No labels are returned by initial purchase request
    case purchaseMissingLabels
}
