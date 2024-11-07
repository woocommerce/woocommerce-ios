import SwiftUI

protocol WooPackageDataRepresentable {
    var id: UUID { get }
    var name: String { get }
    var dimensions: String { get }
    var weight: String { get }
    var type: String { get }
    var packageType: String { get }
}

struct WooSavedPackageData: WooPackageDataRepresentable {
    let id: UUID = UUID()
    let name: String
    let type: String
    let packageType: String
    let dimensions: String
    let weight: String
}

struct WooSavedPackagesSelectionView: View {
    @ObservedObject private var viewModel: WooSavedPackagesSelectionViewModel
    let addPackageAction: (WooPackageDataRepresentable) -> Void

    init(viewModel: WooSavedPackagesSelectionViewModel, addPackageAction: @escaping (WooPackageDataRepresentable) -> Void) {
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
    private func packagesSection(for packages: [any WooPackageDataRepresentable]) -> some View {
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

    private func packagesRows(for packages: [any WooPackageDataRepresentable]) -> some View {
        ForEach(packages, id: \.id) { package in
            PackageOptionView(
                isSelected: viewModel.selectedPackageId == package.id,
                package: package,
                showTopDivider: false,
                showType: true,
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
                        viewModel.removePackage(package) { error in
                            // TODO: handle error
                        }
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
    var package: WooPackageDataRepresentable
    var showTopDivider: Bool
    var showType: Bool
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
                    if showType, package.type.isNotEmpty {
                        Text(package.type)
                            .captionStyle()
                    }
                    Text(package.name)
                        .bodyStyle()
                    HStack {
                        Text(package.dimensions)
                        Text("•")
                        Text(package.weight)
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
