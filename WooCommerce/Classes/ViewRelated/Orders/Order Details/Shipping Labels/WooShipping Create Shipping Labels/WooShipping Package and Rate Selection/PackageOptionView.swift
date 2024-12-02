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

    /// Title for an optional tip to explain the star action.
    ///
    /// Set this title to display the tip once.
    var starTipTitle: String? = nil
    /// Optional message for the tip to explain the star action.
    var starTipMessage: String? = nil

    /// Tip to display on the star image, to explain the star action.
    private var tip: StarActionTip? {
        guard #available(iOS 17.0, *), let starTipTitle else {
            return nil
        }
        return StarActionTip(title: starTipTitle, message: starTipMessage)
    }

    var body: some View {
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
                        .popoverTipIfSupported(tip: tip)
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

// MARK: Popover Tip
private extension View {
    /// Shows the provided tip as a popover if the platform supports it.
    @ViewBuilder
    func popoverTipIfSupported(tip: StarActionTip?) -> some View {
        if #available(iOS 17.0, *), let tip {
            self.popoverTip(tip)
        } else {
            self
        }
    }
}

// MARK: Star Action Tip
private struct StarActionTip: Tip {
    var title: Text

    var message: Text?

    init(title: String,
         message: String?) {
        self.title = Text(title)
        if let message {
            self.message = Text(message)
        }
    }

    var id: String {
        "star-action-tip"
    }

    @available(iOS 17.0, *)
    var options: [any Option] {
        // This tip will only be displayed once.
        MaxDisplayCount(1)
    }
}
