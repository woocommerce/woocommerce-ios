import SwiftUI
import Yosemite

struct ShippingLabelAddNewPackage: View {
    @ObservedObject var viewModel: ShippingLabelAddNewPackageViewModel
    @Environment(\.presentationMode) var presentation
    @State var isSyncing = false

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    SegmentedView(selection: $viewModel.selectedIndex, views: [Text(Localization.customPackage), Text(Localization.servicePackage)])
                        .frame(height: 44)
                    Divider()
                }
                .padding(.horizontal, insets: geometry.safeAreaInsets)

                ScrollView {
                    switch viewModel.selectedView {
                    case .customPackage:
                        ShippingLabelCustomPackageForm(viewModel: viewModel.customPackageVM, safeAreaInsets: geometry.safeAreaInsets)
                    case .servicePackage:
                        ShippingLabelServicePackageList(viewModel: viewModel.servicePackageVM, geometry: geometry)
                    }
                }
                 .background(Color(.listBackground).ignoresSafeArea(.container, edges: .bottom))
            }
            .ignoresSafeArea(.container, edges: .horizontal)
            .navigationTitle(Localization.title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                // Minimal back button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        presentation.wrappedValue.dismiss()
                    } label: {
                        Image(uiImage: .chevronLeftImage.imageFlippedForRightToLeftLayoutDirection())
                    }
                }
                // Done button
                ToolbarItem(placement: .navigationBarTrailing, content: {
                    Button(action: {
                        isSyncing = true
                        switch viewModel.selectedView {
                        case .customPackage:
                            viewModel.customPackageVM.validatePackage()
                            if viewModel.customPackageVM.validatedCustomPackage != nil {
                                viewModel.createCustomPackage()
                            }
                        case .servicePackage:
                            viewModel.activateServicePackage()
                        }
                    }, label: {
                        if isSyncing {
                            ActivityIndicator(isAnimating: .constant(true), style: .medium)
                                .accentColor(Color(.navigationBarLoadingIndicator))
                        } else {
                            Text(Localization.doneButton)
                        }
                    })
                    .disabled(isSyncing)
                    .onAppear() {
                        // Dismiss the view after API calls are finished
                        viewModel.$dismissView.sink { dismiss in
                            guard dismiss else { return }
                            viewModel.dismissView = false
                            isSyncing = false
                            presentation.wrappedValue.dismiss()
                        }.cancel()
                    }
                })
            }
        }
    }
}

private extension ShippingLabelAddNewPackage {
    enum Localization {
        static let title = NSLocalizedString("Add New Package", comment: "Add New Package screen title in Shipping Label flow")
        static let customPackage = NSLocalizedString("Custom Package", comment: "Custom Package menu in Shipping Label Add New Package flow")
        static let servicePackage = NSLocalizedString("Service Package", comment: "Service Package menu in Shipping Label Add New Package flow")
        static let doneButton = NSLocalizedString("Done", comment: "Done navigation button in the Add New Package screen in Shipping Label flow")
    }
}

struct ShippingLabelAddNewPackage_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ShippingLabelAddNewPackageViewModel(siteID: 12345,
                                                            packagesResponse: ShippingLabelPackageDetailsViewModel.samplePackageDetails(),
                                                            onCompletion: { _, _, _ in })

        ShippingLabelAddNewPackage(viewModel: viewModel)
    }
}
