import SwiftUI
import Foundation
import WooFoundation

struct CustomAmountRowView: View {
    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    let viewModel: CustomAmountRowViewModel
    let editable: Bool

    var body: some View {
        HStack(alignment: .center, spacing: Layout.contentSpacing) {
            Text(viewModel.name)
                .foregroundColor(.init(UIColor.text))
                .subheadlineStyle()
                .multilineTextAlignment(.leading)
                // Avoids the custom amount name to be truncated when it's long enough
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Text(viewModel.total)
                .foregroundColor(.init(UIColor.text))
                .subheadlineStyle()

            Image(systemName: "pencil")
                .resizable()
                .frame(width: Layout.editIconImageSize * scale,
                       height: Layout.editIconImageSize * scale)
                .foregroundColor(Color(.wooCommercePurple(.shade60)))
        }
        .padding(Layout.contentPadding)
        .onTapGesture {
            viewModel.onEditCustomAmount()
        }
        .background(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .fill(Color(uiColor: .init(light: UIColor.clear,
                                           dark: UIColor.systemGray5)))
        )
        .overlay {
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .stroke(Color(uiColor: .separator), lineWidth: Layout.borderLineWidth)
        }
    }
}

extension CustomAmountRowView {
    enum Layout {
        static let contentSpacing: CGFloat = 16
        static let contentPadding: CGFloat = 16
        static let cornerRadius: CGFloat = 8
        static let borderLineWidth: CGFloat = 0.5
        static let editIconImageSize: CGFloat = 16
    }
}
