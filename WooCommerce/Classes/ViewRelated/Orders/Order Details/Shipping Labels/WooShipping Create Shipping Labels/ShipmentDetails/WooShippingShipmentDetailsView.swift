import SwiftUI
import WooFoundation
import struct Yosemite.WooShippingServiceStatusNotice

struct WooShippingShipmentDetailsView: View {
    @ObservedObject private var viewModel: WooShippingShipmentDetailsViewModel
    @State private var showingRefundRequest = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let serviceStatusNotices: [WooShippingServiceStatusNotice]
    private let onDismissServiceStatusNotice: (_ noticeID: String) -> Void

    init(viewModel: WooShippingShipmentDetailsViewModel,
         serviceStatusNotices: [WooShippingServiceStatusNotice] = [],
         onDismissServiceStatusNotice: @escaping (_ noticeID: String) -> Void = { _ in }) {
        self.viewModel = viewModel
        self.serviceStatusNotices = serviceStatusNotices
        self.onDismissServiceStatusNotice = onDismissServiceStatusNotice
    }

    var body: some View {
        VStack(spacing: Layout.verticalSpacing) {
            if viewModel.canViewLabel, let postPurchase = viewModel.postPurchase {
                WooShippingPostPurchaseView(viewModel: postPurchase, onRefundRequest: {
                    showingRefundRequest = true
                })
            }

            WooShippingItems(itemsCountLabel: viewModel.itemsCountLabel,
                             itemsDetailLabel: viewModel.itemsDetailLabel,
                             items: viewModel.itemsRowViewModels,
                             itemsSummaryAccessibilityValue: viewModel.itemsSummaryAccessibilityValue)

            WooShippingHazmatRow(selectedCategory: $viewModel.hazmatCategory,
                                 enabled: !viewModel.canViewLabel)

            WooShippingCustomsRow(informationIsCompleted: viewModel.customsInformationIsCompleted,
                                  isCheckingRequirements: viewModel.isCheckingEUProductIdentifiers,
                                  customsFormViewModel: viewModel.customsFormViewModel)
                .padding(.bottom, Layout.contentSpacing)
                .renderedIf(viewModel.shouldShowCustomsForm)

            if !viewModel.canViewLabel && serviceStatusNotices.isNotEmpty {
                WooShippingServiceStatusNoticesView(notices: serviceStatusNotices,
                                                    onDismiss: onDismissServiceStatusNotice)
                    .padding(.bottom, Layout.contentSpacing)
            }

            if viewModel.canViewLabel {
                EmptyView()
            } else if let package = viewModel.selectedPackage,
                      let shippingService = viewModel.shippingService {
                WooShippingSelectedPackageView(package: package,
                                               totalWeight: $viewModel.shipmentWeight,
                                               lastARState: viewModel.lastARState,
                                               arAnalytics: ParcelFittingAnalyticsAdaptor(),
                                               parcelFittingDelegate: viewModel,
                                               updateSelectedPackage: { viewModel.selectPackage($0) })
                WooShippingServiceView(viewModel: shippingService)
            } else {
                WooShippingPackageAndRatePlaceholder(
                    onSelectPackage: { viewModel.selectPackage($0) },
                    arDelegate: viewModel
                )
            }
        }
        // Animates only notice changes, so switching shipment tabs never re-animates the banners.
        .animation(reduceMotion ? nil : .easeInOut, value: serviceStatusNotices.map(\.id))
        .sheet(isPresented: $showingRefundRequest) {
            if let refundViewModel = viewModel.refundViewModel {
                WooShippingRefundView(viewModel: refundViewModel) { updatedLabel in
                    showingRefundRequest = false
                    viewModel.didRequestRefund(for: updatedLabel.shippingLabelID)
                }
            }
        }
    }
}

private extension WooShippingShipmentDetailsView {
    enum Layout {
        static let verticalSpacing: CGFloat = 8
        static let contentSpacing: CGFloat = 16
    }
}
