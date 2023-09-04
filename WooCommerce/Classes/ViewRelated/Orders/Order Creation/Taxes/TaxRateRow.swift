import SwiftUI

struct TaxRateRow: View {
    let viewModel: TaxRateViewModel

    var body: some View {
        HStack {
            Button(action: { }) {
                AdaptiveStack(horizontalAlignment: .leading, spacing: Layout.generalPadding) {
                    Text(viewModel.name)
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
