# UI regression evidence

Use this reference when migration changes affect geometry, presentation, animation, or visible timing. Select devices and tests from the affected readers and user flows.

## Compare screenshots

1. Identify every reader of the changed value. Identify its presentation path: sheet, full-screen cover, modal, or root content.
2. Build the requested base and changed code with separate build data. Use a separate checkout for the base to keep current edits unchanged.
3. Capture both builds on the same simulator. Match orientation, window size, locale, accessibility settings, store data, and navigation steps. Wait for animations to finish. Record any state that cannot be repeated reliably.
4. Test the device sizes and resized windows affected by the change. Use the repository verification, snapshot, and mock workflows where available.
5. Compare full-resolution images with an available image-diff tool. Inspect changed regions. Report the comparison thresholds and excluded regions. A similarity score cannot prove that excluded content is unchanged.

For timing or cancellation changes, test the interaction sequence too. A screenshot shows the final state. It cannot prove execution order or that cancelled work remains stopped.

## Repeatable setup

Prefer repository mocks or an existing test session. If authentication is necessary, use the repository auto-login workflow with test credentials. Keep credentials out of committed files and captured artifacts.

Document setup differences that affect the result. Reset only test state created for the task when necessary. Get authorization before you change store security, delete the application, or reset the keychain.

Report tested screens and configurations. Identify unexplained image differences and missing coverage. If captures cannot be repeated or matched, report the comparison as inconclusive.
