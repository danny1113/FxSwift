//
//  Pipe.swift
//
//
//  Created by Danny on 2022/9/7.
//

import Foundation
#if canImport(Combine)
import Combine
#endif
#if canImport(OpenCombine)
import OpenCombine
#endif


@frozen
public struct Pipe<Object> {

    @usableFromInline
    internal let object: Object
    
    @inlinable @inline(__always)
    public init(_ object: Object) {
        self.object = object
    }
    
    @inlinable @inline(__always)
    public init(_ closure: () throws -> Object) rethrows {
        self.object = try closure()
    }
    
    @inlinable @inline(__always)
    public func unwrap() -> Object {
        object
    }
}

infix operator =>: AdditionPrecedence


extension Pipe: CustomStringConvertible {
    public var description: String {
        return String(describing: object)
    }
}

extension Pipe: Decodable where Object: Decodable { }
extension Pipe: Encodable where Object: Encodable { }
extension Pipe: Hashable where Object: Hashable { }
extension Pipe: Equatable where Object: Equatable { }
extension Pipe: Comparable where Object: Comparable {
    public static func < (lhs: Pipe<Object>, rhs: Pipe<Object>) -> Bool {
        lhs.object < rhs.object
    }
}

extension Pipe {
    @discardableResult
    public func log(_ closure: @escaping (Object) -> Void) -> Self {
        print("----------------")
        closure(object)
        print("----------------")
        return self
    }
}

// MARK: - Pipe + map

extension Pipe {
    @inlinable @inline(__always)
    public func map<Result>(
        _ transform: @escaping (Object) throws -> Result
    ) rethrows -> Pipe<Result> {
        .init(try transform(object))
    }
    
    @inlinable @inline(__always)
    public func map<Result>(
        _ transform: @escaping (Object) async throws -> Result
    ) async rethrows -> Pipe<Result> {
        .init(try await transform(object))
    }
    
    static public func => <Result>(
        lhs: Self, rhs: @escaping (Object) throws -> Result
    ) rethrows -> Pipe<Result> {
        .init(try rhs(lhs.object))
    }
    
    static public func => <Result>(
        lhs: Self, rhs: @escaping (Object) async throws -> Result
    ) async rethrows -> Pipe<Result> {
        .init(try await rhs(lhs.object))
    }
}


// MARK: - Pipe + combine

extension Pipe {
    @inlinable @inline(__always)
    public func combine<Other>(
        _ other: Pipe<Other>
    ) -> Pipe<(Object, Other)> {
        .init((object, other.object))
    }
    
    static public func + <Other>(
        lhs: Self, rhs: Pipe<Other>
    ) -> Pipe<(Object, Other)> {
        .init((lhs.object, rhs.object))
    }
    
    // combine + transform
    
    @inlinable @inline(__always)
    public func combine<Other, T>(
        _ other: Pipe<Other>,
        _ transform: @escaping (Object, Other) throws -> T
    ) rethrows -> Pipe<T> {
        .init(try transform(object, other.object))
    }
    
    @inlinable @inline(__always)
    public func combine<Other, T>(
        _ other: Pipe<Other>,
        _ transform: @escaping (Object, Other) async throws -> T
    ) async rethrows -> Pipe<T> {
        .init(try await transform(object, other.object))
    }
}

extension Pipe {
    @inlinable @inline(__always)
    public func combine<O1, O2>(
        _ pipe1: Pipe<O1>,
        _ pipe2: Pipe<O2>
    ) -> Pipe<(Object, O1, O2)> {
        .init((object, pipe1.object, pipe2.object))
    }
    
    @inlinable @inline(__always)
    public func combine<O1, O2, T>(
        _ pipe1: Pipe<O1>,
        _ pipe2: Pipe<O2>,
        _ transform: @escaping (Object, O1, O2) throws -> T
    ) rethrows -> Pipe<T> {
        .init(try transform(object, pipe1.object, pipe2.object))
    }
    
    @inlinable @inline(__always)
    public func combine<O1, O2, T>(
        _ pipe1: Pipe<O1>,
        _ pipe2: Pipe<O2>,
        _ transform: @escaping (Object, O1, O2) async throws -> T
    ) async rethrows -> Pipe<T> {
        .init(try await transform(object, pipe1.object, pipe2.object))
    }
}


// MARK: - Pipe + compactMap
infix operator =>?: AdditionPrecedence

extension Pipe {
    @inlinable @inline(__always)
    public func compactMap<Result>(
        _ transform: @escaping (Object) -> Result?
    ) throws -> Pipe<Result> {
        guard let unwrap = transform(object) else {
            throw PipeError.foundNilValue(object)
        }
        return .init(unwrap)
    }
    
