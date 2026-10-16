import Foundation
import Observation
import UIKit
import Yosemite
import protocol WooFoundation.Analytics
import enum NetworkingCore.DotcomError
import enum NetworkingCore.NetworkError

@Observable
@MainActor
final class CustomerListErrorViewModel {
    enum Source: String {
        case customers
        case orderForm = "order_form"
        case orderListFilter = "order_list_filter"
    }

    enum Message: Equatable {
        case disabled
        case noPermission
        case unavailable
    }

    enum State: Equatable {
        case hidden
        case checking
        case shown(Message)
        case generic
    }

    private enum Recovery: String {
        case retry
        case enableAnalytics = "enable_analytics"
    }

    private enum Cause: String {
        case disabled
        case other
        case unknown
    }

    private let siteID: Int64
    private let source: Source
    private let reloadCustomers: () -> Void
    private let stores: StoresManager
    private let analytics: Analytics

    private(set) var state: State = .hidden
    var notice: Notice?

    @ObservationIgnored private var recovery: Recovery?
    @ObservationIgnored private var resultVersion = 0

    init(siteID: Int64,
         source: Source,
         reloadCustomers: @escaping () -> Void,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.source = source
        self.reloadCustomers = reloadCustomers
        self.stores = stores
        self.analytics = analytics
    }

    var isActive: Bool {
        state != .hidden
    }

    func customersDidFail(with error: Error) async -> Bool {
        let isEnableReload = recovery == .enableAnalytics
        recovery = nil
        resultVersion += 1
        let version = resultVersion

        guard isAnalyticsRouteMissing(error) else {
            // Once the Analytics error has shown, cached customers stay hidden until a load succeeds.
            guard isActive else {
                return false
            }
            state = .generic
            return true
        }

        state = .checking
        let result = await retrieveAnalyticsSetting()
        if case let .failure(error) = result {
            DDLogError("⛔️ Error retrieving Analytics setting: \(error)")
        }
        guard version == resultVersion else {
            return true
        }

        let message: Message
        let cause: Cause
        switch result {
        case .success(false):
            message = isEnableReload ? .unavailable : .disabled
            cause = .disabled
        case .success(true):
            message = .unavailable
            cause = .other
        case .failure(let error) where isAnalyticsSettingPermissionError(error):
            message = .noPermission
            cause = .unknown
        case .failure:
            message = .unavailable
            cause = .unknown
        }

        state = .shown(message)
        analytics.track(event: .CustomersHub.customerListAnalyticsUnavailableErrorShown(source: source.rawValue, cause: cause.rawValue))
        return true
    }

    func customersDidLoad() {
        resultVersion += 1
        if let recovery {
            analytics.track(event: .CustomersHub.customerListAnalyticsUnavailableReloadSuccess(source: source.rawValue, type: recovery.rawValue))
        }
        recovery = nil
        state = .hidden
        notice = nil
    }

    func retry() {
        // Retrying from the generic error isn't a recovery from the Analytics error.
        if case .shown = state {
            recovery = .retry
        }
        state = .checking
        notice = nil
        reloadCustomers()
    }

    func enableAnalytics() async {
        let previousState = state
        state = .checking
        notice = nil

        do {
            try await enableAnalyticsSetting()
        } catch {
            do {
                try await enableAnalyticsSetting()
            } catch {
                DDLogError("⛔️ Error enabling analytics: \(error)")
                state = previousState
                notice = Notice(message: Localization.enableAnalyticsFailure, feedbackType: .error)
                return
            }
        }

        recovery = .enableAnalytics
        reloadCustomers()
    }
}

private extension CustomerListErrorViewModel {
    func retrieveAnalyticsSetting() async -> Result<Bool, Error> {
        await withCheckedContinuation { continuation in
            stores.dispatch(SettingAction.retrieveAnalyticsSetting(siteID: siteID) { result in
                continuation.resume(returning: result)
            })
        }
    }

    func enableAnalyticsSetting() async throws {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(SettingAction.enableAnalyticsSetting(siteID: siteID) { result in
                continuation.resume(with: result)
            })
        }
    }

    func isAnalyticsRouteMissing(_ error: Error) -> Bool {
        if case .noRestRoute? = error as? DotcomError {
            return true
        }
        if let networkError = error as? NetworkError,
           case .notFound = networkError,
           networkError.errorCode == "rest_no_route" {
            return true
        }
        return false
    }

    func isAnalyticsSettingPermissionError(_ error: Error) -> Bool {
        if case let .unknown(code, _, _)? = error as? DotcomError {
            return code == "woocommerce_rest_cannot_view"
        }
        if let networkError = error as? NetworkError,
           case let .unacceptableStatusCode(statusCode, _) = networkError {
            return statusCode == 403 && networkError.errorCode == "woocommerce_rest_cannot_view"
        }
        return false
    }
}

#if DEBUG
extension CustomerListErrorViewModel {
    static func preview(state: State) -> CustomerListErrorViewModel {
        let viewModel = CustomerListErrorViewModel(siteID: 0, source: .customers, reloadCustomers: {})
        viewModel.state = state
        return viewModel
    }
}
#endif

private extension CustomerListErrorViewModel {
    enum Localization {
        static let enableAnalyticsFailure = NSLocalizedString(
            "customers.error.enableAnalyticsFailure",
            value: "WooCommerce Analytics couldn't be enabled. Please try again.",
            comment: "Notice shown when the app can't enable WooCommerce Analytics from the Customers error state")
    }
}
