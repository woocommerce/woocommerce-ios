import Foundation

extension HTTPCookieStorage {
    func removeCookies(forHostOf url: URL) {
        guard let siteHost = url.host?.lowercased() else { return }
        cookies?.forEach { cookie in
            let cookieDomain = cookie.domain
                .trimmingCharacters(in: CharacterSet(charactersIn: "."))
                .lowercased()
            if siteHost == cookieDomain || siteHost.hasSuffix(".\(cookieDomain)") {
                deleteCookie(cookie)
            }
        }
    }
}
