import UIKit

/// Top-level stats v4
final class DashboardUIContainerViewController: UIViewController {
    private var dashboardUI: DashboardUI?
    private var topBannerView: TopBannerView?

    // MARK: - DashboardUI properties

    var displaySyncingErrorNotice: () -> Void = {} {
        didSet {
            dashboardUI?.displaySyncingErrorNotice = displaySyncingErrorNotice
        }
    }

    var onPullToRefresh: () -> Void = {} {
        didSet {
            dashboardUI?.onPullToRefresh = onPullToRefresh
        }
    }

    // MARK: - Private properties

    private let v3ToV4BannerActionHandler: StatsV3ToV4BannerActionHandler
    private let v4ToV3BannerActionHandler: StatsV4ToV3BannerActionHandler

    // MARK: - Subviews
    private lazy var stackView: UIStackView = {
        return UIStackView(arrangedSubviews: [])
    }()

    init(v3ToV4BannerActionHandler: StatsV3ToV4BannerActionHandler, v4ToV3BannerActionHandler: StatsV4ToV3BannerActionHandler) {
        self.v3ToV4BannerActionHandler = v3ToV4BannerActionHandler
        self.v4ToV3BannerActionHandler = v4ToV3BannerActionHandler
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureSubviews()
    }

    func showV3ToV4Banner() {
        let bannerViewModel = DashboardTopBannerFactory.v3ToV4BannerViewModel(actionHandler: {
            self?.v3ToV4BannerActionHandler.statsV4ButtonPressed()
        }, dismissHandler: {
            self?.hideBanner()
        })

        let v3ToV4Banner = TopBannerView(viewModel: bannerViewModel)
        topBannerView = v3ToV4Banner

        v3ToV4Banner.isHidden = true
        stackView.addArrangedSubview(v3ToV4Banner)
        UIView.animate(withDuration: 0.1) {
            v3ToV4Banner.isHidden = false
        }
    }

    func showV4ToV3Banner() {
    }

    func hideBanner() {

    }

    func updateDashboardUI(updatedDashboardUI: DashboardUI) {
        guard dashboardUI !== updatedDashboardUI else {
            return
        }

        if let dashboardUI = dashboardUI {
            stackView.removeArrangedSubview(dashboardUI.view)
        }

        dashboardUI = updatedDashboardUI
        add(updatedDashboardUI)
        stackView.addArrangedSubview(updatedDashboardUI.view)
        updatedDashboardUI.didMove(toParent: self)
    }
}

private extension DashboardUIContainerViewController {
    func createV3ToV4BannerViewModel() -> TopBannerViewModel {
        
    }
}

private extension DashboardUIContainerViewController {
    func configureSubviews() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        view.pinSubviewToAllEdges(stackView)
    }
}

extension DashboardUIContainerViewController: DashboardUI {

    func defaultAccountDidUpdate() {
        dashboardUI?.defaultAccountDidUpdate()
    }

    func reloadData(completion: @escaping () -> Void) {
        dashboardUI?.reloadData(completion: completion)
    }
}
