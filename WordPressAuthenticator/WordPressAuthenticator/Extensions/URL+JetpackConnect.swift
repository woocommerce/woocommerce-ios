import Foundation

extension URL {
    public func isJetpackConnect() -> Bool {
        query?.contains("&source=jetpack") ?? false
    }
}
