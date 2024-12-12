import SwiftUI
import enum Yosemite.POSItem

struct POSHeaderTitleView: View {
    var foregroundColor: Color = Color.posPrimaryText

    let parentItem: POSItem?

    var body: some View {
        Text(title(for: parentItem))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Constants.padding)
            .font(.posTitleEmphasized)
            .foregroundColor(foregroundColor)
            .accessibilityAddTraits(.isHeader)
    }

    private func title(for parentItem: POSItem?) -> String {
        switch parentItem {
        case .none:
            return Localization.productSelectorTitle
        case .some(let item):
            return item.name
        }
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
    POSHeaderTitleView(parentItem: nil)
}
