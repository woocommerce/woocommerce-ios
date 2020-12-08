import Foundation

/// Describes a text that could be bolded or not.
struct BoldableElement: Equatable {
    let content: String
    let isBold: Bool
}

/// Parses boldable text for further text concatenation with bold attributes.
struct BoldableTextParser {
    private let boldTextPattern = "\\*{2}(.*?)\\*{2}"

    /// Parses the input text and returns a collection of `BoldableElement`.
    ///
    /// - Returns: A collection of boldable elements.
    func parseBoldableElements(string: String) -> [BoldableElement] {
        guard let regex = try? NSRegularExpression(pattern: boldTextPattern) else {
            return []
        }
        let range = NSRange(string.startIndex..., in: string)

        /// Finds all the ranges that match the regex for content within a bold region.
        let matches: [NSTextCheckingResult] = regex.matches(in: string, options: [], range: range)

        guard matches.isNotEmpty else {
            return [.init(content: string, isBold: false)]
        }

        var elements: [BoldableElement] = []

        var startingIndex = 0
        matches.enumerated().forEach { index, match in
            // Each `NSTextCheckingResult` has two ranges: the first one (index 0) is the range that includes the bold marks (**..**).
            // The second one (index 1) is the range that excludes the bold marks, which corresponds to the bolded substring.
            guard match.numberOfRanges == 2 else {
                return
            }

            let matchingRange = match.range(at: 0)
            let boldedContentRange = match.range(at: 1)

            // Adds an element for the range from the last index and before the matching range, if non-empty.
            let rangeBefore = startingIndex..<matchingRange.lowerBound
            if rangeBefore.isEmpty == false {
                let content = string[rangeBefore]
                elements.append(.init(content: content, isBold: false))
            }

            // Adds an element for the matching range which should be bold.
            let matchContent = string[boldedContentRange.lowerBound..<boldedContentRange.upperBound]
            elements.append(.init(content: matchContent, isBold: true))

            // Updates the last starting index so that the next range starts after the end of current matching range.
            startingIndex = matchingRange.upperBound

            // If the matching range is the last one, adds an element for the range after the last matching range, if non-empty.
            let isLastMatchingRange = match == matches.last
            if isLastMatchingRange {
                let lastRange = matchingRange.upperBound..<string.count
                if lastRange.isEmpty == false {
                    let content = string[lastRange]
                    elements.append(.init(content: content, isBold: false))
                }
            }
        }
        return elements
    }
}

private extension String {
    /// - Returns: A string subscript based on the given range.
    subscript(range: Range<Int>) -> String {
        let startIndex = index(self.startIndex, offsetBy: range.lowerBound)
        let endIndex = index(self.startIndex, offsetBy: range.upperBound)
        return String(self[startIndex..<endIndex])
    }
}
