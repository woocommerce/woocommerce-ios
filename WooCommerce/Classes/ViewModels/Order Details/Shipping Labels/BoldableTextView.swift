import SwiftUI

/// A text view that takes in a string whose substrings within two asterisks are bolded.
///
/// For example, initializing with a string "*Never* will I *stop learning*." will bold the substrings "Never" and "stop learning".
///
struct BoldableTextView: View {
    fileprivate struct Element {
        let content: String
        let isBold: Bool

        init(content: String, isBold: Bool) {
            if isBold {
                self.content = content.replacingOccurrences(of: boldRegionMark, with: "")
            } else {
                self.content = content
            }
            self.isBold = isBold
        }
    }

    fileprivate static let boldRegionMark = "*"

    private let elements: [Element]

    init(_ content: String) {
        elements = content.parseBoldableElements()
    }

    var body: some View {
        elements.map { $0.toTextView }
            .reduce(into: Text(""), { result, text in
                result = result + text
            })
    }
}

private extension BoldableTextView.Element {
    var toTextView: Text {
        if isBold {
            return Text(content).fontWeight(.bold)
        } else {
            return Text(content)
        }
    }
}

private extension String {
    /// Parses the input text and returns a collection of boldable elements.
    ///
    /// - Returns: A collection of boldable elements.
    func parseBoldableElements() -> [BoldableTextView.Element] {
        let boldRegionMark = BoldableTextView.boldRegionMark
        let regex = try! NSRegularExpression(pattern: "\\\(boldRegionMark){1}(.*?)\\\(boldRegionMark){1}")
        let range = NSRange(location: 0, length: count)

        /// Finds all the ranges that match the regex for content within a bold region.
        let matches: [NSTextCheckingResult] = regex.matches(in: self, options: [], range: range)
        let matchingRanges = matches.compactMap { Range<Int>($0.range) }

        guard matchingRanges.isNotEmpty else {
            return [BoldableTextView.Element(content: self, isBold: false)]
        }

        var elements: [BoldableTextView.Element] = []

        var startingIndex = 0
        matchingRanges.enumerated().forEach { index, matchingRange in
            // Adds an element for the range from the last index and before the matching range, if non-empty.
            let rangeBefore = startingIndex..<matchingRanges[index].lowerBound
            if rangeBefore.isEmpty == false {
                let content = self[rangeBefore]
                elements.append(BoldableTextView.Element(content: content, isBold: false))
            }

            // Adds an element for the matching range which should be bold.
            let matchContent = self[matchingRange]
            elements.append(BoldableTextView.Element(content: matchContent, isBold: true))

            // Updates the last starting index so that the next range starts after the end of current matching range.
            startingIndex = matchingRange.upperBound

            // If the matching range is the last one, adds an element for the range after the last matching range, if non-empty.
            let isLastMatchingRange = matchingRange == matchingRanges.last
            if isLastMatchingRange {
                let lastRange = matchingRange.upperBound..<count
                if lastRange.isEmpty == false {
                    let content = self[lastRange]
                    elements.append(BoldableTextView.Element(content: content, isBold: false))
                }
            }
        }
        return elements
    }

    /// - Returns: A string subscript based on the given range.
    subscript(range: Range<Int>) -> String {
        let startIndex = index(self.startIndex, offsetBy: range.lowerBound)
        let endIndex = index(self.startIndex, offsetBy: range.upperBound)
        return String(self[startIndex..<endIndex])
    }
}

struct RichTextView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading) {
            BoldableTextView("Not a bold text.")
            BoldableTextView("")
            BoldableTextView("*Never* will I *stop learning*.")
            BoldableTextView("I will never stop *learning.")
        }
    }
}
