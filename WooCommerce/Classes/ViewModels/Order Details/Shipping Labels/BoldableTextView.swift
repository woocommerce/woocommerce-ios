import SwiftUI

/// A text view that takes in a string whose substrings within two asterisks are bolded.
///
/// For example, initializing with a string "**Never** will I **stop learning**." will bold the substrings "Never" and "stop learning".
///
struct BoldableTextView: View {
    private let elements: [BoldableElement]

    init(_ content: String) {
        elements = BoldableTextParser().parseBoldableElements(string: content)
    }

    var body: some View {
        elements.map { $0.toTextView }
            .reduce(into: Text(""), { result, text in
                result = result + text
            })
    }
}

private extension BoldableElement {
    var toTextView: Text {
        if isBold {
            return Text(content).fontWeight(.bold)
        } else {
            return Text(content)
        }
    }
}

// MARK: - Previews

#if DEBUG

struct BoldableTextView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading) {
            BoldableTextView("Not a bold text.")
            BoldableTextView("")
            BoldableTextView("**Never** will I *stop learning*.")
            BoldableTextView("I will never stop *learning.")
        }
    }
}

#endif
