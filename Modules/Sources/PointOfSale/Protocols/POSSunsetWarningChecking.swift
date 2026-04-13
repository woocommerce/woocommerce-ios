import Foundation

/// Determines whether the POS sunset warning banner should be shown
/// and records when the user dismisses it.
///
public protocol POSSunsetWarningChecking {
    func shouldShowSunsetWarning(siteID: Int64) async -> Bool
    func recordDismissal(siteID: Int64)
}
