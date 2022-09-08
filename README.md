# FunctionalSwift

FunctionalSwift declarative functional programming for Swift.  
It also can interoperate with the Combine framework, bridge async await and Combine together.

> **Note**: On non-Apple platforms, FunctionalSwift use [OpenCombine](https://github.com/OpenCombine/OpenCombine) as open source Combine framework.

## Introduction

The core of FunctionalSwift is `Pipe`. It's a wrapper that takes a function, transform value and pass to the next chain.

```swift
@frozen
public struct Pipe<Object> {

    public init<T>(_ object: Object)
    public init(_ closure: () throws -> Object) rethrows
    
    public func unwrap() -> Object
}
```

### Example

```swift
let hello = Pipe("Hello")
let world = Pipe("world")
let ex = Pipe("!")

func split(lhs: String, rhs: String) -> String {
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
    .map(split)      // Pipe<String>
    .combine(ex)     // Pipe<(String, String)>
    .map(combine)    // Pipe<String>
```

Or you can use the convinent operator provided by Pipe:

```swift
let pipe = hello + world => split  // hello, world
         + ex => combine           // hello, world!
```

### Operators

Pipe have 2 custom operators: `=>` and `+`.

`=>` is for 

`+` is for combining pipe or Combine's Publisher to the pipe on the left hand side.
