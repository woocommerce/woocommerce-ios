# Localization

During development, using [`NSLocalizedString()`](https://developer.apple.com/documentation/foundation/nslocalizedstring) in the code should be enough. You shouldn't need to touch the `Localizable.strings` files manually.

During the release process, `NSLocalizedString` statements are scanned and stored in the `Localizable.strings` file. The file is then uploaded to [GlotPress](https://translate.wordpress.com/projects/woocommerce/woocommerce-ios/) for translation. Before the release build is finalized, all the translations are grabbed from GlotPress and saved back to the `Localizable.strings` files.

## Always Add Comments

Always add a meaningful comment. If possible, describe where and how the string will be used. If there are placeholders, describe what each placeholder is. 

```swift
// Do
let title = NSLocalizedString("Following %1$@",
                              comment: "Title for a notice informing the user that they've successfully followed a site. %1$@ is a placeholder for the name of the site.")
```

```swift
// Avoid
let title = NSLocalizedString("Following %@", comment: "")
```

Comments help give more context to translators.

## Always Use Positional Placeholders

Always include the positional index of parameters, even if you only have one placeholder in your string. For example, instead of using `%@` as the placeholder, use `%1$@` instead. Positional placeholders allow translators to change the order of placeholders or repeat them if necessary.

```swift
// Do
let title = NSLocalizedString(
    "%1$@ left a review on %2$@",
    comment: "Title for a product review in Notifications." +
        " The %1$@ is a placeholder for the author's name." +
        " The %2$@ is a placeholder for the product name.")
```

```swift
// Don't
let title = NSLocalizedString(
    "%@ left a review on %@",
    comment: "Title for a product review in Notifications." +
        " The first placeholder is the author's name." +
        " The second placeholder is the product name.")
```

## Do Not Use Variables

Do not use variables as the argument of `NSLocalizedString()`. The string value will not be automatically picked up. 

```swift
// Do
let myText = NSLocalizedString("This is the text I want to translate.", comment: "Put a meaningful comment here.")
myTextLabel?.text = myText
```

```swift
// Don't
let myText = "This is the text I want to translate."
myTextLabel?.text = NSLocalizedString(myText, comment: "Put a meaningful comment here.")
```

## Do Not Use Interpolated Strings

Interpolated strings are harder to understand by translators and they may end up translating/changing the variable name, causing a crash.

Use [`String.localizedStringWithFormat`](https://developer.apple.com/documentation/swift/string/1414192-localizedstringwithformat) instead.

```swift
// Do
let year = 2019
let template = NSLocalizedString("© %1$d Acme, Inc.", comment: "Copyright Notice")
let str = String.localizeStringWithFormat(template, year)
```

```swift
// Don't
let year = 2019
let str = NSLocalizedString("© \(year) Acme, Inc.", comment: "Copyright Notice")
```

## Multiline Strings

For readability, you can split the string and concatenate the parts using the plus (`+`) symbol. 

```swift
// Okay
NSLocalizedString(
    "Take some long text here " +
    "and then concatenate it using the '+' symbol."
    comment: "You can even use this form of concatenation " +
        "for extra-long comments that take the time to explain " +
        "lots of details to help our translators make accurate translations."
)
```

Do not use extended delimiters (e.g. triple quotes). They are not automatically picked up.

```swift
// Don't
NSLocalizedString(
    """Triple-quoted text, when used in NSLocalizedString, is Not OK. Our scripts break when you use this."""
    comment: """Triple-quoted text, when used in NSLocalizedString, is Not OK."""
)
```

## Pluralization

GlotPress currently does not support pluralization using the [`.stringsdict` file](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPInternational/LocalizingYourApp/LocalizingYourApp.html#//apple_ref/doc/uid/10000171i-CH5-SW10). So, right now, you have to support plurals manually by having separate localized strings.

```swift
struct PostCountLabels {
    static let singular = NSLocalizedString("%1$d Post", comment: "Number of posts displayed in Posting Activity when a day is selected. %1$d will contain the actual number (singular).")
    static let plural = NSLocalizedString("%1$d Posts", comment: "Number of posts displayed in Posting Activity when a day is selected. %1$d will contain the actual number (plural).")
}

let postCountText = (count == 1 ? PostCountLabels.singular : PostCountLabels.plural)
```

## Numbers

Localize numbers whenever possible. 

```swift
let localizedCount = NumberFormatter.localizedString(from: NSNumber(value: count), number: .none)
```
