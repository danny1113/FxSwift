# FxSwift

FxSwift is a declarative functional programming for Swift.  
It can also interoperate with the Combine framework, bridge async await and Combine together.

> **Note**: On non-Apple platforms, FxSwift use [OpenCombine](https://github.com/OpenCombine/OpenCombine) as open source Combine framework.

## Introduction

The core of FxSwift is `Pipe`. It's a wrapper that takes a function, transform value and pass to the next chain.

```swift
@frozen
public struct Pipe<Object> {

    public init(_ object: Object)
    public init(_ closure: () throws -> Object) rethrows
    
    public func unwrap() -> Object
}
```

Main reason to use FxSwift:

- Lightweight
- Easy to use
- Runs on Linux platforms too!
- `async await` support
- Error handling with `try catch`
- Interoperate with Combine

### Example

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
    .map(comma)      // Pipe<String>
    .combine(ex)     // Pipe<(String, String)>
    .map(combine)    // Pipe<String>
```

Or you can use the convinent operator provided by Pipe:

```swift
let pipe = hello + world => comma  // hello, world
         + ex => combine           // hello, world!
```

### Operators

Pipe have 2 custom operators: `=>` and `+`.

`=>` is for passing the value to the next function.

`+` is for combining two pipes together.

### Interoperate with Combine

You can simply chain a function that returns an `AnyPublisher` to the pipe, and it will automatically transform to an async function for you.

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

let pipe: Pipe<T> = try await Pipe("http://www.example.com") // String
    => URL.init(string:)            // String => URL
    => dataTaskPublisher(for:)      // URL => Data
    => decode(data:)                // Data => T
```

You can also transform pipe to an AnyPublisher:

```swift
func toInt(string: String) throws -> Pipe<Int> {
    try Pipe(string) => Int.init
}
let subject = PassthroughSubject<String, Error>()

let cancellable = subject
    .compactMap(toInt(string:))
    // => AnyPublisher<Int, Error>
```
