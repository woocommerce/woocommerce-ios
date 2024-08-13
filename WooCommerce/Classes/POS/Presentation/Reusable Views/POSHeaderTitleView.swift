import SwiftUI

struct POSHeaderTitleView: View {
    var body: some View {
        Text(Localization.productSelectorTitle)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Constants.headerPadding)
            .font(.posHeaderTitle)
            .foregroundColor(Color.posPrimaryTexti3)
    }
}

private extension POSHeaderTitleView {
    enum Localization {
        static let productSelectorTitle = NSLocalizedString(
            "pos.headerTitleView.productSelectorTitle",
            value: "Products",
            comment: "Title at the top of the Point of Sale product selector screen."
        )
    }

    enum Constants {
        static let headerPadding: CGFloat = 8
    }
}

#Preview {
    POSHeaderTitleView()
}
