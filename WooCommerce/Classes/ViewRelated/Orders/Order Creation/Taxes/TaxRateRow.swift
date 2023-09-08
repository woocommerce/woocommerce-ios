import SwiftUI

struct TaxRateRow: View {
    let viewModel: TaxRateViewModel
    let onSelect: () -> Void

    var body: some View {
        HStack {
            Button(action: onSelect) {
                AdaptiveStack(horizontalAlignment: .leading, spacing: Layout.generalPadding) {
                    Text(viewModel.title)
                        .foregroundColor(Color(.text))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(viewModel.rate)
                        .foregroundColor(Color(.text))
                        .multilineTextAlignment(.trailing)
                        .frame(width: nil, alignment: .trailing)

                    Image(systemName: "chevron.right")
                        .font(.body)
                        .font(Font.title.weight(.semibold))
                        .foregroundColor(Color(.textTertiary))
                        .padding(.leading, Layout.generalPadding)
                }
                .padding(Layout.generalPadding)
            }
        }
    }
}

extension TaxRateRow {
    enum Layout {
        static let generalPadding: CGFloat = 16
    }
}
