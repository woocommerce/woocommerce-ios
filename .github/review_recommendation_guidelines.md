# When to request a review

Approvals are optional for internal pull requests in this repository. Authors may merge without a review, but should request one when the
change matches the guidelines below, taken from the
[experiment proposal](https://woomobilep2.wordpress.com/2026/09/02/experiment-proposal-turning-off-approval-requirement-for-prs-in-woocommerce-mobile-repository/#when-to-request-a-review).

Request a review when the change involves:

- architectural decisions or a new pattern;
- critical merchant flows, including payments, refunds, and orders;
- security, privacy, authentication, or sensitive data;
- migrations or changes with data-loss potential;
- significant cross-platform, API impact;
- large changes or changes with a wide blast radius;
- difficult testing, rollback, or recovery;

When in doubt, request a review.

These guidelines are also read by the [review recommendation workflow](workflows/claude-review-recommendation.yml), which labels every pull
request `review: recommended` or `review: optional`. Changing this file changes how pull requests are labeled.
