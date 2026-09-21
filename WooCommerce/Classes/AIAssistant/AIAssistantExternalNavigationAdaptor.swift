import Foundation
import SwiftUI
import UIKit
import Yosemite
import CocoaLumberjackSwift
import WooAIAssistant

@MainActor
struct AIAssistantExternalNavigationAdaptor: AssistantExternalNavigationProviding {

    private let boundSiteID: Int64
    private let navigationHost: AIAssistantNavigationHost
    private let stores: StoresManager
    private let timeZone: TimeZone

    init(siteID: Int64,
         navigationHost: AIAssistantNavigationHost,
         stores: StoresManager = ServiceLocator.stores,
         timeZone: TimeZone = .siteTimezone) {
        self.boundSiteID = siteID
        self.navigationHost = navigationHost
        self.stores = stores
        self.timeZone = timeZone
    }

    // MARK: - Orders

    func openOrder(orderID: Int64) {
        let loader = OrderLoaderViewController(orderID: orderID, siteID: boundSiteID)
        push(loader)
    }

    func openOrder(orderID: Int64, payload: AnyCodableJSON) {
        if let order = decode(Order.self, from: payload) {
            let viewModel = OrderDetailsViewModel(order: order)
            let detail = OrderDetailsViewController(viewModel: viewModel)
            push(detail)
            return
        }
        openOrder(orderID: orderID)
    }

    // MARK: - Products

    func openProduct(productID: Int64) {
        pushLoadingThen(
            fetch: { await fetchProduct(productID: productID) },
            detail: { ProductDetailNavigator.shared.makeDestination(product: $0, isReadOnly: false) }
        )
    }

    func openProduct(productID: Int64, payload: AnyCodableJSON) {
        if let product = decode(Product.self, from: payload) {
            pushProductDetail(for: product)
            return
        }
        openProduct(productID: productID)
    }

    func openProductVariation(productID: Int64, variationID: Int64) {
        pushLoadingThen(
            fetch: { () -> UIViewController? in
                async let parent = fetchProduct(productID: productID)
                async let variation = fetchProductVariation(productID: productID, variationID: variationID)
                guard let parent = await parent, let variation = await variation else { return nil }
                return await withCheckedContinuation { continuation in
                    ProductVariationDetailsFactory.productVariationDetails(productVariation: variation,
                                                                           parentProduct: parent,
                                                                           presentationStyle: .navigationStack,
                                                                           forceReadOnly: false) { viewController in
                        continuation.resume(returning: viewController)
                    }
                }
            },
            detail: { $0 }
        )
    }

    private func pushProductDetail(for product: Product) {
        let detail = ProductDetailNavigator.shared.makeDestination(product: product, isReadOnly: false)
        push(detail)
    }

    // MARK: - Customers

    func openCustomer(customerID: Int64) {
        pushLoadingThen(
            fetch: { await fetchCustomer(customerID: customerID) },
            detail: { customer in
                let viewModel = makeCustomerDetailViewModel(for: customer)
                return UIHostingController(rootView: CustomerDetailView(viewModel: viewModel))
            }
        )
    }

    func openCustomer(customerID: Int64, payload: AnyCodableJSON) {
        if let customer = decode(Customer.self, from: payload) {
            pushCustomerDetail(for: customer)
            return
        }
        openCustomer(customerID: customerID)
    }

    private func pushCustomerDetail(for customer: Customer) {
        let viewModel = makeCustomerDetailViewModel(for: customer)
        let hosting = UIHostingController(rootView: CustomerDetailView(viewModel: viewModel))
        push(hosting)
    }

