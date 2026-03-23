/// Provides the set of product types available for creation on the current site.
///
/// Standard sites offer the full set (variable, grouped, subscriptions, etc.);
/// CIAB sites offer only simple and affiliate products.
///
protocol CreatableProductTypeProviding {
    var creatableProductTypes: [BottomSheetProductType] { get }
}
