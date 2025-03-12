import Foundation
import Combine

/// Save product image upload statuses in User Defaults.
/// This class is declared in the Networking layer because it will also be accessed by the background URLSession operations.
/// This class avoid KVO, and uses Combine to handle notifications, and efficiently checks for actual data changes.
/// We're not using KVO, because `ProductImageStatus` use a swift type (enum), not compatible with Obj-C.
///
public final class ProductImageStatusStorage {
    private let key: String
    private let userDefaults: UserDefaults

    // Private internal instance for static methods
    private static let internalInstance = ProductImageStatusStorage()

    // Publisher for observing changes
    private let statusesSubject: CurrentValueSubject<[ProductImageStatus], Never>
    private var cancellables = Set<AnyCancellable>()

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public var statusesPublisher: AnyPublisher<[ProductImageStatus], Never> {
        statusesSubject
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    public var errorsPublisher: AnyPublisher<[(siteID: Int64,
                                               productOrVariationID: ProductOrVariationID?,
                                               assetType: ProductImageAssetType?,
                                               error: Error)], Never> {
        statusesSubject
            .map { statuses in
                statuses.compactMap { status in
                    if status.isUploadFailure, let error = status.error {
                        return (siteID: status.siteID,
                                productOrVariationID: status.productOrVariationID,
                                assetType: status.asset,
                                error: error)
                    } else {
                        return nil
                    }
                }
            }
            .eraseToAnyPublisher()
    }

    public init(userDefaults: UserDefaults = .standard,
                key: String = "savedProductUploadImageStatuses",
                encoder: JSONEncoder = JSONEncoder(),
                decoder: JSONDecoder = JSONDecoder()) {
        self.key = key
        self.userDefaults = userDefaults
        self.encoder = encoder
        self.decoder = decoder
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder.dateDecodingStrategy = .iso8601
        self.statusesSubject = CurrentValueSubject(Self.loadStatuses(from: userDefaults, key: key, decoder: decoder))
        setupObservers()
    }

    public func addStatus(_ status: ProductImageStatus) {
        var current = statusesSubject.value
        current.append(status)
        saveStatuses(current)
    }

    public func removeStatus(_ status: ProductImageStatus) {
        let current = statusesSubject.value.filter { $0 != status }
        saveStatuses(current)
    }

    public func removeStatus(where predicate: (ProductImageStatus) -> Bool) {
        let current = statusesSubject.value.filter { !predicate($0) }
        saveStatuses(current)
    }

    public func updateStatus(_ status: ProductImageStatus) {
        var current = statusesSubject.value
        if let index = current.firstIndex(where: { $0 == status }) {
            current[index] = status
            saveStatuses(current)
        } else {
            addStatus(status)
        }
    }

    public func findStatus(where predicate: (ProductImageStatus) -> Bool) -> ProductImageStatus? {
        statusesSubject.value.first(where: predicate)
    }

    public func getAllStatuses() -> [ProductImageStatus] {
        statusesSubject.value
    }

    public func getAllStatuses(for siteID: Int64, productID: ProductOrVariationID?) -> [ProductImageStatus] {
        statusesSubject.value.filter {
            switch $0 {
            case .uploading(_, let sID, let pID),
                    .uploadFailure(_, _, let sID, let pID):
                return sID == siteID && (productID == nil || pID == productID)
            case .remote(_, let sID, let pID):
                return sID == siteID && pID == productID
            }
        }
    }

    public func clearAllStatuses() {
        userDefaults.removeObject(forKey: key)
        userDefaults.synchronize()
        statusesSubject.send([])
    }

    public func setAllStatuses(_ statuses: [ProductImageStatus]) {
        saveStatuses(statuses)
    }

    public func appendStatuses(_ statuses: [ProductImageStatus], for siteID: Int64, productID: ProductOrVariationID?) {
        var filtered = statusesSubject.value.filter {
            switch $0 {
            case .uploading(_, let sID, let pID),
                    .uploadFailure(_, _, let sID, let pID):
                return sID != siteID || (productID != nil && pID != productID)
            case .remote(_, let sID, let pID):
                return sID != siteID || pID != productID
            }
        }
        filtered.append(contentsOf: statuses)
        saveStatuses(filtered)
    }

    private func saveStatuses(_ statuses: [ProductImageStatus]) {
        do {
            let data = try encoder.encode(statuses)
            userDefaults.set(data, forKey: key)
            userDefaults.synchronize()
            statusesSubject.send(statuses)
        } catch {
            print("Encoding error in ProductImageStatusStorage: \(error)")
        }
    }

    private static func loadStatuses(from userDefaults: UserDefaults, key: String, decoder: JSONDecoder = JSONDecoder()) -> [ProductImageStatus] {
        guard let data = userDefaults.data(forKey: key) else { return [] }
        do {
            return try decoder.decode([ProductImageStatus].self, from: data)
        } catch {
            print("Decoding error in ProductImageStatusStorage: \(error)")
            return []
        }
    }
}

// Private utility methods to observe changes in UserDefaults
private extension ProductImageStatusStorage {
    func setupObservers() {
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification, object: userDefaults)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.checkForExternalUpdates()
            }
            .store(in: &cancellables)
    }

    func checkForExternalUpdates() {
        let newStatuses = Self.loadStatuses(from: userDefaults, key: key, decoder: decoder)

        // Deep comparison
        let hasChanges = !newStatuses.elementsEqual(statusesSubject.value) { lhs, rhs in
                    switch (lhs, rhs) {
                    case (.remote(let lImg, let lSite, let lProd), .remote(let rImg, let rSite, let rProd)):
                        return lImg == rImg && lSite == rSite && lProd == rProd
                    default:
                        return lhs == rhs
                    }
                }

                if hasChanges {
                    statusesSubject.send(newStatuses)
                }
    }
}
