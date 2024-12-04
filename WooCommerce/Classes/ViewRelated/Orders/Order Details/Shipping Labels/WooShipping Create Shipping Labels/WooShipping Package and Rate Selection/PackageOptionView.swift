import SwiftUI
import TipKit

struct PackageOptionView: View {
    enum Constants {
        static let verticalSpacing: CGFloat = 4.0
        static let textContentLeadingPadding: CGFloat = 4.0
        static let contentPadding: CGFloat = 16.0
    }

    var isSelected: Bool?
    var package: WooShippingPackageDataRepresentable
    var showTopDivider: Bool
    var showSource: Bool
    var tapAction: () -> Void
    var starAction: (() -> Void)?
    var starred: Bool?

    /// Title for an optional tip.
    ///
    /// Set this title to display the tip once.
    var tipTitle: Text? = nil
    /// Optional message for the tip.
    var tipMessage: Text? = nil
    /// Optional image for the tip.
    var tipImage: Image? = nil

    /// Tip to display above the package option view, if `tipTitle` is set.
    private var tip: PackageOptionTip? {
        guard #available(iOS 17.0, *), let tipTitle else {
            return nil
        }
        return PackageOptionTip(title: tipTitle, message: tipMessage, image: tipImage)
    }

    var body: some View {
        VStack {
            if #available(iOS 17.0, *), starAction != nil, let tip {
                TipView(tip, arrowEdge: .bottom)
                    .tipCornerRadius(0)
                    .tipImageSize(CGSize(width: 16, height: 16))
            }
            HStack(spacing: 0) {
                HStack {
                    if let isSelected {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isSelected ? Color(.withColorStudio(.wooCommercePurple, shade: .shade60)) : .gray)
                            .font(.title)
                    }
                    VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
                        if showSource {
                            Text(package.source.userFriendlyDescription)
                                .font(.caption)
                                .foregroundStyle(Color(.secondaryLabel))
                        }
                        Text(package.name)
                            .bodyStyle()
                        HStack {
                            Text(package.dimensionsDescription)
                            Text("•")
                            Text(package.weightDescription)
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color(.text))
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
}

// MARK: Popover Tip
private extension View {
    /// Shows the provided tip as a popover if the platform supports it.
    @ViewBuilder
    func popoverTipIfSupported(tip: PackageOptionTip?) -> some View {
        if #available(iOS 17.0, *), let tip {
            self.popoverTip(tip)
                .tipViewStyle(InvertedTipStyle())
        } else {
            self
        }
    }
}

// MARK: Package Option Tip
private struct PackageOptionTip: Tip {
    var title: Text

    var message: Text?

    var image: Image?

    var id: String {
        "package-option-tip"
    }

    @available(iOS 17.0, *)
    var options: [any Option] {
        // This tip will only be displayed once.
        MaxDisplayCount(1)
    }
}
