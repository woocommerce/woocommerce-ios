import SwiftUI
import Yosemite

struct ShippingLabelAddNewPackage: View {
    @ObservedObject var viewModel: ShippingLabelAddNewPackageViewModel
    @Environment(\.presentationMode) var presentation
    @State private var isSyncing = false
    @State private var showingAddPackageError = false

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
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        presentation.wrappedValue.dismiss()
                    } label: {
                        Image(uiImage: .chevronLeftImage).flipsForRightToLeftLayoutDirection(true)
                    }
                    .accessibilityLabel(Localization.backButtonAccessibilityLabel)
                }
                // Done button
                ToolbarItem(placement: .confirmationAction, content: {
                    Button(action: {
                        switch viewModel.selectedView {
                        case .customPackage:
                            viewModel.customPackageVM.validatePackage()
                            guard viewModel.customPackageVM.validatedCustomPackage != nil else { return }
                            isSyncing = true
                            viewModel.createCustomPackage() { success in
                                isSyncing = false
                                guard success else {
                                    showingAddPackageError = true
                                    return
                                }
                                presentation.wrappedValue.dismiss()
                            }
                        case .servicePackage:
                            isSyncing = true
                            viewModel.activateServicePackage() { success in
                                isSyncing = false
                                guard success else {
                                    showingAddPackageError = true
                                    return
                                }
                                presentation.wrappedValue.dismiss()
                            }
                        }
                    }, label: {
                        if isSyncing {
                            ActivityIndicator(isAnimating: .constant(true), style: .medium)
                                .tint(Color(.navigationBarLoadingIndicator))
                        } else {
                            Text(Localization.doneButton)
                        }
                    })
                    .disabled(isSyncing)
                    .alert(isPresented: $showingAddPackageError, content: {
                        let title = viewModel.error?.alertTitle ?? Localization.errorAlertTitle
                        let message = viewModel.error?.errorDescription ?? Localization.errorAlertMessage
                        return Alert(title: Text(title), message: Text(message))
                    })
                })
            }
        }
    }
}

private extension ShippingLabelAddNewPackage {
    enum Localization {
        static let title = NSLocalizedString("Add New Package", comment: "This text appears as the screen title in the navigation bar when users are adding a new package during the shipping label creation process in WooCommerce.")
        static let customPackage = NSLocalizedString("Custom Package", comment: "Custom Package menu in Shipping Label Add New Package flow")
        static let servicePackage = NSLocalizedString("Service Package", comment: "Service Package menu in Shipping Label Add New Package flow")
        static let doneButton = NSLocalizedString("Done", comment: "Done navigation button in the Add New Package screen in Shipping Label flow")
        static let errorAlertTitle = NSLocalizedString("Cannot add package", comment: "This text appears as the title of an error alert dialog that is shown when there is a generic failure while trying to add a new shipping package in the shipping label creation flow.")
        static let errorAlertMessage = NSLocalizedString("Unexpected error",
                                                         comment: "The message of the alert when there is an unexpected error adding the package")
        static let backButtonAccessibilityLabel = NSLocalizedString("Back", comment: "This text appears as the accessibility label for back navigation buttons in various screens throughout the WooCommerce app, including web view navigation, shipping label package creation, and product variation selection screens. It helps screen readers identify the back button functionality for visually impaired users.")
    }
}

#if DEBUG
struct ShippingLabelAddNewPackage_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ShippingLabelAddNewPackageViewModel(siteID: 12345,
                                                            packagesResponse: ShippingLabelSampleData.samplePackageDetails(),
                                                            onCompletion: { _, _, _ in })

        ShippingLabelAddNewPackage(viewModel: viewModel)
    }
}
#endif
