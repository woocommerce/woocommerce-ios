# Issue Triage
**Triage** is the process of reviewing and labeling incoming issues, identifying any which are critical, and escalating the critical ones.

## Why We Triage
Triage sets us up for success, improves developer experience, and raises quality faster by prioritizing impactful issues. When all issues in a repository are regularly labeled, tested, and reviewed it makes it easy to know exactly where to see the highest needs to improve user experience. High quality bug reports in an organized and prioritized repository makes it easier to start working on maintenance and, in turn, helps us close the loop on user feedback.

## Labels
All issues should have a label for the general area of the app it corresponds to (a `category` or `feature` label) and what type of issue it is (a `type` label, e.g. `type: bug` or `type: enhancement`).

Useful links to find issues that need labels:

* [Unlabeled issues](https://github.com/woocommerce/woocommerce-ios/issues?utf8=%E2%9C%93&q=is%3Aissue%20is%3Aopen%20no%3Alabel)
* [Issues with no Type label](https://github.com/woocommerce/woocommerce-ios/issues?q=is%3Aopen+is%3Aissue+-label%3A%22type%3A+bug%22+-label%3A%22type%3A+crash%22+-label%3A%22type%3A+documentation%22+-label%3A%22type%3A+enhancement%22+-label%3A%22type%3A+question%22+-label%3A%22type%3A+task%22+-label%3A%22type%3A+technical+debt%22)

## Prioritization
Bug and crash reports (issues with the  `type: bug` or `type: crash` labels) should be prioritized and assigned a `priority` label. The exception is medium priority issues; any issue without a `priority` label is considered medium priority.

Priority is assigned based on severity and impact:

| |**Low Severity**|**Medium Severity**|**High Severity**|**Critical Severity**|
|-|-|-|-|-|
|**Low Impact**|Low|Low|Medium|High|
|**Medium Impact**|Low|Medium|High|Critical|
|**High Impact**|Medium|High|Critical|Critical|

### Severity

Severity is determined by what functionality is affected and how broken it is:

* **Low:** Visual issue or edge case (doesn’t affect core/default functionality)
* **Medium:** Bug with a workaround, low priority feature is broken/non-functional, visual issue in login/signup (first impressions)
* **High**: High priority flow or feature is broken/non-functional, crash. High priority areas: login, order fulfillment, notifications, payments
* **Critical:** Critical impact on data or site: data loss (orders, reviews), unable to operate store (e.g. collect orders), security issues

### Impact

Impact is determined by how many users are affected or how many reports we receive:

* **Low:** Non-reproducible or single user report, or estimated 0-5% of users affected.
* **Medium:** 2-4 user reports, or estimated 6-25% of users affected.
* **High:** 5+ user reports, or estimated 26-100% of users affected.

If you aren't sure how to estimate the number of users affected, use the number of user reports you can find as a starting point. The issue can be escalated later if we find a good estimate of users affected or if more user reports are noted on the issue.

### Special Cases

In addition to the guidelines above, we have specific criteria for prioritizing certain types of issues in a new production or beta release:

* A new crash affecting more than 0.2% of users once the rollout of a production release is completed requires a hotfix. Some considerations here:
   * If the crash leaves the user in an unrecoverable situation, that’s a breaking incident. All hands on deck until we push a fix.
   * If the user can recover, we need to find the developer(s) that have the highest chance of success and redirect them to the issue.
* All new crashes in a beta release should be fixed on the frozen branch (i.e. "Critical" priority) if they are actionable.
* Issues with Tracks events should be fixed as soon as they are discovered. We rely on Tracks to evaluate whether a project was a success or not, or if we should keep iterating on it, so it’s extremely important that all our events are accurate. When to hotfix or target the frozen branch will be determined on a case by case basis.

### Note on prioritization

The matrix and criteria outline above are meant as a guideline, to avoid having to rely solely on "gut instinct" when prioritizing issues. However, there will likely be exceptions or cases that are unclear. Trust your instincts if an issue seems to be higher priority than the matrix gives it!

You can also always reach out for help prioritizing or escalating issues: Contributors are welcome to get in touch in the `#mobile-apps` channel on the [WooCommerce Community Slack](https://woocommerce.com/community-slack/), and WooCommerce team members can reach out to the WooCommerce Mobile lead, team leads, or quality lead for help.
