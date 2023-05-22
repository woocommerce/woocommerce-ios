import SwiftUI
import Yosemite

final class ShippingCustomsFormListHostingController: UIHostingController<ShippingLabelCustomsFormList> {
    init(order: Order,
         customsForms: [ShippingLabelCustomsForm],
         destinationCountry: Country,
         countries: [Country],
         isEUShippingScenario: Bool,
         onCompletion: @escaping ([ShippingLabelCustomsForm]) -> Void) {
        let viewModel = ShippingLabelCustomsFormListViewModel(order: order,
                                                              customsForms: customsForms,
                                                              destinationCountry: destinationCountry,
                                                              countries: countries,
                                                              isEUShippingScenario: isEUShippingScenario)
        super.init(rootView: .init(viewModel: viewModel, onCompletion: onCompletion))

        rootView.onLearnMoreTapped = { [weak self] in
            self?.presentShippingInstructionsView()
        }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func presentShippingInstructionsView() {
        let instructionsURL = WooConstants.URLs.shippingCustomsInstructionsForEUCountries.asURL()
        WebviewHelper.launch(instructionsURL, with: self)
    }
}

struct ShippingLabelCustomsFormList: View {
    @Environment(\.presentationMode) var presentation
    @ObservedObject private var viewModel: ShippingLabelCustomsFormListViewModel
    @State private var shippingNoticeBannerID = UUID()

    private let onCompletion: ([ShippingLabelCustomsForm]) -> Void

    var onLearnMoreTapped: () -> Void = {}

    init(viewModel: ShippingLabelCustomsFormListViewModel,
         onCompletion: @escaping ([ShippingLabelCustomsForm]) -> Void) {
        self.viewModel = viewModel
        self.onCompletion = onCompletion
        ServiceLocator.analytics.track(.shippingLabelPurchaseFlow, withProperties: ["state": "customs_started"])
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { scrollProxy in
                ScrollView {
                    EUShippingNoticeBanner(width: geometry.size.width)
                        .onDismiss {
                            viewModel.bannerDismissTapped()
                        }
                        .onLearnMore {
                            onLearnMoreTapped()
                        }
                        .renderedIf(viewModel.isShippingNoticeVisible)
                        .fixedSize(horizontal: false, vertical: true)
                        .id(shippingNoticeBannerID)

                    ForEach(Array(viewModel.inputViewModels.enumerated()), id: \.offset) { (index, item) in
                        ShippingLabelCustomsFormInput(isCollapsible: viewModel.multiplePackagesDetected,
                                                      packageNumber: index + 1,
                                                      safeAreaInsets: geometry.safeAreaInsets,
                                                      viewModel: item,
                                                      infoTooltipTapped: {
                            viewModel.onInfoTooltipTapped()
                            withAnimation {
                                scrollProxy.scrollTo(shippingNoticeBannerID, anchor: .top)
                            }
                        })
                    }
                    .padding(.bottom, insets: geometry.safeAreaInsets)
                }
                .background(Color(.listBackground))
                .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
            }
        }
        .navigationTitle(Localization.navigationTitle)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: {
                    onCompletion(viewModel.validatedCustomsForms)
                    presentation.wrappedValue.dismiss()
                    ServiceLocator.analytics.track(.shippingLabelPurchaseFlow, withProperties: ["state": "customs_complete"])
                }, label: {
                    Text(Localization.doneButton)
                }).disabled(!viewModel.doneButtonEnabled)
            }
        }
        .wooNavigationBarStyle()
    }
}

private extension ShippingLabelCustomsFormList {
    enum Localization {
        static let navigationTitle = NSLocalizedString("Customs", comment: "Navigation title for Customs screen in Shipping Label flow")
        static let doneButton = NSLocalizedString("Done", comment: "Done navigation button in the Customs screen in Shipping Label flow")
    }
}

#if DEBUG
struct ShippingLabelCustomsFormList_Previews: PreviewProvider {
    static let sampleViewModel: ShippingLabelCustomsFormListViewModel = {
        let sampleOrder = ShippingLabelSampleData.sampleOrder()
        let sampleForm = ShippingLabelCustomsForm(packageID: "Food Package", packageName: "Food Package", items: [])
        return ShippingLabelCustomsFormListViewModel(order: sampleOrder,
                                                     customsForms: [sampleForm],
                                                     destinationCountry: Country(code: "VN", name: "Vietnam", states: []),
                                                     countries: [])
    }()

    static var previews: some View {
        ShippingLabelCustomsFormList(viewModel: sampleViewModel) { _ in }
    }
}
#endif
