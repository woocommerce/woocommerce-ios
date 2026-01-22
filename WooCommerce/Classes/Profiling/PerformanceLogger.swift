import Foundation
import os.log
import os.signpost

/// Centralized performance logging and profiling infrastructure using os_signpost
/// for detailed performance analysis in Instruments.
final class PerformanceLogger {

    // MARK: - Singleton
    static let shared = PerformanceLogger()

    // MARK: - OSLog Configuration
    private let perfLog: OSLog
    private let subsystemIdentifier = "com.automattic.woocommerce"

    // MARK: - Signpost Categories
    enum SignpostCategory: String {
        // Product Catalog Performance
        case catalogLoad = "CatalogLoad"
        case catalogScroll = "CatalogScroll"
        case catalogFilter = "CatalogFilter"

        // Product Detail Performance
        case productDetailLoad = "ProductDetailLoad"
        case productDetailGallery = "ProductDetailGallery"

        // Cart & Checkout Performance
        case addToCart = "AddToCart"
        case cartUpdate = "CartUpdate"
        case checkoutStart = "CheckoutStart"
        case checkoutComplete = "CheckoutComplete"

        // Image Loading & Caching
        case imageDecode = "ImageDecode"
        case imageCacheHit = "ImageCacheHit"
        case imageCacheMiss = "ImageCacheMiss"

        // Network & API
        case apiRequest = "APIRequest"
        case apiResponse = "APIResponse"

        // App Lifecycle / Launch
        case coldStart = "ColdStart"
        case warmStart = "WarmStart"

        // Miscellaneous
        case backgroundProcessing = "BackgroundProcessing"
        case databaseQuery = "DatabaseQuery"

        // Custom
        case custom1 = "Custom1"
        case custom2 = "Custom2"
        case custom3 = "Custom3"
    }

    // MARK: - Init
    private init() {
        self.perfLog = OSLog(subsystem: subsystemIdentifier, category: "Performance")
    }

    // MARK: - Public API

    /// Creates a unique signpost ID for an interval.
    func makeSignpostID() -> OSSignpostID {
        if #available(iOS 12.0, *) {
            return OSSignpostID(log: perfLog)
        } else {
            return .invalid
        }
    }

    /// Begins a signposted interval for a specific category.
    func begin(_ category: SignpostCategory,
               id: OSSignpostID,
               _ message: StaticString = "") {
        guard #available(iOS 12.0, *), id != .invalid else { return }
        os_signpost(.begin, log: perfLog, name: category.osSignpostName, signpostID: id, message)
    }

    /// Ends a signposted interval for a specific category.
    func end(_ category: SignpostCategory,
             id: OSSignpostID,
             _ message: StaticString = "") {
        guard #available(iOS 12.0, *), id != .invalid else { return }
        os_signpost(.end, log: perfLog, name: category.osSignpostName, signpostID: id, message)
    }

    /// Logs a single-point event for a specific category.
    func event(_ category: SignpostCategory,
               _ message: StaticString = "") {
        guard #available(iOS 12.0, *) else { return }
        os_signpost(.event, log: perfLog, name: category.osSignpostName, message)
    }

    /// Measures the execution time of a synchronous block.
    @discardableResult
    func measure<T>(_ category: SignpostCategory, block: () throws -> T) rethrows -> T {
        let id = makeSignpostID()
        begin(category, id: id)
        defer { end(category, id: id) }
        return try block()
    }

    /// Measures the execution time of an async block.
    @discardableResult
    func measureAsync<T>(_ category: SignpostCategory, block: () async throws -> T) async rethrows -> T {
        let id = makeSignpostID()
        begin(category, id: id)
        defer { end(category, id: id) }
        return try await block()
    }
}

// MARK: - Helper

private extension PerformanceLogger.SignpostCategory {
    var osSignpostName: StaticString {
        switch self {
        case .catalogLoad:            return "CatalogLoad"
        case .catalogScroll:          return "CatalogScroll"
        case .catalogFilter:          return "CatalogFilter"
        case .productDetailLoad:      return "ProductDetailLoad"
        case .productDetailGallery:   return "ProductDetailGallery"
        case .addToCart:              return "AddToCart"
        case .cartUpdate:             return "CartUpdate"
        case .checkoutStart:          return "CheckoutStart"
        case .checkoutComplete:       return "CheckoutComplete"
        case .imageDecode:            return "ImageDecode"
        case .imageCacheHit:          return "ImageCacheHit"
        case .imageCacheMiss:         return "ImageCacheMiss"
        case .apiRequest:             return "APIRequest"
        case .apiResponse:            return "APIResponse"
        case .coldStart:              return "ColdStart"
        case .warmStart:              return "WarmStart"
        case .backgroundProcessing:   return "BackgroundProcessing"
        case .databaseQuery:          return "DatabaseQuery"
        case .custom1:                return "Custom1"
        case .custom2:                return "Custom2"
        case .custom3:                return "Custom3"
        }
    }
}

