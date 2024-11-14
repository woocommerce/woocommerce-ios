import SwiftUI

enum WooShippingPackageSource {
    case custom
    case predefined(String)

    var userFriendlyDescription: String {
        switch self {
        case .custom:
            return NSLocalizedString("Custom Package", comment: "Label used to mark a custom package in list of saved packages")
        case .predefined(let source):
            return source
        }
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
    var weightDescription: String { get }
    var dimensionsDescription: String { get }
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
    let weightDescription: String
    let dimensionsDescription: String
    let source: WooShippingPackageSource
    let packageType: String

    init(id: String,
         name: String,
         length: String,
         width: String,
         height: String,
         dimensionsUnit: String,
         weight: String,
         weightUnit: String,
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

        self.dimensionsDescription = WooShippingPackageData.createDimensionsDescription(length: length, width: width, height: height, unit: dimensionsUnit)
        self.weightDescription = WooShippingPackageData.createWeightsDescription(weight: weight, unit: weightUnit)
    }

    init(name: String,
         length: String,
         width: String,
         height: String,
         dimensionsUnit: String,
         weight: String,
         weightUnit: String,
         source: WooShippingPackageSource,
         packageType: String) {
        self.init(id: name,
                  name: name,
                  length: length,
                  width: width,
                  height: height,
                  dimensionsUnit: dimensionsUnit,
                  weight: weight,
                  weightUnit: weightUnit,
                  source: source,
                  packageType: packageType)
    }
}

extension WooShippingPackageDataRepresentable {
    static func createDimensionsDescription(length: String, width: String, height: String, unit: String) -> String {
        return "\(length) x \(width) x \(height) \( unit)"
    }

    static func createWeightsDescription(weight: String, unit: String) -> String {
        return "\(weight) \(unit)"
    }
}

struct WooSavedPackagesSelectionView: View {
    @ObservedObject private var viewModel: WooSavedPackagesSelectionViewModel
    let addPackageAction: (WooShippingPackageDataRepresentable) -> Void

    init(viewModel: WooSavedPackagesSelectionViewModel, addPackageAction: @escaping (WooShippingPackageDataRepresentable) -> Void) {
        self.viewModel = viewModel
        self.addPackageAction = addPackageAction
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            if viewModel.packagesRepository.loadingSavedPackages {
                // TODO: think of a better progress/loading indicator
                ProgressView()
                    .progressViewStyle(.circular)
                    .padding()
            }
            List {
                packagesSection(for: viewModel.customSavedPackages)
                packagesSection(for: viewModel.predefinedSavedPackages)
            }
            .listStyle(.plain)
            .refreshable {
                viewModel.packagesRepository.loadSavedPackages()
            }
            Divider()
            Button(WooShippingAddPackageView.Localization.addPackage) {
                addPackageButtonTapped()
            }
            .disabled(viewModel.selectedPackageId == nil || !viewModel.hasPackages)
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
            PackageOptionView(
                isSelected: viewModel.selectedPackageId == package.id,
                package: package,
                showTopDivider: false,
                showSource: true,
                tapAction: {
                    viewModel.selectedPackageId = viewModel.selectedPackageId == package.id ? nil : package.id
                }
            )
            .alignmentGuide(.listRowSeparatorLeading) { _ in
                return 16
            }
            .swipeActions {
                Button {
                    withAnimation {
                        _ = Task {
                            return await viewModel.removePackage(package)
                        }
                        // TODO: handle error
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
        guard let selectedPackage = viewModel.selectedPackage else { return }

        addPackageAction(selectedPackage)
    }
}

struct PackageOptionView: View {
    enum Constants {
        static let verticalSpacing: CGFloat = 4.0
        static let textContentLeadingPadding: CGFloat = 4.0
        static let contentPadding: CGFloat = 16.0
    }

    var isSelected: Bool
    var package: WooShippingPackageDataRepresentable
    var showTopDivider: Bool
    var showSource: Bool
    var tapAction: () -> Void
    var starAction: (() -> Void)?
    var starred: Bool?

    var body: some View {
        HStack(spacing: 0) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Color(.withColorStudio(.wooCommercePurple, shade: .shade60)) : .gray)
                    .font(.title)
                VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
                    if showSource {
                        Text(package.source.userFriendlyDescription)
                            .captionStyle()
                    }
                    Text(package.name)
                        .bodyStyle()
                    HStack {
                        Text(package.dimensionsDescription)
                        Text("•")
                        Text(package.weightDescription)
                    }
                    .subheadlineStyle()
                }
                .padding(.leading, Constants.textContentLeadingPadding)
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                tapAction()
            }
            .padding(Constants.contentPadding)
            if let starAction, let starred {
                VStack {
                    Image(systemName: starred ? "star.fill": "star")
                        .foregroundStyle(.secondary)
                        .padding(Constants.contentPadding)
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    starAction()
                }
            }
        }
    }
}
