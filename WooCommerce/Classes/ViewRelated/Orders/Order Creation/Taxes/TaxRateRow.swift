import SwiftUI

struct TaxRateRow: View {
    let viewModel: TaxRateViewModel
    let onSelect: (() -> Void)?

    var body: some View {
        HStack {
            if let onSelect = onSelect {
                Button(action: onSelect) {
                    content
                }
            } else {
                content
            }
        }
    }

    @ViewBuilder private var content: some View {
        AdaptiveStack(horizontalAlignment: .leading, spacing: Layout.generalPadding) {
            Text(viewModel.title)
                .foregroundColor(Color(.text))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(viewModel.rate)
                .foregroundColor(Color(.text))
                .multilineTextAlignment(.trailing)
                .frame(width: nil, alignment: .trailing)

            Image(systemName: "chevron.forward")
                .font(.body)
                .font(Font.title.weight(.semibold))
                .foregroundColor(Color(.textTertiary))
                .padding(.leading, Layout.generalPadding)
                .renderedIf(viewModel.showChevron)
        }
        .padding(Layout.generalPadding)
    }
}

extension TaxRateRow {
    enum Layout {
        static let generalPadding: CGFloat = 16
    }
}
