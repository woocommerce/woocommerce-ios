import FloatingPanel
import UIKit
import Yosemite

final class ProductStockScannerViewController: UIViewController {

    private lazy var barcodeScannerChildViewController : BarcodeScannerViewController = {
        return BarcodeScannerViewController { [weak self] (barcodes, error) in
            guard let barcode = barcodes.first else {
                return
            }
            self?.searchProductBySKU(barcode: barcode)
        }
    }()

    private lazy var resultsNavigationController: InventoryScannerResultsNavigationController = {
        return InventoryScannerResultsNavigationController { [weak self] in
            self?.cancelButtonTapped()
        }
    }()

    private lazy var floatingPanelController: FloatingPanelController = {
        let fpc = FloatingPanelController(delegate: nil)
        fpc.set(contentViewController: resultsNavigationController)
        fpc.surfaceView.cornerRadius = 9.0
        fpc.surfaceView.grabberTopPadding = -12.0
        return fpc
    }()

    private var areSearchResultsPresented: Bool = false

    private lazy var keyboardFrameObserver: KeyboardFrameObserver = {
        let keyboardFrameObserver = KeyboardFrameObserver(onKeyboardFrameUpdate: { [weak self] keyboardFrame in
            if keyboardFrame.height > 0 {
                self?.floatingPanelController.move(to: .full, animated: true)
            } else {
                self?.floatingPanelController.move(to: .half, animated: true)
            }
        })
        return keyboardFrameObserver
    }()

    private lazy var throttler: Throttler = Throttler(seconds: 1)

    private let siteID: Int64

    init(siteID: Int64) {
        self.siteID = siteID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .basicBackground
        keyboardFrameObserver.startObservingKeyboardFrame()
        configureNavigation()
        configureBarcodeScannerChildViewController()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // TODO-jc: remove. this is just for testing
        searchProductBySKU(barcode: "9789863210887")
    }
}

// MARK: Search
//
private extension ProductStockScannerViewController {
    func searchProductBySKU(barcode: String) {
        DispatchQueue.main.async {
            let action = ProductAction.searchProductBySKU(siteID: self.siteID, sku: barcode) { [weak self] result in
                guard let self = self else {
                    return
                }
                switch result {
                case .success(let product):
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)

                    self.presentSearchResults()
                    self.resultsNavigationController.productScanned(product: product)
                case .failure(let error):
                    print("No product matched: \(error)")
                }
            }
            ServiceLocator.stores.dispatch(action)
        }
    }

    func presentSearchResults() {
        guard areSearchResultsPresented == false else {
            switch traitCollection.verticalSizeClass {
            case .compact:
                floatingPanelController.move(to: .tip, animated: true)
            case .regular:
                floatingPanelController.move(to: .half, animated: true)
            default:
                break
            }
            return
        }

        present(floatingPanelController, animated: true, completion: nil)
        areSearchResultsPresented = true
    }
}

// MARK: Navigation
//
private extension ProductStockScannerViewController {
    @objc func cancelButtonTapped() {
        if areSearchResultsPresented {
            resultsNavigationController.dismiss(animated: true) {
                self.dismiss(animated: true, completion: nil)
            }
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
}

private extension ProductStockScannerViewController {
    func configureNavigation() {
        title = NSLocalizedString("Inventory scanner", comment: "")

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
    }

    func configureBarcodeScannerChildViewController() {
        let contentView = barcodeScannerChildViewController.view!
        addChild(barcodeScannerChildViewController)
        view.addSubview(contentView)
        barcodeScannerChildViewController.didMove(toParent: self)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(contentView)
    }
}
