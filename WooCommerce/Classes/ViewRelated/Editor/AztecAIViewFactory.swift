import UIKit

/// Creates Jetpack AI CTAs in Aztec editor.
struct AztecAIViewFactory {
    /// Returns a view that contains a CTA for the Jetpack AI action to be shown next to the Aztec format bar.
    /// - Parameter onTap: Called when the CTA is tapped.
    /// - Returns: View that contains the Jetpack AI CTA.
    func aiButtonNextToFormatBar(onTap: @escaping () -> Void) -> UIView {
        let configuration: UIButton.Configuration = {
            var configuration = UIButton.Configuration.filled()
            configuration.image = .magicWandIcon(size: Layout.AIButton.imageSize)
            configuration.imagePadding = 0
            configuration.background.backgroundColor = .tertiaryLabel
            configuration.contentInsets = Layout.AIButton.contentInsets
            return configuration
        }()
        let button = UIButton(type: .system)
        button.accessibilityLabel = Localization.aiButtonAccessibilityLabel
        button.configuration = configuration
        button.on(.touchUpInside) { _ in
            onTap()
        }

        let containerView = UIView(frame: .zero)
        containerView.backgroundColor = .systemColor(.secondarySystemBackground)
        containerView.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: Layout.AIButton.size.width),
            button.heightAnchor.constraint(equalToConstant: Layout.AIButton.size.height),
            button.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            button.leadingAnchor.constraint(equalTo: containerView.safeLeadingAnchor, constant: Layout.AIButton.horizontalMargin),
            button.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Layout.AIButton.horizontalMargin),
            containerView.heightAnchor.constraint(equalToConstant: Layout.AIButton.containerHeight)
        ])

        let topBorder = UIView.createBorderView(height: Layout.borderWidth, color: .divider)
        let bottomBorder = UIView.createBorderView(height: Layout.borderWidth, color: .divider)
        [topBorder, bottomBorder].forEach {
            containerView.addSubview($0)
            NSLayoutConstraint.activate([
                containerView.leadingAnchor.constraint(equalTo: $0.leadingAnchor),
                containerView.trailingAnchor.constraint(equalTo: $0.trailingAnchor)
            ])
        }

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topBorder.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomBorder.bottomAnchor)
        ])

        let verticalBorder = UIView.createSeparatorView(height: Layout.AIButton.size.height,
                                                        width: Layout.borderWidth,
                                                        color: .divider)
        containerView.addSubview(verticalBorder)
        NSLayoutConstraint.activate([
            verticalBorder.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            verticalBorder.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])

        return containerView
    }
}

private extension AztecAIViewFactory {
    enum Localization {
        static let aiButtonAccessibilityLabel = NSLocalizedString(
            "Generate product description with AI",
            comment: "Accessibility label to generate product description with Jetpack AI from the Aztec editor."
        )
    }

    enum Layout {
        enum AIButton {
            static let contentInsets: NSDirectionalEdgeInsets = .init(top: 0, leading: 4, bottom: 0, trailing: 4)
            static let imageSize: CGSize = .init(width: 16, height: 20)
            static let size: CGSize = .init(width: 24, height: 24)
            static let horizontalMargin: CGFloat = 20
            static let containerHeight: CGFloat = 44
        }

        static let borderWidth: CGFloat = 1
    }
}
