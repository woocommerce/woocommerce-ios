import UIKit

/// Container view controller of gift card code scanner for an order.
final class GiftCardCodeScannerViewController: UIViewController {
    private lazy var codeScannerChildViewController: CodeScannerViewController = {
        return CodeScannerViewController(instructionText: Localization.instructionText,
                                         format: .text(recognitionLevel: .accurate) { [weak self] result in
            guard let self = self else { return }
            guard self.hasDetectedCode == false else {
                return
            }
            guard let code = try? result.get().first(where: {
                self.isCodeValid($0)
            }) else {
                return
            }
            self.hasDetectedCode = true
            self.onCodeScanned(code)
        })
    }()

    func isCodeValid(_ code: String) -> Bool {
        GiftCardInputViewModel.isCodeValid(code)
    }

    private let onCodeScanned: (String) -> Void

    /// Tracks whether a code has been detected because the code detection callback is only handled once.
    private var hasDetectedCode: Bool = false

    init(onCodeScanned: @escaping (String) -> Void) {
        self.onCodeScanned = onCodeScanned
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureCodeScannerChildViewController()
    }
}

private extension GiftCardCodeScannerViewController {
    func configureCodeScannerChildViewController() {
        guard let contentView = codeScannerChildViewController.view else {
            return
        }
        addChild(codeScannerChildViewController)
        view.addSubview(contentView)
        codeScannerChildViewController.didMove(toParent: self)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(contentView)
    }
}

private extension GiftCardCodeScannerViewController {
    enum Localization {
        static let instructionText = NSLocalizedString("Scan code like XXXX-XXXX-XXXX-XXXX",
                                                       comment: "The instruction text below the scan area in the barcode scanner for product SKU.")
    }
}
