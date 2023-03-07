import Foundation

/// Helpers for working with versions (e.g. comparing two version strings)
///
final class VersionHelpers {
    /// Compares two strings as versions using the same approach as PHP `version_compare`.
    /// https://www.php.net/manual/en/function.version-compare.php
    ///
    static func isVersionSupported(version: String, minimumRequired: String) -> Bool {
        VersionHelpers.compare(version, minimumRequired) != .orderedAscending
    }

    /// Compares two strings as versions using the same approach as PHP `version_compare`.
    /// https://www.php.net/manual/en/function.version-compare.php
    ///
    /// Returns `orderedAscending` if the lhs version is older than the rhs
    /// Returns `orderedSame` if the lhs version is the same as the rhs
    /// Returns `orderedDescending` if the lhs version is newer than the rhs
    ///
    static func compare(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let leftComponents = versionComponents(of: lhs)
        let rightComponents = versionComponents(of: rhs)
        let maxComponents = max(leftComponents.count, rightComponents.count)

        for index in 0..<maxComponents {
            /// Treat missing components (e.g. 1.2 being compared to 1.1.3 as "0", i.e. 1.2.0)
            let leftComponent = index < leftComponents.count ? leftComponents[index] : "0"
            let rightComponent = index < rightComponents.count ? rightComponents[index] : "0"

            let comparisonResult = compareStringComponents(leftComponent, rightComponent)
            if comparisonResult != .orderedSame {
                return comparisonResult
            }
        }

        return .orderedSame
    }
}

// MARK: - Private Helpers
//
private extension VersionHelpers {
    /// Replace _ - and + with a .
    ///
    static func replaceUnderscoreDashAndPlusWithDot(_ string: String) -> String {
        string.replacingOccurrences(of: "([_\\-+]+)", with: ".", options: .regularExpression)
    }

    /// Insert a . before and after any non number
    ///
    static func insertDotsBeforeAndAfterAnyNonNumber(_ string: String) -> String {
        string.replacingOccurrences(of: "([^0-9.]+)", with: ".$1.", options: .regularExpression)
    }

    /// Score and compare two string components
    ///
    static func compareStringComponents(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let lhsScore = VersionComponentScore(from: lhs)
        let rhsScore = VersionComponentScore(from: rhs)

        if lhsScore < rhsScore {
            return .orderedAscending
        }

        if lhsScore > rhsScore {
            return .orderedDescending
        }

        if lhsScore == .number && rhsScore == .number {
            let lhsAsNumber = NSNumber(value: Int(lhs) ?? 0)
            let rhsAsNumber = NSNumber(value: Int(rhs) ?? 0)

            let comparisonResult = lhsAsNumber.compare(rhsAsNumber)
            if comparisonResult != .orderedSame {
                return comparisonResult
            }
        }

        return .orderedSame
    }

    /// Process the given string into version components
    ///
    static func versionComponents(of string: String) -> [String] {
        var stringToComponentize = replaceUnderscoreDashAndPlusWithDot(string)
        stringToComponentize = insertDotsBeforeAndAfterAnyNonNumber(stringToComponentize)
        return stringToComponentize.components(separatedBy: ".")
    }
}

/// Defines the score (rank) of a component string within a version string.
/// e.g. the "3" in 3.0.0beta3 should be treated as `.number`
/// and the "beta" should be scored (ranked) lower as `.beta`.
///
/// The scores of components of version strings are used when comparing complete version strings
/// to decide if one version is older, equal or newer than another.
///
/// Ranked per https://www.php.net/manual/en/function.version-compare.php
///
private enum VersionComponentScore: Comparable {
    case other
    case dev
    case alpha
    case beta
    case RC
    case number
    case patch
}

private extension VersionComponentScore {
    init(from: String) {
        if from == "dev" {
            self = .dev
            return
        }
        if from == "alpha" || from == "a" {
            self = .alpha
            return
        }
        if from == "beta" || from == "b" {
            self = .beta
            return
        }
        if from == "RC" || from == "rc" {
            self = .RC
            return
        }
        let componentCharacterSet = CharacterSet(charactersIn: from)
        if componentCharacterSet.isSubset(of: .decimalDigits) {
            self = .number
            return
        }

        if from == "pl" || from == "p" {
            self = .patch
            return
        }

        self = .other
    }
}
