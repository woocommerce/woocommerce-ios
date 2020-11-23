
import UIKit
import WordPressAuthenticator

final class ULExceptionViewController: UIViewController {
    private let context: NavigationExceptionContext

    @IBOutlet private var primaryButton: FancyAnimatedButton!
    @IBOutlet private var secondaryButton: FancyAnimatedButton!

    init(context: NavigationExceptionContext) {
        self.context = context

        super.init(nibName: Self.nibName, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configurePrimaryButton()
        configureSecondaryButton()
    }
}


private extension ULExceptionViewController {
    func configurePrimaryButton() {
        primaryButton.setTitle(context.primaryButtontitle, for: .normal)

        primaryButton.addTarget(self, action: #selector(didTapPrimaryButton), for: .touchUpInside)
    }

    func configureSecondaryButton() {
        secondaryButton.setTitle(context.secondaryButtonTitle, for: .normal)

        secondaryButton.addTarget(self, action: #selector(didTapSecondaryButton), for: .touchUpInside)
    }

    @objc func didTapPrimaryButton() {
        context.primaryButtonAction.execute(with: navigationController)
    }

    @objc func didTapSecondaryButton() {
        context.secondaryButtonAction.execute(with: navigationController)
    }
}
