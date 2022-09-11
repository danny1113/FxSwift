# FxSwift

FxSwift is a declarative functional programming for Swift.  
It can also interoperate with the Combine framework, bridge async await and Combine together.

# Introduction

Reason to use FxSwift:

- Lightweight
- Easy to use
- Testable
- Runs on Linux too!
- `async await` support
- Error handling with `try catch`
- Interoperate with Combine

The core of FxSwift is `Pipe`. It's a wrapper that takes a function, transform value and pass to the next chain.

```swift
@frozen
public struct Pipe<Object> {

    public init(_ object: Object)
    public init(_ closure: () throws -> Object) rethrows
    
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
public func map<Result>(_ transform: @escaping (Object) throws -> Result) rethrows -> Pipe<Result>

/// Transforms all elements with a provided error-throwing closure.
public func tryMap<Result>(_ transform: @escaping (Object) throws -> Result?) throws -> Pipe<Result>

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
    .combine(world)  // Pipe<(String, String)>
    .map(comma)      // hello, world
    .combine(ex)     // Pipe<(String, String)>
    .map(combine)    // hello, world!
```

Or you can use the convenient operator provided by Pipe:

```swift
let pipe = hello + world => comma  // hello, world
         + ex => combine           // hello, world!
         
// or transform value inline:
let pipe = hello + world
    => { $0 + ", " + $1 }
    + ex => { $0 + $1 }
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

> **Note**: If you're using Linux and want to interoperate with Combine, you can add [OpenCombine](https://github.com/OpenCombine/OpenCombine) to your package dependency.

```swift
dependencies: [
    .package(url: "https://github.com/OpenCombine/OpenCombine.git", from: "0.13.0"),
    .package(url: "https://github.com/danny1113/FxSwift.git", from: "0.1.0"),
],
targets: [
    .target(
        name: "<TARGET_NAME>",
        dependencies: [
            "OpenCombine",
            .product(name: "OpenCombineFoundation", package: "OpenCombine"),
            .product(name: "OpenCombineDispatch", package: "OpenCombine"),
            .product(name: "OpenCombineShim", package: "OpenCombine"),
            "FxSwift",
        ]
    )
]
```

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
//             |          |--- need to await because of dataTaskPublisher(for:)
//             |          |
let pipe: Pipe<T> = try await Pipe("http://www.example.com")  // String
    => URL.init(string:)          // String => URL
    => dataTaskPublisher(for:)    // URL => Data
    => decode(data:)              // Data => T
```

### Pipe → Publisher

You can also transform pipe to an AnyPublisher:

```swift
func toInt(string: String) throws -> Pipe<Int> {
    try Pipe(string) => Int.init
}

let subject = PassthroughSubject<String, Error>()

let cancellable = subject
    .compactMap(toInt(string:))
    // => AnyPublisher<Int, Error>
    .sink { completion in
        
    } receivedValue: { (value: Int) in
        print(value)
        // receive 10
    }

subject.send("10")
```
