import SwiftUI
import Foundation
import WooFoundation

struct CustomAmountRowView: View {
    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    let viewModel: CustomAmountRowViewModel
    let editable: Bool

    var body: some View {
        HStack(alignment: .center) {
            Image(systemName: "tag")
                .resizable()
                .foregroundColor(Color(uiColor: .secondaryLabel))
                .frame(width: Layout.tagIconImageSize * scale, height: Layout.tagIconImageSize * scale)
                .padding()
                .overlay {
                    RoundedRectangle(cornerRadius: Layout.tagBorderCornerRadius)
                        .stroke(Color(.separator), lineWidth: Layout.tagBorderLineWidth)
                }

            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    Text(viewModel.name)
                        .foregroundColor(Color(.wooCommercePurple(.shade60)))
                        .bodyStyle()
                    Button {} label: {
                        Image(systemName: "pencil")
                            .resizable()
                            .padding(.top, Layout.editIconTopPadding)
                            .frame(width: Layout.editIconImageSize * scale,
                                   height: Layout.editIconImageSize * scale)
                            .renderedIf(editable)
                    }
                }

                Text(viewModel.total)
                    .subheadlineStyle()
            }

            Spacer()

            Button {
                viewModel.onRemoveCustomAmount()
            } label: {
                Image(systemName: "xmark")
            }
            .foregroundColor(Color(.secondaryLabel))
            .tertiaryTitleStyle()
            .frame(width: Layout.closeButtonImageSize * scale,
                   height: Layout.closeButtonImageSize * scale, alignment: .trailing)
            .renderedIf(editable)

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Layout.topPadding)
    }
}

extension CustomAmountRowView {
    enum Layout {
        static let tagBorderCornerRadius: CGFloat = 4
        static let tagBorderLineWidth: CGFloat = 0.5
        static let tagIconImageSize: CGFloat = 25
        static let editIconImageSize: CGFloat = 16
        static let editIconTopPadding: CGFloat = 3
        static let closeButtonImageSize: CGFloat = 25
        static let topPadding: CGFloat = 16
    }
}
