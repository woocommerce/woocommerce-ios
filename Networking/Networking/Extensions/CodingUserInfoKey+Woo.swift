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

    /// Used to store the SiteID within a Coder/Decoder's userInfo dictionary.
    ///
    public static let orderID = CodingUserInfoKey(rawValue: "orderID")!
}
