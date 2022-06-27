# Hot Reloading using Inject

In the app, we implemented an optional hot reloading functionality to speed up the development process.

From an interesting [article](https://merowing.info/2022/04/hot-reloading-in-swift/) of Krzysztof Zabłocki:
> Hot reloading is about getting rid of compiling your whole application and avoiding deploy/restart cycles as much as possible while allowing you to edit your running application code and see changes reflected immediately.
> 
> This process improvement can save you literally hours of development time, each day. I tracked my work for over a month, and for me, it was between 1-2h each day.

I found too that the hot reloading functionality is an incredible time saver, since I don't have to recompile the entire app to see a change. Indeed, I can even modify the logic within a view model to immediately see the graphic or logical implications behind a specific change.

## Inject
For implementing the hot reloading functionality, we used [Inject](https://github.com/krzysztofzablocki/Inject), an open source library under MIT license that allow us with one or two lines of codes to enable the hot reloading functionality with `UIKit` or `SwiftUI`.

The library is imported using SPM.

## Setup
For enabling the hot reload, there is a small individual developer setup that you should follow on your machine.

1) Download the newest version of **Xcode Injection** app from its [GitHub page](https://github.com/johnno1962/InjectionIII/releases) or from the [Mac App Store](https://apps.apple.com/app/injectioniii/id1380446739?mt=12) and install it.

2) Unpack it and place it under `/Applications`.

3) Make sure that the Xcode version you are using to compile our projects is under the default location: `/Applications/Xcode.app`. This is super important, unfortunately, Xcode Injection doesn't work if your Xcode is not under this path or it's called with a different name.

4) Run the injection application.

5) From the injection application in the menu bar, select "open project" from its menu and pick the right workspace file you are using.

6) Launch the WCiOS app from Xcode. If everything works properly, you should see in the console log something similar:
```
💉 InjectionIII connected /Users/youruserpath/woocommerce-ios/WooCommerce/WooCommerce.xcodeproj
💉 Watching files under /Users/youruserpath/woocommerce-ios/WooCommerce
```

## Enable hot reload in SwiftUI

Just 2 steps to enable injection in your SwiftUI Views

- Add `@ObservedObject private var iO = Inject.observer` to your view struct.
- Call `.enableInjection()` at the end of your body definition.

**Remember you don't need to remove this code when you are done, it's NO-OP in production builds.**
** Keep also in mind that if you try to add the injection in a view while the app is running, you will experience a crash **


## Enable hot reload in UIKit / AppKit

The situation here is a little bit more complex, but still feasable.

If you are initializing and assigning a view or a view controller, just wrap it inside `Inject.ViewHost` or `Inject.ViewControllerHost`.

Case for a view:
```
paneA = Inject.ViewHost(
  PaneAView(whatever: arguments, you: want)
)
```

Case for a view controller:
```
let viewController = Inject.ViewControllerHost(YourViewController())
rootViewController.pushViewController(viewController, animated: true)
```

**Remember you don't need to remove this code when you are done, it's NO-OP in production builds.**
** Keep also in mind that if you try to add the injection in a view while the app is running, you will experience a crash **


## Questions

#### Why not use Playground?
While Apple has made great strides with [Playground](https://www.apple.com/swift/playgrounds/), it is not an environment born for large projects. You can only test small pieces of code in Playground, and it's not ideal for our app. Playground was born as an environment for experimenting, and is more useful for learning.

#### Why not use SwiftUI preview?
There are several reasons. I'd like to test everything in SwiftUI preview, but the preview functionality of SwiftUI is still broken and slow 🐌

If you need to test something fast, with real data, maybe in multiple flows, it's not the ideal solution. It's useful for small components (like a table row) but not too much useful for entire views or flows.
Using hot reloading, allow us to have a faster workflow, and you don't need to restart the app in the simulator every time, which save you a lot of time.


## Tips

- If a view embedded in a `UIHostingController` is not refreshing properly, it's because you should wrap the view controller under `Inject.ViewControllerHost`.
