import SwiftUI

enum WooShippingPackageSource {
    case custom
    case predefined(sourceTitle: String, sourceID: String)

    var userFriendlyDescription: String {
        switch self {
        case .custom:
            return NSLocalizedString("Custom Package", comment: "Label used to mark a custom package in list of saved packages")
        case .predefined(let sourceTitle, _):
            return sourceTitle
        }
    }

    var sourceID: String? {
        guard case .predefined(_, let sourceID) = self else {
            return nil
        }
        return sourceID
    }
}

protocol WooShippingPackageDataRepresentable {
    // backend
    var id: String { get }
    var name: String { get }
    var length: String { get }
    var width: String { get }
    var height: String { get }
    var weight: String { get }
    // local
    var source: WooShippingPackageSource { get } // custom, predefined
    var packageType: String { get } // box, envelope
}

struct WooShippingPackageData: WooShippingPackageDataRepresentable {
    // backend
    let id: String
    let name: String
    let length: String
    let width: String
    let height: String
    let weight: String
    // local
    let source: WooShippingPackageSource
    let packageType: String

    init(id: String,
         name: String,
         length: String,
         width: String,
         height: String,
         weight: String,
         source: WooShippingPackageSource,
         packageType: String) {
        self.id = id
        self.name = name
        self.length = length
        self.width = width
        self.height = height
        self.weight = weight

        self.source = source
        self.packageType = packageType
    }

    init(name: String,
         length: String,
         width: String,
         height: String,
         weight: String,
         source: WooShippingPackageSource,
         packageType: String) {
        self.init(id: name,
                  name: name,
                  length: length,
                  width: width,
                  height: height,
                  weight: weight,
                  source: source,
                  packageType: packageType)
    }
}

extension WooShippingPackageDataRepresentable {
    func dimensionsDescription(unit: String) -> String {
        return "\(length) x \(width) x \(height) \( unit)"
    }

    func weightDescription(unit: String) -> String? {
        guard weight.isNotEmpty else {
            return nil
        }
        return "\(weight) \(unit)"
    }

    var displayName: String {
        name.isNotEmpty ? name : source.userFriendlyDescription
    }
}

struct WooSavedPackagesSelectionView: View {
    @ObservedObject private var viewModel: WooShippingAddPackageViewModel
    let addPackageAction: (WooShippingPackageDataRepresentable) -> Void

    init(viewModel: WooShippingAddPackageViewModel, addPackageAction: @escaping (WooShippingPackageDataRepresentable) -> Void) {
        self.viewModel = viewModel
        self.addPackageAction = addPackageAction
    }

    var body: some View {
        VStack(spacing: 0) {
            if !viewModel.hasSavedPackages {
                // Show extra loading indicator in case there are no packages
                if viewModel.isLoadingPackages {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .padding()
                }
                else {
                    Button {
                        viewModel.loadPackages()
                    } label: {
                        Image(systemName: "arrow.trianglehead.counterclockwise")
                    }
                    .padding()
                }
            }
            else {
                Divider()
                List {
                    packagesSection(for: viewModel.customSavedPackages)
                    packagesSection(for: viewModel.predefinedSavedPackages)
                }
                .listStyle(.plain)
                .refreshable {
                    await withCheckedContinuation { continuation in
                        viewModel.loadPackages {
                            continuation.resume()
                        }
                    }
                }
                Divider()
            }
            Spacer()
            Button(WooShippingAddPackageView.Localization.addPackage) {
                addPackageButtonTapped()
            }
            .disabled(viewModel.selectedSavedPackageId == nil || !viewModel.hasSavedPackages)
            .buttonStyle(PrimaryButtonStyle())
            .padding()
        }
    }

    @ViewBuilder
    private func packagesSection(for packages: [any WooShippingPackageDataRepresentable]) -> some View {
        if packages.isEmpty {
            EmptyView()
        }
        else {
            Section {
                packagesRows(for: packages)
            }
            .listRowInsets(.zero)
        }
    }

    private func packagesRows(for packages: [any WooShippingPackageDataRepresentable]) -> some View {
        ForEach(packages, id: \.id) { package in
            WooShippingPackageOptionView(
                isSelected: viewModel.selectedSavedPackageId == package.id,
                package: package,
                showTopDivider: false,
                showSource: true,
                tapAction: {
                    viewModel.selectedSavedPackageId = viewModel.selectedSavedPackageId == package.id ? nil : package.id
                }
            )
            .alignmentGuide(.listRowSeparatorLeading) { _ in
                return 16
            }
            .swipeActions {
                Button {
                    withAnimation {
                        viewModel.removeSavedPackage(package)
                    }
                } label: {
                    Image(systemName: "trash")
                }
                .tint(Color.withColorStudio(name: .red, shade: .shade50))
            }
        }
        .listRowInsets(.zero)
    }

    private func addPackageButtonTapped() {
        // call addPackageAction with data from selected package
        guard let selectedPackage = viewModel.selectedSavedPackage else { return }

        addPackageAction(selectedPackage)
    }
}
