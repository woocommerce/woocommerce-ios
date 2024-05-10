import Foundation
import protocol Yosemite.StoresManager
import protocol WooFoundation.Analytics

public class PointOfSaleDependencies {
    let siteID: Int64
    let analytics: Analytics
    let stores: StoresManager

    public init(siteID: Int64,
                analytics: Analytics,
                stores: StoresManager) {
        self.siteID = siteID
        self.analytics = analytics
        self.stores = stores
    }
}
