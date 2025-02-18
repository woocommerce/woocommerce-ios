import Foundation

/// Save product image upload statuses in User Defaults.
/// This class is declared in the Networking layer because it will also be accessed by the background URLSession operations.
///
final class ProductImagesUserDefaultsStatuses {
    private static let key = "savedProductUploadImageStatuses"

    static func addStatus(_ status: ProductImageStatus) {
        var statuses = getAllStatuses()
        statuses.append(status)
        saveAllStatuses(statuses)
    }

    static func removeStatus(_ status: ProductImageStatus) {
        var statuses = getAllStatuses()
        statuses.removeAll(where: { $0 == status })
        saveAllStatuses(statuses)
    }

    static func findStatus(where predicate: (ProductImageStatus) -> Bool) -> ProductImageStatus? {
        return getAllStatuses().first(where: predicate)
    }

    static func getAllStatuses() -> [ProductImageStatus] {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return []
        }
        do {
            let statuses = try JSONDecoder().decode([ProductImageStatus].self, from: data)
            return statuses
        } catch {
            DDLogError("Error decoding saved product image statuses: \(error)")
            return []
        }
    }

    static func getAllStatuses(for siteID: Int64, productID: ProductOrVariationID?) -> [ProductImageStatus] {
        return getAllStatuses().filter { status in
            switch status {
            case .remote(_, let sID, let pID):
                if let filterProductID = productID {
                    return sID == siteID && pID == filterProductID
                } else {
                    return false
                }
            case .uploading(_, let sID, let pID),
                 .uploadFailure(_, _, let sID, let pID):
                if let filterProductID = productID {
                    return sID == siteID && pID == filterProductID
                } else {
                    return sID == siteID && pID == nil
                }
            }
        }
    }

    static func clearAllStatuses() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    private static func saveAllStatuses(_ statuses: [ProductImageStatus]) {
        do {
            let data = try JSONEncoder().encode(statuses)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            DDLogError("Error encoding saved product image statuses: \(error)")
        }
    }
}

extension ProductImagesUserDefaultsStatuses {
    static func setAllStatuses(_ statuses: [ProductImageStatus]) {
        saveAllStatuses(statuses)
    }

    static func setAllStatuses(_ statuses: [ProductImageStatus], for siteID: Int64, productID: ProductOrVariationID?) {
        // Merge with existing, removing any old statuses for this site/product
        var all = getAllStatuses().filter { st in
            switch st {
            case .remote(_, let sID, let pID):
                if let filterProductID = productID {
                    return !(sID == siteID && pID == filterProductID)
                } else {
                    return true
                }
            case .uploading(_, let sID, let pID),
                 .uploadFailure(_, _, let sID, let pID):
                if let filterProductID = productID {
                    return !(sID == siteID && pID == filterProductID)
                } else {
                    return !(sID == siteID && pID == nil)
                }
            }
        }
        all.append(contentsOf: statuses)
        saveAllStatuses(all)
    }
}
