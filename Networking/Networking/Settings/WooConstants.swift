import Foundation

/// Constants to be shared in Networking layer.
///
public enum WooConstants {
    /// Placeholder site ID to be used when the user is logged in without WPCom.
    public static let placeholderSiteID: Int64 = -1

    /// Keychain Access's Service Name
    ///
    public static let keychainServiceName = "com.automattic.woocommerce"

    /// Slug of the free plan
    static let freePlanSlug = "free_plan"

    /// Slug of the free trial WooExpress plan
    static let freeTrialPlanSlug = "ecommerce-trial-bundle-monthly"
}
