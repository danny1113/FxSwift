//
//  Pipe+Publisher.swift
//  
//
//  Created by Danny on 2022/9/11.
//

#if canImport(Combine)
import Combine
#elseif canImport(OpenCombine)
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

#endif
