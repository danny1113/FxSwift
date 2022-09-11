//
//  Pipe+Publisher.swift
//  
//
//  Created by Danny on 2022/9/8.
//

#if canImport(Combine)
import Combine
#endif
#if canImport(OpenCombine)
import OpenCombine
#endif


#if canImport(Combine) || canImport(OpenCombine)

extension Pipe {
    public func publisher() -> AnyPublisher<Object, Never> {
        Just(object)
            .eraseToAnyPublisher()
    }
}

extension Pipe {
    
    public func combineLatest<T>(
        _ publisher: AnyPublisher<T, Never>
    ) async -> Pipe<T> {
        await withUnsafeContinuation { continuation in
            publisher
                .subscribe(Subscribers.Sink { _ in
                    
                } receiveValue: { value in
                    continuation.resume(returning: .init(value))
                })
        }
    }
    
    public func combineLatest<T, E: Error>(
        _ publisher: AnyPublisher<T, E>
    ) async throws -> Pipe<T> {
        try await withUnsafeThrowingContinuation { continuation in
            publisher
                .subscribe(Subscribers.Sink { completion in
                    switch completion {
                    case .finished:
                        return
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                } receiveValue: { value in
                    continuation.resume(returning: .init(value))
                })
        }
    }
    
    public func combineLatest<T>(
        _ transform: @escaping (Object) -> AnyPublisher<T, Never>
    ) async -> Pipe<T> {
        await withUnsafeContinuation { continuation in
            transform(object)
                .subscribe(Subscribers.Sink { _ in
                    
                } receiveValue: { value in
                    continuation.resume(returning: .init(value))
                })
        }
    }
    
    public func combineLatest<T, E: Error>(
        _ transform: @escaping (Object) throws -> AnyPublisher<T, E>
    ) async throws -> Pipe<T> {
        try await withUnsafeThrowingContinuation { continuation in
            let publisher: AnyPublisher<T, E>
            do {
                publisher = try transform(object)
            } catch {
                continuation.resume(throwing: error)
                return
            }
            
            publisher
                .subscribe(Subscribers.Sink { completion in
                    switch completion {
                    case .finished:
                        return
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                } receiveValue: { value in
                    continuation.resume(returning: .init(value))
                })
        }
    }
    
    static public func => <T, E: Error>(
        lhs: Self,
        rhs: @escaping (Object) throws -> AnyPublisher<T, E>
    ) async throws -> Pipe<T> {
        try await lhs.combineLatest(rhs)
    }
}


extension Publisher {
    public func map<Result>(
        _ transform: @escaping (Output) -> Pipe<Result>
    ) -> Publishers.Map<Self, Result> {
        map { output in
            transform(output).unwrap()
        }
    }
    
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
    
    public func compactMap<Result>(
        _ transform: @escaping (Output) -> Pipe<Result?>
    ) -> Publishers.CompactMap<Self, Result> {
        compactMap { output in
            transform(output).unwrap()
        }
    }
    
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
    
    public func tryMap<Result>(
        _ transform: @escaping (Output) throws -> Pipe<Result>
    ) -> Publishers.TryMap<Self, Result> {
        tryMap { output in
            try transform(output).unwrap()
        }
    }
    
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
    
    public func tryCompactMap<Result>(
        _ transform: @escaping (Output) throws -> Pipe<Result?>
    ) -> Publishers.TryCompactMap<Self, Result> {
        tryCompactMap { output in
            try transform(output).unwrap()
        }
    }
    
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
