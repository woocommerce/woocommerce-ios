
import Foundation
import UIKit

/// A section header with a headline-style title and a white background.
///
/// This is originally used for the Order Details' Product section header.
///
final class PrimarySectionHeaderView: UITableViewHeaderFooterView {

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var containerView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()

        titleLabel.text = ""
        titleLabel.applyHeadlineStyle()

        containerView.backgroundColor = Colors.containerViewBackgroundColor

        addDummyViewToHideSectionSeparator()
    }

    /// Change the configurable properties of this header.
    ///
    func configure(title: String?) {
        titleLabel.text = title
    }

    /// Creates a dummy border which will cover the grouped section separator that is normally
    /// shown below this header view.
    ///
    private func addDummyViewToHideSectionSeparator() {
        // The separator has to be the same color as the container
        let separator = UIView.createBorderView(color: Colors.containerViewBackgroundColor)

        containerView.addSubview(separator)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: separator.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: separator.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: separator.topAnchor)
        ])
    }
}

// MARK: - Constants

private extension PrimarySectionHeaderView {
    enum Colors {
        static let containerViewBackgroundColor = UIColor.basicBackground
    }
}

// MARK: - Previews

#if canImport(SwiftUI) && DEBUG

import SwiftUI

private struct PrimarySectionHeaderViewRepresentable: UIViewRepresentable {
    let title: String

    func makeUIView(context: Context) -> PrimarySectionHeaderView {
        .instantiateFromNib()
    }

    func updateUIView(_ view: PrimarySectionHeaderView, context: Context) {
        view.configure(title: title)
    }
}

@available(iOS 13.0, *)
struct PrimarySectionHeaderView_Previews: PreviewProvider {

    private static func makeStack() -> some View {
        VStack {
            PrimarySectionHeaderViewRepresentable(title: "Products Eos omnis eius")
        }
        .background(Color(UIColor.listBackground))
    }

    static var previews: some View {
        Group {
            makeStack()
                .previewLayout(.fixed(width: 320, height: 60))
                .previewDisplayName("Light")

            makeStack()
                .previewLayout(.fixed(width: 320, height: 60))
                .environment(\.colorScheme, .dark)
                .previewDisplayName("Dark")

            makeStack()
                .previewLayout(.fixed(width: 320, height: 160))
                .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
                .previewDisplayName("Large Font")
        }
    }
}

#endif
