extension Product {
    /// Whether shipping settings are available for the product.
    public var isShippingEnabled: Bool {
        return downloadable == false && virtual == false
    }
}
