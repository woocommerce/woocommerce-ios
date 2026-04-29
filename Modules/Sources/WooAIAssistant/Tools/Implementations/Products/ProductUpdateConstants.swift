/// Allowed `status` values for `products_update` and `products_bulk_update`.
/// `trash` is excluded: trashing a product is destructive and outside the
/// v1 write-tool scope; deletion-style mutations require a different path.
enum AllowedProductUpdateStatuses {
    static let values: Set<String> = ["draft", "pending", "private", "publish"]
}
