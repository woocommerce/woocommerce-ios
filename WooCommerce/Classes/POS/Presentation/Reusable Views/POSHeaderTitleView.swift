import SwiftUI

struct POSHeaderTitleView: View {
    private let title: String
    private let foregroundColor: Color

    init(title: String, foregroundColor: Color = .posPrimaryText) {
        self.title = title
        self.foregroundColor = foregroundColor
    }

    var body: some View {
        Text(title)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Constants.padding)
            .font(.posTitleEmphasized)
            .foregroundColor(foregroundColor)
            .accessibilityAddTraits(.isHeader)
    }
}

private extension POSHeaderTitleView {
    enum Constants {
        static let padding: EdgeInsets = .init(top: POSHeaderLayoutConstants.sectionVerticalPadding,
                                               leading: POSHeaderLayoutConstants.sectionHorizontalPadding,
                                               bottom: POSHeaderLayoutConstants.sectionVerticalPadding,
                                               trailing: POSHeaderLayoutConstants.sectionHorizontalPadding)
    }
}

#Preview {
    POSHeaderTitleView(title: "Products")
}
