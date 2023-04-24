import UIKit

/// Displays the Login Prologue carousel, populated with `LoginProloguePageTypeViewController` pages.
///
final class LoginProloguePageViewController: UIPageViewController {

    private let pages: [UIViewController]

    private let pageControl = UIPageControl()

    init(pageTypes: [LoginProloguePageType] = LoginProloguePageType.allCases, showsSubtitle: Bool = false) {
        self.pages = pageTypes.map { LoginProloguePageTypeViewController(pageType: $0, showsSubtitle: showsSubtitle) }
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self

        if let firstPage = pages.first {
            setViewControllers([firstPage], direction: .forward, animated: false)
        }

        configureUIBasedOnPageCount()
    }

    /// Shows the next page of content if it is not on the last page.
    /// - Returns: Whether it can go to the next page, if it has not reached the last page.
    func goToNextPageIfPossible() -> Bool {
        let currentPage = pageControl.currentPage
        guard currentPage < pages.count - 1 else {
            return false
        }
        pageControl.currentPage = currentPage + 1
        setViewControllers([pages[pageControl.currentPage]], direction: .forward, animated: true)
        return true
    }
}

private extension LoginProloguePageViewController {
    func configureUIBasedOnPageCount() {
        if pages.count > 1 {
            addPageControl()
        } else {
            // Sets data source to `nil` to disable scrolling.
            dataSource = nil
        }
    }

    // MARK: Page Control Setup
    //
    func addPageControl() {
        pageControl.currentPageIndicatorTintColor = .gray(.shade5)
        pageControl.pageIndicatorTintColor = .wooCommercePurple(.shade50)
        pageControl.transform = CGAffineTransform(scaleX: Constants.pageControlScale, y: Constants.pageControlScale)

        pageControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageControl)

        NSLayoutConstraint.activate([
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: Constants.pageControlBottomMargin)
        ])

        pageControl.numberOfPages = pages.count
        pageControl.addTarget(self, action: #selector(handlePageControlValueChanged(sender:)), for: .valueChanged)
    }

    @objc func handlePageControlValueChanged(sender: UIPageControl) {
        guard let currentPage = viewControllers?.first,
              let currentIndex = pages.firstIndex(of: currentPage) else {
            return
        }

        let direction: UIPageViewController.NavigationDirection = sender.currentPage > currentIndex ? .forward : .reverse
        setViewControllers([pages[sender.currentPage]], direction: direction, animated: true)
    }
}

// MARK: - UIPageViewControllerDataSource Conformance
//
extension LoginProloguePageViewController: UIPageViewControllerDataSource {

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController),
              index > 0 else {
            return nil
        }

        return pages[index - 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController),
              index < pages.count - 1 else {
            return nil
        }

        return pages[index + 1]
    }
}

// MARK: - UIPageViewControllerDelegate Conformance
//
extension LoginProloguePageViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        guard let toVC = previousViewControllers.first,
              let index = pages.firstIndex(of: toVC) else {
            return
        }
        if !completed {
            pageControl.currentPage = index
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        guard let toVC = pendingViewControllers.first,
              let index = pages.firstIndex(of: toVC) else {
            return
        }
        pageControl.currentPage = index
    }
}

// MARK: - Constants
private extension LoginProloguePageViewController {
    enum Constants {
        static let pageControlBottomMargin: CGFloat = -10
        static let pageControlScale: CGFloat = 0.8 // Scales page control according to design
    }
}
