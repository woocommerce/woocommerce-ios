import UIKit

/// Displays the Login Prologue carousel, populated with `LoginOnboardingPageTypeViewController` pages.
///
final class LoginOnboardingPageViewController: UIPageViewController {

    private let pages: [UIViewController]

    init(pageTypes: [LoginOnboardingPageType] = LoginOnboardingPageType.allCases, showsSubtitle: Bool = false) {
        self.pages = pageTypes.map { LoginOnboardingPageTypeViewController(pageType: $0, showsSubtitle: showsSubtitle) }
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = pages.count > 1 ? self : nil

        if let firstPage = pages.first {
            setViewControllers([firstPage], direction: .forward, animated: false)
        }
    }

    override func viewDidLayoutSubviews() {
        if let pageControl = view.subviews.first(where: { $0 is UIPageControl }) as? UIPageControl {
            configurePageControllerAppearance(pageControl: pageControl)
        }
    }

    /// Shows the next page of content if it is not on the last page.
    /// - Returns: Whether it can go to the next page, if it has not reached the last page.
    func goToNextPageIfPossible() -> Bool {
        let currentPage = dataSource?.presentationIndex?(for: self) ?? 0
        guard currentPage < pages.count - 1 else {
            return false
        }
        setViewControllers([pages[currentPage + 1]], direction: .forward, animated: true)
        return true
    }
}

private extension LoginOnboardingPageViewController {
    // MARK: Page Control Setup
    //
    func configurePageControllerAppearance(pageControl: UIPageControl) {
        pageControl.currentPageIndicatorTintColor = .accent
        pageControl.pageIndicatorTintColor = .gray(.shade10)
        pageControl.transform = CGAffineTransform(scaleX: Constants.pageControlScale, y: Constants.pageControlScale)
    }
}

// MARK: - UIPageViewControllerDataSource Conformance
//
extension LoginOnboardingPageViewController: UIPageViewControllerDataSource {

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

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        pages.count
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let currentPage = viewControllers?.first,
              let currentIndex = pages.firstIndex(of: currentPage) else {
            return 0
        }

        return currentIndex
    }
}


// MARK: - Constants
private extension LoginOnboardingPageViewController {
    enum Constants {
        static let pageControlBottomMargin: CGFloat = 0
        static let pageControlScale: CGFloat = 0.8 // Scales page control according to design
    }
}
