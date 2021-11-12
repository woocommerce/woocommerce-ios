import Foundation


/// String: Helper Methods
///
extension String {

    /// Helper method to provide the singular or plural (formatted) version of a
    /// string based on a count.
    ///
    /// - Parameters:
    ///   - count: Number of 'things' in the string
    ///   - singular: Singular version of localized string — used if `count` is 1
    ///   - plural: Plural version of localized string — used if `count` is greater than 1
    /// - Returns: Singular or plural version of string based on `count` param
    ///
    /// NOTE: String params _must_ include `%ld` placeholder (count will be placed there).
    ///
    static func pluralize(_ count: Int, singular: String, plural: String) -> String {
        if count == 1 {
            return String.localizedStringWithFormat(singular, count)
        } else {
            return String.localizedStringWithFormat(plural, count)
        }
    }

    /// Helper method to provide the singular or plural (formatted) version of a
    /// string based on a count.
    ///
    /// - Parameters:
    ///   - count: Number of 'things' in the string
    ///   - singular: Singular version of localized string — used if `count` is 1
    ///   - plural: Plural version of localized string — used if `count` is greater than 1
    /// - Returns: Singular or plural version of string based on `count` param
    ///
    /// NOTE: String params _must_ include `%@` placeholder (count will be placed there).
    ///
    static func pluralize(_ count: Decimal, singular: String, plural: String) -> String {
        let stringCount = NSDecimalNumber(decimal: count).stringValue

        if count > 0 && count < 1 || count == 1 {
            return String.localizedStringWithFormat(singular, stringCount)
        } else {
            return String.localizedStringWithFormat(plural, stringCount)
        }
    }

    /// Helper method to remove the last newline character in a given string.
    ///
    /// - Parameters:
    ///   - string: the string to format
    /// - Returns: a string with the newline character removed, if the
    ///            newline character is the last character in the string.
    ///
    static func stripLastNewline(in string: String) -> String {
        var newText = string
        let lastChar = newText.suffix(1)

        let newline = String(lastChar)
        if newline == "\n" {
            newText.removeSuffix(newline)
        }

        return newText
    }

    /// A Boolean value indicating whether a string has characters.
    var isNotEmpty: Bool {
        return !isEmpty
    }

    /// Compares two strings as versions.
    ///
    /// Returns `orderedAscending` if the argument represents a newer version
    /// Returns `orderedSame` if the argument represents the same version
    /// Returns `orderedDescending` if the argument represents an older version
    ///
    func compareAsVersion(to: String) -> ComparisonResult {

        /// Replace _ - and + with a .
        ///
        func replaceUnderscoreDashAndPlusWithDot(inString: String) -> String {
            var outString = inString
            let replaceTargets = ["_", "-", "+"]
            for replaceTarget in replaceTargets {
                outString = outString.replacingOccurrences(of: replaceTarget, with: ".")
            }
            return outString
        }

        /// Insert a . before and after any non number
        ///
        func insertDotsBeforeAndAfterAnyNonNumber(inString: String) -> String {
            guard inString.count > 1 else {
                return inString
            }

            /// Initialize our output with the first character of the input string
            var outString = String(inString[inString.index(inString.startIndex, offsetBy: 0)])

            /// Loop over the remaining characters in the string, inserting . as needed
            for index in 1...inString.count - 1 {
                let characterAtIndex = inString[inString.index(inString.startIndex, offsetBy: index)]
                let characterBefore = inString[inString.index(inString.startIndex, offsetBy: index - 1)]

                let characterAtIndexIsNumberOrDot = characterAtIndex.isNumber || characterAtIndex == "."
                let characterBeforeIsNumberOrDot = characterBefore.isNumber || characterBefore == "."

                if !characterAtIndexIsNumberOrDot && characterBefore.isNumber {
                    outString += "."
                }

                if characterAtIndex.isNumber && !characterBeforeIsNumberOrDot {
                    outString += "."
                }

                outString += String(characterAtIndex)
            }

            return outString
        }

        /// Score and compare two string components
        ///
        func compareStringComponents(_ lhs: String, _ rhs: String) -> ComparisonResult {
            /// Score each component
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
        func versionComponents(of string: String) -> [String] {
            var stringToComponentize = replaceUnderscoreDashAndPlusWithDot(inString: string)
            stringToComponentize = insertDotsBeforeAndAfterAnyNonNumber(inString: stringToComponentize)
            return stringToComponentize.components(separatedBy: ".")
        }

        let leftComponents = versionComponents(of: self)
        let rightComponents = versionComponents(of: to)

        let maxComponents = max(leftComponents.count, rightComponents.count)

        for index in 0..<maxComponents {
            /// Treat missing components (e.g. 1.2 being compared to 1.1.3 as "0", i.e. 1.2.0
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

/// Defines the score (rank) of a component string within a version string.
/// e.g. the "3" in 3.0.0beta3 should be treated as `.number`
/// and the "beta" should be scored (ranked) lower as `.beta`.
///
/// The scores of components of version strings are used when comparing complete version strings
/// to decide if one version is older, equal or newer than another.
///
/// Ranked per https://www.php.net/manual/en/function.version-compare.php
///
fileprivate enum VersionComponentScore: Comparable {
    case other
    case dev
    case alpha
    case beta
    case RC
    case number
    case patch
}

extension VersionComponentScore {
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