    private func makeCustomerDetailViewModel(for customer: Customer) -> CustomerDetailViewModel {
        let displayName: String = {
            let combined = [customer.firstName, customer.lastName]
                .compactMap { $0?.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            if !combined.isEmpty { return combined }
            if let username = customer.username, !username.isEmpty { return username }
            return customer.email
        }()
        return CustomerDetailViewModel(
            siteID: customer.siteID,
            customerID: customer.customerID,
            name: displayName,
            dateLastActive: nil,
            email: nullifyBlank(customer.email),
            ordersCount: "-",
            totalSpend: "-",
            avgOrderValue: "-",
            username: nullifyBlank(customer.username),
            dateRegistered: nil,
            country: nullifyBlank(customer.billing?.country),
            region: nullifyBlank(customer.billing?.state),
            city: nullifyBlank(customer.billing?.city),
            postcode: nullifyBlank(customer.billing?.postcode)
        )
    }

    private func nullifyBlank(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespaces),
              !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    // MARK: - Analytics

    func openAnalyticsHub(payload: AnyCodableJSON) {
        let analyticsHubVC = AnalyticsHubHostingViewController(
            siteID: boundSiteID,
            timeZone: timeZone,
            timeRange: timeRange(fromAnalyticsPayload: payload),
            usageTracksEventEmitter: StoreStatsUsageTracksEventEmitter()
        )
        push(analyticsHubVC)
    }

    // The analytics screen interprets the range in the site timezone, so parse the
    // YYYY-MM-DD strings in that same timezone to avoid an off-by-one shift in
    // negative-UTC stores (e.g. May 4 displayed as May 3 in America/Los_Angeles).
    func timeRange(fromAnalyticsPayload payload: AnyCodableJSON) -> StatsTimeRangeV4 {
        let formatter = makeISODateFormatter()
        guard let after = payload.assistantString("after"),
              let before = payload.assistantString("before"),
              let from = formatter.date(from: after),
              let to = formatter.date(from: before) else {
            return .today
        }
        return .custom(from: from, to: to)
    }

    private func makeISODateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    // MARK: - Helpers

    private func push(_ viewController: UIViewController) {
        guard let nav = navigationHost.navigationController else { return }
        nav.pushViewController(viewController, animated: true)
    }

    // Pushes a placeholder, swaps it once `fetch` resolves. Identity lookup no-ops if the user popped.
    private func pushLoadingThen<Value>(
        fetch: @escaping () async -> Value?,
        detail: @escaping (Value) -> UIViewController
    ) {
        let placeholder = AIAssistantLoadingPlaceholderViewController()
        push(placeholder)
        Task { @MainActor in
            guard let value = await fetch() else { return }
            guard let nav = navigationHost.navigationController else { return }
            var stack = nav.viewControllers
            guard let index = stack.firstIndex(where: { $0 === placeholder }) else { return }
            stack[index] = detail(value)
            nav.setViewControllers(stack, animated: false)
        }
    }

    // Networking model inits read siteID from decoder.userInfo, not the REST response.
    private func decode<T: Decodable>(_ type: T.Type, from payload: AnyCodableJSON) -> T? {
        do {
            let data = try JSONEncoder().encode(payload)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
            decoder.userInfo[.siteID] = boundSiteID
            return try decoder.decode(type, from: data)
        } catch {
            DDLogDebug("AIAssistantExternalNavigationAdaptor: \(type) cache miss \(error)")
            return nil
        }
    }

    private func fetchProduct(productID: Int64) async -> Product? {
        await withCheckedContinuation { continuation in
            let action = ProductAction.retrieveProduct(siteID: boundSiteID, productID: productID) { result in
                switch result {
                case .success(let product):
                    continuation.resume(returning: product)
                case .failure(let error):
                    DDLogError("AIAssistantExternalNavigationAdaptor failed to fetch product: \(error)")
                    continuation.resume(returning: nil)
                }
            }
            stores.dispatch(action)
        }
    }

    private func fetchProductVariation(productID: Int64, variationID: Int64) async -> ProductVariation? {
        await withCheckedContinuation { continuation in
            let action = ProductVariationAction.retrieveProductVariation(siteID: boundSiteID,
                                                                          productID: productID,
                                                                          variationID: variationID) { result in
                switch result {
                case .success(let variation):
                    continuation.resume(returning: variation)
                case .failure(let error):
                    DDLogError("AIAssistantExternalNavigationAdaptor failed to fetch variation: \(error)")
                    continuation.resume(returning: nil)
                }
            }
            stores.dispatch(action)
        }
    }

    private func fetchCustomer(customerID: Int64) async -> Customer? {
        await withCheckedContinuation { continuation in
            let action = CustomerAction.retrieveCustomer(siteID: boundSiteID, customerID: customerID) { result in
                switch result {
                case .success(let value):
                    continuation.resume(returning: value)
                case .failure(let error):
                    DDLogError("AIAssistantExternalNavigationAdaptor failed to fetch customer: \(error)")
                    continuation.resume(returning: nil)
                }
            }
            stores.dispatch(action)
        }
    }
}
