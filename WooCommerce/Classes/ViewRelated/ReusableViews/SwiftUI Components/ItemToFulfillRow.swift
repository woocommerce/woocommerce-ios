import SwiftUI

/// Represent a row of a Product Item that should be fulfilled
///
struct ItemToFulfillRow: View, Identifiable {
    let id = UUID()
    let productOrVariationID: Int64
    let title: String
    let subtitle: String
    var moveItemActionSheetTitle: String = ""
    var moveItemActionSheetButtons: [ActionSheet.Button] = []
    @State private var showingMoveItemDialog: Bool = false

    var body: some View {
        if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.shippingLabelsInternational) {
            HStack {
                TitleAndSubtitleRow(title: title, subtitle: subtitle)
                Spacer()
                Button(action: {
                    guard !showingMoveItemDialog else {
                        showingMoveItemDialog = false
                        return
                    }
                    showingMoveItemDialog = true
                    ServiceLocator.analytics.track(.shippingLabelMoveItemTapped)
                }, label: {
                    Text(Localization.moveButton)
                        .font(.footnote)
                        .foregroundColor(Color(UIColor(color: .accent)))
                })
                .padding(.trailing, Constants.horizontalPadding)
                .actionSheet(isPresented: $showingMoveItemDialog, content: {
                    ActionSheet(title: Text(moveItemActionSheetTitle),
                                buttons: moveItemActionSheetButtons)
                })
            }
        } else {
            TitleAndSubtitleRow(title: title, subtitle: subtitle)
        }
    }
}

private extension ItemToFulfillRow {
    enum Localization {
        static let moveButton = NSLocalizedString("Move", comment: "Button on each order item of the Package Details screen in Shipping Labels flow.")
    }

    enum Constants {
        static let horizontalPadding: CGFloat = 16
    }
}

struct ItemToFulfillRow_Previews: PreviewProvider {
    static var previews: some View {
        ItemToFulfillRow(productOrVariationID: 123, title: "Title", subtitle: "My subtitle")
            .previewLayout(.fixed(width: 375, height: 100))
    }
}
