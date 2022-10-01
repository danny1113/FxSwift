//
//  Publisher+Pipe.swift
//  
//
//  Created by Danny on 2022/9/8.
//

#if canImport(Combine)
import Combine
#endif


#if canImport(Combine)

extension Publisher {
    /// Transforms all elements with a provided closure.
    public func map<Result>(
        _ transform: @escaping (Output) -> Pipe<Result>
    ) -> Publishers.Map<Self, Result> {
        map { output in
            transform(output).unwrap()
        }
    }
    
    /// Transforms all elements with a provided closure.
    public func map<Result>(
        _ transform: @escaping (Output) async -> Pipe<Result>
    ) async -> Publishers.FlatMap<Future<Result, Failure>, Self> {
        flatMap { (output) -> Future<Result, Failure> in
            Future {
                await transform(output).unwrap()
            }
        }
    }
}

extension Publisher {
    /// Calls a closure with each received element and publishes any returned optional that has a value.
    public func compactMap<Result>(
        _ transform: @escaping (Output) -> Pipe<Result?>
    ) -> Publishers.CompactMap<Self, Result> {
        compactMap { output in
            transform(output).unwrap()
        }
    }
    
    /// Calls a closure with each received element and publishes any returned optional that has a value.
    public func compactMap<Result>(
        _ transform: @escaping (Output) async -> Pipe<Result?>
    ) -> Publishers.CompactMap<Publishers.FlatMap<Future<Result?, Failure>, Self>, Result> {
        flatMap { (output) -> Future<Result?, Failure> in
            Future {
                await transform(output).unwrap()
            }
        }
        .compactMap { $0 }
    }
}

extension Publisher {
    /// Transforms all elements with a provided error-throwing closure.
    public func tryMap<Result>(
        _ transform: @escaping (Output) throws -> Pipe<Result>
    ) -> Publishers.TryMap<Self, Result> {
        tryMap { output in
            try transform(output).unwrap()
        }
    }
    
    /// Transforms all elements with a provided error-throwing closure.
    public func tryMap<Result>(
        _ transform: @escaping (Output) async throws -> Pipe<Result>
    ) -> AnyPublisher<Result, Error> {
        self.mapError { $0 as Error }
            .flatMap { (output) -> Future<Result, Error> in
                Future {
                    try await transform(output).unwrap()
                }
            }
            .eraseToAnyPublisher()
    }
}

extension Publisher {
    
    /// Calls an error-throwing closure with each received element and publishes any returned optional that has a value.
    public func tryCompactMap<Result>(
        _ transform: @escaping (Output) throws -> Pipe<Result?>
    ) -> Publishers.TryCompactMap<Self, Result> {
        tryCompactMap { output in
            try transform(output).unwrap()
        }
    }
    
    /// Calls an error-throwing closure with each received element and publishes any returned optional that has a value.
    public func tryCompactMap<Result>(
        _ transform: @escaping (Output) async throws -> Pipe<Result?>
    ) -> AnyPublisher<Result, Error> {
        self.mapError { $0 as (any Error) }
            .flatMap { (output) -> Future<Result?, any Error> in
                Future {
                    try await transform(output).unwrap()
                }
            }
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
}

extension Publisher {
    
    public func compactTryMap<Result>(
        _ transform: @escaping (Output) throws -> Pipe<Result>
    ) -> Publishers.CompactMap<Self, Result> {
        compactMap { output in
            try? transform(output).unwrap()
        }
    }
    
    public func compactTryMap<Result>(
        _ transform: @escaping (Output) async throws -> Pipe<Result>
    ) -> Publishers.CompactMap<Publishers.FlatMap<Future<Result?, Failure>, Self>, Result> {
        flatMap { (output) -> Future<Result?, Failure> in
            Future {
                try? await transform(output).unwrap()
            }
        }
        .compactMap { $0 }
    }
}

extension Future {
    public convenience init(
        operation: @escaping () async -> Output
    ) {
        self.init { promise in
            Task {
                promise(.success(await operation()))
            }
        }
    }
}

extension Future where Failure == Error {
    public convenience init(
        operation: @escaping () async throws -> Output
    ) {
        self.init { promise in
            Task {
                do {
                    let output = try await operation()
                    promise(.success(output))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
}

#endif
