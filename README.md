
# FxSwift

FxSwift is a declarative functional programming package for Swift.  
It can also interoperate with the Combine framework, bridge async await and Combine together.

# Installation

```swift
dependencies: [
    // ...
    .package(url: "https://github.com/danny1113/FxSwift.git", from: "1.0.0")
]
```

# Introduction

Reason to use FxSwift:

- Lightweight
- Easy to use
- Testable
- Support Linux platforms
- `async await` support
- Error handling with `try catch`
- Interoperate with Combine*

The core of FxSwift is `Pipe`. It's a wrapper that takes a function, transform value and pass to the next chain.

```swift
@frozen
public struct Pipe<Object> {

    public init(_ object: Object)
    
    public func unwrap() -> Object
}
```

> **Note**: If you got an error `cannot specialize non-generic type 'Pipe'`, please rename Pipe to solve name collision.

```swift
typealias Pipe = FxSwift.Pipe
```

Pipe comes with various transform functions, the usage and effect are just like those in Combine:

```swift
/// Transforms all elements with a provided closure.
public func map<Result>(_ transform: @escaping (Object) -> Result) -> Pipe<Result>

/// Transforms all elements with a provided error-throwing closure.
public func tryMap<Result>(_ transform: @escaping (Object) throws -> Result) throws -> Pipe<Result>

/// Combine with another pipe and return a new pipe with both values in a tuple.
public func combine<Other>(_ other: Pipe<Other>) -> Pipe<(Object, Other)>
```

## Example

```swift
let hello = Pipe("Hello")
let world = Pipe("world")
let ex = Pipe("!")

func comma(lhs: String, rhs: String) -> String {
    lhs + ", " + rhs
}

func combine(lhs: String, rhs: String) -> String {
    lhs + rhs
}
```

That's say you want to combine three words into `"Hello, world!"` with functional programming:

```swift
let pipe = hello
    .combine(world)  // ("Hello", "world")
    .map(comma)      // "Hello, world"
    .combine(ex)     // ("Hello, world", "!")
    .map(combine)    // "Hello, world!"

let result: String = pipe.unwrap()
```

Or you can use the convenient operator provided by Pipe:

```swift
let pipe = hello
         + world     // ("Hello", "world")
        => comma     // "Hello, world"
         + ex        // ("Hello, world", "!")
        => combine   // "Hello, world!"

// or transform value inline:
let pipe = hello
    + world
    => { $0 + ", " + $1 }
    + ex
    => { $0 + $1 }
```

## Operators

Pipe have 3 custom operators: `=>`, `=>?` and `+`.

`=>` is for passing the value to the next function.

> **Note**: Using `=>` will throw if an `nil` value is produced. For passing `nil` value down to the chain, use `=>?`.

```swift
let url = try Pipe("https://www.example.com")
    => URL.init
    // will produce URL
    // throw when URL is nil
```

`=>?` is for passing an `Optional` down to the next chain.

```swift
let url = Pipe("https://www.example.com")
    =>? URL.init
    // will produce URL?
```

`+` is for combining two pipes together.

```swift
let hello = Pipe("Hello")
let world = Pipe("world")

let pipe = hello + world  // Pipe<(String, String)>
```

## Interoperate with Combine

> **Note**: Combine interoperability is currently only available on Apple platforms.

### Pipe → Publisher → Pipe

You can simply chain a function that returns an `AnyPublisher` to the pipe, and it will automatically transform to an async function for you:

```swift
func dataTaskPublisher(
    for url: URL
) -> AnyPublisher<Data, URLError> {
    URLSession.shared
        .dataTaskPublisher(for: url)
        .map(\.data)
        .eraseToAnyPublisher()
}

func decode<T: Decodable>(data: Data) throws -> T {
    try JSONDecoder().decode(T.self, from: data)
}

//             |--- T can be any type that conforms to Decodable
//             |
//             |     |--- may throw an error because URL.init(string:) and dataTaskPublisher(for:)
//             |     |
//             |     |    |--- need to await because of dataTaskPublisher(for:)
//             |     |    |
let pipe: Pipe<T> = try await Pipe("http://www.example.com")
    => URL.init(string:)          // String => URL
    => dataTaskPublisher(for:)    // URL => Data
    => decode(data:)              // Data => T
```

### Pipe → Publisher

There are several functions extends the Publisher protocol to help you transform pipe to an AnyPublisher, the usage is almost the same, except one: `compactTryMap`.  

Instead of throwing an error, `compactTryMap` use `try?` and will transform your data to nil if an error is thrown.

```swift
/// Transforms all elements with a provided closure.
public func map<Result>(_ transform: @escaping (Output) -> Pipe<Result>) -> Publishers.Map<Self, Result>

/// Calls a closure with each received element and publishes any returned optional that has a value.
public func compactMap<Result>(_ transform: @escaping (Output) -> Pipe<Result?>) -> Publishers.CompactMap<Self, Result>

/// Transforms all elements with a provided error-throwing closure.
public func tryMap<Result>(_ transform: @escaping (Output) throws -> Pipe<Result>) -> Publishers.TryMap<Self, Result>

/// Calls an error-throwing closure with each received element and publishes any returned optional that has a value.
public func tryCompactMap<Result>(_ transform: @escaping (Output) throws -> Pipe<Result?>) -> Publishers.TryCompactMap<Self, Result>

/// Calls an error-throwing closure with each received element and publishes any returned optional that has a value.
public func compactTryMap<Result>(_ transform: @escaping (Output) throws -> Pipe<Result>) -> Publishers.CompactMap<Self, Result>
```

You can also transform pipe to an AnyPublisher:

```swift
func toInt(string: String) throws -> Pipe<Int> {
    try Pipe(string) => Int.init
}

let subject = PassthroughSubject<String, Error>()

let cancellable = subject
    .tryMap(toInt(string:))
    // -> AnyPublisher<Int, Error>
    .sink { completion in
        
    } receivedValue: { (value: Int) in
        print(value)
        // receive 10
    }

subject.send("10")
```

## CustomPipeConvertible

You can conform your custom type to `CustomPipeConvertible`, and you can use the convenient function to wrap your custom data type into a pipe:

```swift
struct MyCustomType {

}

extension MyCustomType: CustomPipeConvertible { }

// and now you can just call:
let pipe: Pipe<MyCustomType> = MyCustomType().pipe()
```
