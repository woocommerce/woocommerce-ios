import UIKit
import SwiftUI
import Yosemite

/// Hosting controller that wraps an `AddOnsListView`
///
class AddOnsListViewController: UIHostingController<AddOnsListI1View> {
    init(addOns: [OrderItemAttribute]) {
        super.init(rootView: AddOnsListI1View())
        self.title = Localization.title
        addCloseNavigationBarButton()
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Constants
private extension AddOnsListViewController {
    enum Localization {
        static let title = NSLocalizedString("Product Add-ons", comment: "The title on the navigation bar when viewing an order item add-ons")
    }
}

/// Renders a list of add ons
///
struct AddOnsListI1View: View {
    var body: some View {
        ScrollView {
            VStack {
                ForEach(1..<5) { _ in
                    OrderAddOnView()
                }
            }
        }
        .background(Color(.listBackground))
    }
}

struct OrderAddOnView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()

            Text("Instructions")
                .headlineStyle()
                .padding(.leading)

            HStack(alignment: .bottom) {
                Text("Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard")
                    .bodyStyle()
                Text("$300.00")
                    .secondaryBodyStyle()
            }
            .padding([.leading, .trailing])

            Divider()
        }
        .background(Color(.basicBackground))
    }
}


#if DEBUG

struct OrderAddOnView_Previews: PreviewProvider {
    static var previews: some View {

        AddOnsListI1View()
            .environment(\.colorScheme, .light)

//        AddOnsListI1View()
//            .environment(\.colorScheme, .dark)
//
//        AddOnsListI1View()
//            .environment(\.layoutDirection, .rightToLeft)
//
//        AddOnsListI1View()
//            .environment(\.sizeCategory, .accessibilityLarge)
    }
}

#endif
