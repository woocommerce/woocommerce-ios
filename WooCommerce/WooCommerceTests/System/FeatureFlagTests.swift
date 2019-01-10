import XCTest
@testable import WooCommerce

class FeatureFlagTests: XCTestCase {

    /// App review prompt is enabled for dev builds
    ///
    func testFeatureFlagForAppReviewPromptIsEnabledForLocalDeveloperBuildConfiguration() {
        BuildConfiguration.localDeveloper.test {
            let actualValue = FeatureFlag.appReviewPrompt.enabled
            XCTAssertTrue(actualValue, "App Review Prompt should be enabled for .localDeveloper BuildConfiguration")
        }
    }

    /// App review prompt is disabled for app store builds
    ///
    func testFeatureFlagForAppReviewPromptIsDisabledForAppStoreBuildConfiguration() {
        BuildConfiguration.appStore.test {
            let actualValue = FeatureFlag.appReviewPrompt.enabled
            XCTAssertFalse(actualValue, "App Review Prompt should be disabled for .appStore BuildConfiguration")
        }
    }
}

