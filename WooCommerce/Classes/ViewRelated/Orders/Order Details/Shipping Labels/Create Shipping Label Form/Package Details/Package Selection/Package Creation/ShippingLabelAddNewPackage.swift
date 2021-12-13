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
                        Image(uiImage: .chevronLeftImage.imageFlippedForRightToLeftLayoutDirection())
                    }
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
                                .accentColor(Color(.navigationBarLoadingIndicator))
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
        static let title = NSLocalizedString("Add New Package", comment: "Add New Package screen title in Shipping Label flow")
        static let customPackage = NSLocalizedString("Custom Package", comment: "Custom Package menu in Shipping Label Add New Package flow")
        static let servicePackage = NSLocalizedString("Service Package", comment: "Service Package menu in Shipping Label Add New Package flow")
        static let doneButton = NSLocalizedString("Done", comment: "Done navigation button in the Add New Package screen in Shipping Label flow")
        static let errorAlertTitle = NSLocalizedString("Cannot add package", comment: "The title of the alert when there is a generic error adding the package")
        static let errorAlertMessage = NSLocalizedString("Unexpected error",
                                                         comment: "The message of the alert when there is an unexpected error adding the package")
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
