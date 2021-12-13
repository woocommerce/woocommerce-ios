# Observables

These classes are our own implementation of [ReactiveX observables](http://reactivex.io/) that we used when we were targeting iOS 12+. But now that our minimum iOS version is iOS 13, we should stop using them and use [Combine](https://developer.apple.com/documentation/combine) instead. 

We should also migrate the existing usages of these classes to use Combine. The classes were intentionally created to be compatible with both ReactiveX and Combine so the migration should be smooth-ish.
