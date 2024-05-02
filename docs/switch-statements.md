# Switch Statements Guide

## Enums

When using switch statements to handle enum cases avoid handling `default` case. If we do not provide a default case and in future we add new cases, app will not build and we will immediately see where we have some API changes.

Enumerating every case requires developers and reviewers to consider the correctness of every switch statement when new cases are added in the future.

**Preferred:**

```swift
switch trafficLight {
case .greenLight:
  // Move your vehicle
case .yellowLight, .redLight:
  // Stop your vehicle
}

enum EnumExample {
    case first
    case second
    
    func exampleFunction() -> String? {
        switch self {
        case .first:
            return "first example"
        case .second:
            return "second example"
        }
    }
}
```

**Not Preferred:**

```swift

switch trafficLight {
case .greenLight:
  // Move your vehicle
default:
  // Stop your vehicle
}

enum EnumExample {
    case first
    case second
    
    func exampleFunction() -> String? {
        switch self {
        case .first:
            return "first example"
        case .second:
            return "second example"
        default:
            return nil
        }
    }
}
```

**Counterexamples:**


```swift
enum TaskState {
  case pending
  case running
  case canceling
  case success(Success)
  case failure(Error)

  // We expect that this property will remain valid if additional cases are added to the enumeration.
  public var isRunning: Bool {
    switch self {
    case .running:
      true
    default:
      false
    }
  }  
}

extension TaskState: Equatable {
  // Explicitly listing each state would be too burdensome. Ideally this function could be implemented with a well-tested macro.
  public static func == (lhs: TaskState, rhs: TaskState) -> Bool {
    switch (lhs, rhs) {
    case (.pending, .pending):
      true
    case (.running, .running):
      true
    case (.canceling, .canceling):
      true
    case (.success(let lhs), .success(let rhs)):
      lhs == rhs
    case (.failure(let lhs), .failure(let rhs)):
      lhs == rhs
    default:
      false
    }
  }
}
```

Parts of the guide are from [Airbnb guidelines](https://github.com/airbnb/swift?tab=readme-ov-file#switch-avoid-default)
