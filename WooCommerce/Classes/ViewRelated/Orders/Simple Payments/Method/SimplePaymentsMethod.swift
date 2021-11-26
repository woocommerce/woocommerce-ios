import Foundation
import SwiftUI

/// View to choose what payment method will be used with the simple payments order.
///
struct SimplePaymentsMethod: View {

    /// Navigation bar title.
    ///
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.noSpacing) {

            Text(Localization.header)
                .subheadlineStyle()
                .padding()

            Divider()

            Group {
                MethodRow(icon: .priceImage, title: Localization.cash) {
                    print("Tapped Cash")
                }

                Divider()

                MethodRow(icon: .creditCardImage, title: Localization.card) {
                    print("Tapped Card")
                }
            }
            .padding(.leading)
            .background(Color(.listForeground))

            Divider()

            Spacer()
        }
        .background(Color(.listBackground).ignoresSafeArea())
        .navigationTitle(title)
    }
}

/// Represents a Payment method row
///
private struct MethodRow: View {
    /// Icon of the row
    ///
    let icon: UIImage

    /// Title of the row
    ///
    let title: String

    /// Action when the row is selected
    ///
    let action: () -> ()

    /// Keeps track of the current screen scale.
    ///
    @ScaledMetric private var scale = 1

    var body: some View {
        HStack(spacing: SimplePaymentsMethod.Layout.noSpacing) {
            Image(uiImage: icon)
                .resizable()
                .frame(width: SimplePaymentsMethod.Layout.iconWidthHeight(scale: scale),
                       height: SimplePaymentsMethod.Layout.iconWidthHeight(scale: scale))
                .foregroundColor(Color(.systemGray))

            TitleAndValueRow(title: title, value: .content(""), selectable: true, action: action)
        }
    }
}

// MARK: Constants
private extension SimplePaymentsMethod {
    enum Localization {
        static let header = NSLocalizedString("Choose your payment method", comment: "Heading text on the select payment method screen for simple payments")
        static let cash = NSLocalizedString("Cash", comment: "Cash method title on the select payment method screen for simple payments")
        static let card = NSLocalizedString("Card", comment: "Card method title on the select payment method screen for simple payments")
    }

    enum Layout {
        static let noSpacing: CGFloat = 0
        static func iconWidthHeight(scale: CGFloat) -> CGFloat {
            24 * scale
        }
    }
}

// MARK: Previews
struct SimplePaymentsMethod_Preview: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SimplePaymentsMethod(title: "Take payment ($15.99)")
                .navigationBarTitleDisplayMode(.inline)
        }
        .environment(\.colorScheme, .light)
        .previewDisplayName("Light")

        NavigationView {
            SimplePaymentsMethod(title: "Take payment ($15.99)")
                .navigationBarTitleDisplayMode(.inline)
        }
        .environment(\.colorScheme, .dark)
        .previewDisplayName("Dark")

        NavigationView {
            SimplePaymentsMethod(title: "Take payment ($15.99)")
                .navigationBarTitleDisplayMode(.inline)
        }
        .environment(\.sizeCategory, .accessibilityExtraExtraLarge)
        .previewDisplayName("Accessibility")
    }
}
