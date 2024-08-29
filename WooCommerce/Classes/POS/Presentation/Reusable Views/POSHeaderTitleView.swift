import SwiftUI

struct POSHeaderTitleView: View {
    var foregroundColor: Color = Color.posPrimaryText

    var body: some View {
        Text(Localization.productSelectorTitle)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Constants.padding)
            .font(.posTitleEmphasized)
            .foregroundColor(foregroundColor)
            .accessibilityAddTraits(.isHeader)
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
        static let padding: EdgeInsets = .init(top: POSHeaderLayoutConstants.sectionVerticalPadding,
                                               leading: POSHeaderLayoutConstants.sectionHorizontalPadding,
                                               bottom: POSHeaderLayoutConstants.sectionVerticalPadding,
                                               trailing: POSHeaderLayoutConstants.sectionHorizontalPadding)
    }
}

#Preview {
    POSHeaderTitleView()
}
