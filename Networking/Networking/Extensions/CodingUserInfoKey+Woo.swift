import Foundation


/// WooCommerce CodingUserInfoKey(s)
///
extension CodingUserInfoKey {

    /// Used to store the SiteID within a Coder/Decoder's userInfo dictionary.
    ///
    public static let siteID = CodingUserInfoKey(rawValue: "siteID")!

    /// Used to store the SettingGroupKey within a Coder/Decoder's userInfo dictionary.
    ///
    public static let settingGroupKey = CodingUserInfoKey(rawValue: "settingGroupKey")!

    /// Used to store the OrderID within a Coder/Decoder's userInfo dictionary.
    ///
    public static let orderID = CodingUserInfoKey(rawValue: "orderID")!

    /// Used to store the ProductID within a Coder/Decoder's userInfo dictionary.
    ///
    public static let productID = CodingUserInfoKey(rawValue: "productID")!

    /// Used to store the UserID within a Coder/Decoder's userInfo dictionary.
    ///
    public static let userID = CodingUserInfoKey(rawValue: "userID")!

    /// Used to store the Granularity within a Coder/Decoder's userInfo dictionary.
    ///
    public static let granularity = CodingUserInfoKey(rawValue: "granularity")!

    /// Used to store the WordPress org username  within a Coder/Decoder's userInfo dictionary.
    ///
    public static let wpOrgUsername = CodingUserInfoKey(rawValue: "wpOrgUsername")!
}
