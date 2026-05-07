import SwiftUI

struct ARParcelFittingResultsView: View {
    let viewModel: ARParcelFittingResultsViewModel
    let onConfirm: (ParcelFittingResult) -> Void
    let onBack: () -> Void

    @State private var selection: Selection = .custom

    enum Selection: Hashable {
        case carrier(String)
        case custom
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { onBack() } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                }
                Spacer()
                Text("Select a package")
                    .font(.headline)
                Spacer()
                Color.clear.frame(width: 24)
            }
            .padding()

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(viewModel.carrierResults) { result in
                        carrierRow(result)
                    }
                    customRow
                }
                .padding(.horizontal)
            }

            confirmButton
                .padding()
        }
    }

    private func carrierRow(_ result: ARParcelFittingResultsViewModel.CarrierResult) -> some View {
        let isSelected = selection == .carrier(result.package.id)
        return Button {
            selection = .carrier(result.package.id)
        } label: {
            HStack(spacing: 12) {
                if let logo = result.carrier.logo {
                    Image(uiImage: logo)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                } else {
                    Text(result.carrier.name.prefix(2))
                        .font(.caption.bold())
                        .frame(width: 32, height: 32)
                        .background(Color.secondary.opacity(0.2), in: RoundedRectangle(cornerRadius: 6))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.carrier.name)
                        .font(.subheadline.bold())
                    Text(result.package.name)
                        .font(.subheadline)
                    Text(Self.formatDimensions(result.package, unit: viewModel.unit))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .font(.title3)
            }
            .padding(12)
            .background(isSelected ? Color.accentColor.opacity(0.08) : Color(.secondarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private var customRow: some View {
        let isSelected = selection == .custom
        return Button {
            selection = .custom
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "ruler")
                    .font(.title3)
                    .frame(width: 32, height: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Custom dimensions")
                        .font(.subheadline.bold())
                    Text(viewModel.dimensionsLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .font(.title3)
            }
            .padding(12)
            .background(isSelected ? Color.accentColor.opacity(0.08) : Color(.secondarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private var confirmButton: some View {
        Button {
            switch selection {
            case .carrier(let packageID):
                if let result = viewModel.carrierResults.first(where: { $0.package.id == packageID }) {
                    onConfirm(.carrierPackage(result.package))
                }
            case .custom:
                onConfirm(.customDimensions(viewModel.measuredDimensions))
            }
        } label: {
            Text(confirmButtonTitle)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.accentColor, in: Capsule())
                .foregroundStyle(.white)
        }
    }

    private var confirmButtonTitle: String {
        switch selection {
        case .carrier: return "Use selected package"
        case .custom: return "Use custom dimensions"
        }
    }

    private static func formatDimensions(_ package: ParcelPresetPackage, unit: UnitLength) -> String {
        String(format: "%.1f × %.1f × %.1f %@", package.length, package.width, package.height, unit.symbol)
    }
}
