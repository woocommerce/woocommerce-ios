import Foundation
import Storage

extension Storage.OrderAttributionInfo: ReadOnlyConvertible {

    /// Updates the Storage.OrderAttributionInfo with the ReadOnly.
    ///
    public func update(with attributionInfo: Yosemite.OrderAttributionInfo) {
        sourceType = attributionInfo.sourceType
        campaign = attributionInfo.campaign
        source = attributionInfo.source
        medium = attributionInfo.medium
        deviceType = attributionInfo.deviceType
        sessionPageViews = attributionInfo.sessionPageViews
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.OrderAttributionInfo {
        OrderAttributionInfo(sourceType: sourceType,
                             campaign: campaign,
                             source: source,
                             medium: medium,
                             deviceType: deviceType,
                             sessionPageViews: sessionPageViews)
    }
}
