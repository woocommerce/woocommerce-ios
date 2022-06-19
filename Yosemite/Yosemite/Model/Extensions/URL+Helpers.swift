//
//  URL+Helpers.swift
//  Yosemite
//
/// Convenient extension methods for URL
import Foundation

extension URL {
    static public func getWooCommerceAdminURL(from storesManager: StoresManager) -> URL {
        let wooCommerceFallbackURL = URL(string: "https://woocommerce.com/blog/")
        guard let defaultSite = storesManager.sessionManager.defaultSite else {
            return wooCommerceFallbackURL!
        }
        guard let url = URL(string: defaultSite.adminURL) else {
            if defaultSite.url.isEmpty {
                return wooCommerceFallbackURL!
            } else {
                let adminURLFromSiteURLString = defaultSite.url + "/wp-admin"
                return URL(string: adminURLFromSiteURLString)!
            }
        }
        return url
    }
}
