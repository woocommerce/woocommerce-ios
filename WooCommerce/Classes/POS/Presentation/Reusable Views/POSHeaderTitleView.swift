import SwiftUI

struct POSHeaderTitleView: View {
    var foregroundColor: Color = Color.posPrimaryTexti3

    var body: some View {
        Text(Localization.productSelectorTitle)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Constants.padding)
            .font(.posHeaderTitle)
            .foregroundColor(foregroundColor)
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
        static let padding: EdgeInsets = .init(top: 24,
                                               leading: 16,
                                               bottom: 24,
                                               trailing: 16)
    }
}

#Preview {
    POSHeaderTitleView()
}
