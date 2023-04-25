import UIKit

/// Creates Jetpack AI CTAs in Aztec editor.
struct AztecAIViewFactory {
    /// Returns a view that contains a CTA for the Jetpack AI action to be shown next to the Aztec format bar.
    /// - Parameter onTap: Called when the CTA is tapped.
    /// - Returns: View that contains the Jetpack AI CTA.
    func aiButtonNextToFormatBar(onTap: @escaping () -> Void) -> UIView {
        let configuration: UIButton.Configuration = {
            var configuration = UIButton.Configuration.filled()
            configuration.image = .magicWandIcon(size: .init(width: 16, height: 20))
            configuration.imagePadding = 0
            configuration.background.backgroundColor = .tertiaryLabel
            configuration.contentInsets = .init(
                top: 0,
                leading: 4,
                bottom: 0,
                trailing: 4
            )
            return configuration
        }()
        let button = UIButton(type: .system)
        button.accessibilityLabel = NSLocalizedString(
            "Generate product description with AI",
            comment: "Accessibility label to generate product description with Jetpack AI from the Aztec editor."
        )
        button.configuration = configuration
        button.on(.touchUpInside) { _ in
            onTap()
        }

        let containerView = UIView(frame: .zero)
        containerView.backgroundColor = .systemColor(.secondarySystemBackground)
        containerView.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 24),
            button.heightAnchor.constraint(equalToConstant: 24),
            button.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            button.leadingAnchor.constraint(equalTo: containerView.safeLeadingAnchor, constant: 20),
            button.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            containerView.heightAnchor.constraint(equalToConstant: 44)
        ])

        let topBorder = UIView.createBorderView(height: 1, color: .divider)
        let bottomBorder = UIView.createBorderView(height: 1, color: .divider)
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

        let verticalBorder = UIView.createSeparatorView(height: 24,
                                                        width: 1,
                                                        color: .divider)
        containerView.addSubview(verticalBorder)
        NSLayoutConstraint.activate([
            verticalBorder.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            verticalBorder.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])

        return containerView
    }
}