    @inlinable @inline(__always)
    public func tryCompactMap<Result>(
        _ transform: @escaping (Object) throws -> Result?
    ) throws -> Pipe<Result?> {
        return .init(try transform(object))
    }
    
    static public func => <Result>(
        lhs: Self, rhs: @escaping (Object) -> Result?
    ) -> Pipe<Result?> {
        return .init(rhs(lhs.object))
    }
    
    static public func => <Result>(
        lhs: Self, rhs: @escaping (Object) throws -> Result?
    ) throws -> Pipe<Result> {
        guard let unwrap = try rhs(lhs.object) else {
            throw PipeError.foundNilValue(lhs.object)
        }
        return .init(unwrap)
    }
}


// MARK: - Pipe + Combine

#if canImport(Combine) || canImport(OpenCombine)

// Pipe + publisher

extension Pipe {
    public func publisher() -> AnyPublisher<Object, Never> {
        Just(object)
            .eraseToAnyPublisher()
    }
}

// Pipe + combineLatest

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
    
    static public func + <T, E: Error>(
        lhs: Self,
        rhs: @escaping (Object) throws -> AnyPublisher<T, E>
    ) async throws -> Pipe<T> {
        try await lhs.combineLatest(rhs)
    }
}


extension Publisher where Failure == Never {
    
    // flatMap
    
    public func flatMap<Result>(
        _ transform: @escaping (Output) -> Pipe<Result>
    ) -> AnyPublisher<Result, Never> {
        map { output in
            transform(output).unwrap()
        }
        .eraseToAnyPublisher()
    }
    
    public func flatMap<Result>(
        _ transform: @escaping (Output) async -> Pipe<Result>
    ) -> AnyPublisher<Result, Never> {
        flatMap { output in
            Future {
                await transform(output).unwrap()
            }
        }
        .eraseToAnyPublisher()
    }
    
    // compactMap
    
    public func compactMap<Result>(
        _ transform: @escaping (Output) throws -> Pipe<Result>
    ) -> AnyPublisher<Result, Never> {
        compactMap { output in
            try? transform(output).unwrap()
        }
        .eraseToAnyPublisher()
    }
    
    public func compactMap<Result>(
        _ transform: @escaping (Output) async throws -> Pipe<Result>
    ) -> AnyPublisher<Result, Never> {
        flatMap { output in
            Future {
                try? await transform(output).unwrap()
            }
        }
        .compactMap { $0 }
        .eraseToAnyPublisher()
    }
}

extension Publisher where Failure == Error {
    
    // flatMap
    
    public func flatMap<Result>(
        _ transform: @escaping (Output) throws -> Pipe<Result>
    ) -> AnyPublisher<Result, Error> {
        tryMap { output in
            try transform(output).unwrap()
        }
        .eraseToAnyPublisher()
    }
    
    public func flatMap<Result>(
        _ transform: @escaping (Output) async throws -> Pipe<Result>
    ) -> AnyPublisher<Result, Error> {
        flatMap { output in
            Future {
                try await transform(output).unwrap()
            }
        }
        .eraseToAnyPublisher()
    }
    
    // compactMap
    
    public func compactMap<Result>(
        _ transform: @escaping (Output) throws -> Pipe<Result>
    ) -> AnyPublisher<Result, Error> {
        compactMap { output in
            try? transform(output).unwrap()
        }
        .eraseToAnyPublisher()
    }
    
    public func compactMap<Result>(
        _ transform: @escaping (Output) async throws -> Pipe<Result>
    ) -> AnyPublisher<Result, Error> {
        flatMap { output in
            Future {
                try? await transform(output).unwrap()
            }
        }
        .compactMap { $0 }
        .eraseToAnyPublisher()
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

extension Future where Failure == Never {
    public convenience init(operation: @escaping () async -> Output) {
        self.init { promise in
            Task {
                promise(.success(await operation()))
            }
        }
    }
}

#endif

precedencegroup PipePrecedence {
    associativity: left
    assignment: true
}

public enum PipeError: Error, CustomStringConvertible {
    case foundNilValue(Any)
    
    public var description: String {
        switch self {
        case .foundNilValue(let value):
            return "Found nil value when compactMap: '\(String(describing: value))'"
        }
    }
}

// MARK: - PipeConvertible
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol PipeConvertible {
    func pipe() -> Pipe<Self>
}

extension PipeConvertible {
    public func pipe() -> Pipe<Self> {
        .init(self)
    }
}

extension String: PipeConvertible { }
extension Int: PipeConvertible { }
extension URL: PipeConvertible { }
extension URLRequest: PipeConvertible { }
extension Array: PipeConvertible { }
extension Dictionary: PipeConvertible { }
extension Set: PipeConvertible { }
