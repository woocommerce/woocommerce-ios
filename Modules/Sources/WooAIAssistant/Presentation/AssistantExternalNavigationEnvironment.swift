import SwiftUI
import CocoaLumberjackSwift

private struct NoOpAssistantExternalNavigation: AssistantExternalNavigationProviding {
    func openOrder(orderID: Int64) {
        DDLogInfo("AssistantCard openOrder ignored (no navigation provider): order \(orderID)")
    }

    func openProduct(productID: Int64) {
        DDLogInfo("AssistantCard openProduct ignored (no navigation provider): product \(productID)")
    }

    func openProductVariation(productID: Int64, variationID: Int64) {
        DDLogInfo("AssistantCard openProductVariation ignored (no navigation provider): product \(productID), variation \(variationID)")
    }

    func openCustomer(customerID: Int64) {
        DDLogInfo("AssistantCard openCustomer ignored (no navigation provider): customer \(customerID)")
    }

    func openAnalyticsHub(payload: AnyCodableJSON) {
        DDLogInfo("AssistantCard openAnalyticsHub ignored (no navigation provider)")
    }
}

private struct AssistantExternalNavigationKey: EnvironmentKey {
    @MainActor
    static let defaultValue: AssistantExternalNavigationProviding = NoOpAssistantExternalNavigation()
}

public extension EnvironmentValues {
    var assistantExternalNavigation: AssistantExternalNavigationProviding {
        get { self[AssistantExternalNavigationKey.self] }
        set { self[AssistantExternalNavigationKey.self] = newValue }
    }
}

private struct EmptyAssistantExternalViews: AssistantExternalViewProviding {}

private struct AssistantExternalViewsKey: EnvironmentKey {
    static let defaultValue: AssistantExternalViewProviding = EmptyAssistantExternalViews()
}

public extension EnvironmentValues {
    var assistantExternalViews: AssistantExternalViewProviding {
        get { self[AssistantExternalViewsKey.self] }
        set { self[AssistantExternalViewsKey.self] = newValue }
    }
}
