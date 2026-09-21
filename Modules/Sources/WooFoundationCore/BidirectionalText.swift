import Foundation

/// Utilities for formatting bidirectional text in money-related UI.
public enum BidirectionalText {
    public static let leftToRightMark = "\u{200E}"
    public static let rightToLeftMark = "\u{200F}"
    public static let leftToRightIsolate = "\u{2066}"
    public static let rightToLeftIsolate = "\u{2067}"
    public static let popDirectionalIsolate = "\u{2069}"

    public static let defaultNumericSeparators: Set<Character> = [
        ".",
        ",",
        "-",
        "\u{2212}",
        "\u{066B}",
        "\u{066C}"
    ]

    public static func containsStrongRightToLeftCharacter(in text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            switch scalar.value {
            case 0x0590...0x08FF, 0xFB1D...0xFDFF, 0xFE70...0xFEFF:
                return true
            default:
                return false
            }
        }
    }

    public static func isolateLeftToRight(_ text: String) -> String {
        leftToRightIsolate + text + popDirectionalIsolate
    }

    public static func numericSeparators(including separators: [String]) -> Set<Character> {
        separators.reduce(into: defaultNumericSeparators) { partialResult, separator in
            partialResult.formUnion(separator)
        }
    }

    public static func isolateLeftToRightNumericRuns(in text: String,
                                                     separators: Set<Character> = defaultNumericSeparators) -> String {
        guard containsDirectionalControl(in: text) == false else {
            return text
        }

        var result = ""
        var currentRun = ""
        let characters = Array(text)

        for (index, character) in characters.enumerated() {
            if character.isNumber || shouldTreatAsNumericSeparator(character, at: index, in: characters, separators: separators) {
                currentRun.append(character)
            } else {
                result.appendLeftToRightIsolatedRunIfNeeded(currentRun)
                currentRun = ""
                result.append(character)
            }
        }

        result.appendLeftToRightIsolatedRunIfNeeded(currentRun)
        return result
    }
}

private extension BidirectionalText {
    static func containsDirectionalControl(in text: String) -> Bool {
        text.contains { directionalControls.contains($0) }
    }

    static var directionalControls: Set<Character> {
        [
            Character(leftToRightMark),
            Character(rightToLeftMark),
            Character(leftToRightIsolate),
            Character(rightToLeftIsolate),
            Character(popDirectionalIsolate)
        ]
    }

    static func shouldTreatAsNumericSeparator(_ character: Character,
                                              at index: Int,
                                              in characters: [Character],
                                              separators: Set<Character>) -> Bool {
        guard separators.contains(character) else {
            return false
        }

        let previousCharacterIsNumber = index > 0 && characters[index - 1].isNumber
        let nextCharacterIsNumber = index < characters.count - 1 && characters[index + 1].isNumber

        return previousCharacterIsNumber || nextCharacterIsNumber
    }
}

private extension String {
    mutating func appendLeftToRightIsolatedRunIfNeeded(_ run: String) {
        guard run.isNotEmpty else {
            return
        }

        append(BidirectionalText.isolateLeftToRight(run))
    }
}
