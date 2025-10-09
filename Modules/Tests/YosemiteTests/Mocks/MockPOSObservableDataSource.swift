import Foundation
import Observation
import Yosemite

/// Mock implementation for testing and development
@Observable
public final class MockPOSObservableDataSource: POSObservableDataSourceProtocol {
    public private(set) var productItems: [POSItem] = []
    public private(set) var variationItems: [POSItem] = []
    public private(set) var isLoadingProducts: Bool = false
    public private(set) var isLoadingVariations: Bool = false
    public private(set) var hasMoreProducts: Bool = false
    public private(set) var hasMoreVariations: Bool = false
    public private(set) var error: Error? = nil

    public init() {}

    public func loadProducts() {
        isLoadingProducts = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)
            self.productItems = []
            self.isLoadingProducts = false
        }
    }

    public func loadMoreProducts() {
        guard !isLoadingProducts else { return }
        isLoadingProducts = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)
            self.isLoadingProducts = false
        }
    }

    public func loadVariations(for parentProduct: POSVariableParentProduct) {
        isLoadingVariations = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)
            self.variationItems = []
            self.isLoadingVariations = false
        }
    }

    public func loadMoreVariations() {
        guard !isLoadingVariations else { return }
        isLoadingVariations = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)
            self.isLoadingVariations = false
        }
    }

    public func refresh() {
        // No-op for mock
    }
}
