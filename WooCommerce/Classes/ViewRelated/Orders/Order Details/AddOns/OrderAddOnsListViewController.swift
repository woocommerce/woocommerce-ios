import UIKit
import SwiftUI
import Yosemite

/// Hosting controller that wraps an `AddOnsListView`
///
final class OrderAddOnsListViewController: UIHostingController<OrderAddOnListI1View> {
    init(viewModel: OrderAddOnListI1ViewModel) {
        super.init(rootView: OrderAddOnListI1View(viewModel: viewModel))
        self.title = viewModel.title
        addCloseNavigationBarButton()
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Renders a list of add ons
///
struct OrderAddOnListI1View: View {

    /// View model that directs the view content.
    @ObservedObject private(set) var viewModel: OrderAddOnListI1ViewModel

    /// Discussion: Due to the inability of customizing the `List` separators. We have opted to simulate the list behaviour with a `ScrollView` + `VStack`.
    /// We expect performance to be acceptable as normally an order does not have too many add-ons.
    /// A future improvement can be to use a `LazyVStack` when iOS-14 becomes our minimum target.
    ///
    var body: some View {
        GeometryReader { geometry in

            // Solid color as a background view to cover all non-safe area
            Color(.listBackground).edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack {
                    OrderAddOnTopBanner(width: geometry.size.width)
                        .onDismiss {
                            viewModel.shouldShowBetaBanner = false
                        }
                        .onGiveFeedback {
                            viewModel.shouldShowSurvey = true
                        }
                        .renderedIf(viewModel.shouldShowBetaBanner)
                        .fixedSize(horizontal: false, vertical: true) // Forces view to recalculate it's height

                    ForEach(viewModel.addOns) { addOn in
                        OrderAddOnI1View(viewModel: addOn)
                            .fixedSize(horizontal: false, vertical: true) // Forces view to recalculate it's height
                    }

                    OrderAddOnNoticeView(updateText: viewModel.updateNotice)
                        .fixedSize(horizontal: false, vertical: true) // Forces view to recalculate it's height
                }
            }
        }
        .sheet(isPresented: $viewModel.shouldShowSurvey) {
            Survey(source: .addOnsI1)
        }
        .onAppear(perform: {
            viewModel.trackAddOns()
        })
    }
}

/// Renders a single order add-on
///
private struct OrderAddOnI1View: View {

    /// Static view model to populate the view content
    ///
    let viewModel: OrderAddOnI1ViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()

            Text(viewModel.title)
                .headlineStyle()
                .padding([.leading, .trailing])

            HStack(alignment: .bottom) {
                Text(viewModel.content)
                    .bodyStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(viewModel.price)
                    .secondaryBodyStyle()
            }
            .padding([.leading, .trailing])

            Divider()
        }
        .background(Color(.basicBackground))
    }
}

/// Renders a info notice with an icon
///
private struct OrderAddOnNoticeView: View {

    /// Content to be rendered next to the info icon.
    ///
    let updateText: String

    var body: some View {
        HStack {
            Image(uiImage: .infoOutlineImage)
            Text(updateText)
        }
        .footnoteStyle()
        .padding([.leading, .trailing]).padding(.top, 4)
    }
}

#if DEBUG

struct OrderAddOnView_Previews: PreviewProvider {
    static var previews: some View {
        OrderAddOnListI1View(viewModel: .init(addOnViewModels: [
            OrderAddOnI1ViewModel(addOnID: 1, title: "Topping", content: "Pepperoni", price: "$3.00"),
            OrderAddOnI1ViewModel(addOnID: 2, title: "Topping", content: "Salami", price: "$2.00"),
            OrderAddOnI1ViewModel(addOnID: 3, title: "Soda", content: "3", price: "$6.00"),
            OrderAddOnI1ViewModel(addOnID: 4, title: "Instructions", content: "Leave it in the front door", price: "")
        ]))
        .environment(\.colorScheme, .light)
    }
}

#endif
