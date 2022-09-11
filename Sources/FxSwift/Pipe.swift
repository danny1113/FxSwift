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
    public func unwrap() -> Object {
        object
    }
}

infix operator =>: AdditionPrecedence
infix operator =>?: AdditionPrecedence


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
    
    /// Transforms all elements with a provided closure.
    @inlinable @inline(__always)
    public func map<Result>(
        _ transform: @escaping (Object) throws -> Result
    ) rethrows -> Pipe<Result> {
        .init(try transform(object))
    }
    
    /// Transforms all elements with a provided closure.
    @inlinable @inline(__always)
    public func map<Result>(
        _ transform: @escaping (Object) async throws -> Result
    ) async rethrows -> Pipe<Result> {
        .init(try await transform(object))
    }
    
    /// Transforms all elements with a provided error-throwing closure.
    @inlinable @inline(__always)
    public func tryMap<Result>(
        _ transform: @escaping (Object) throws -> Result
    ) throws -> Pipe<Result> {
        .init(try transform(object))
    }
    
    /// Transforms all elements with a provided error-throwing closure.
    @inlinable @inline(__always)
    public func tryMap<Result>(
        _ transform: @escaping (Object) async throws -> Result
    ) async throws -> Pipe<Result> {
        .init(try await transform(object))
    }
    
    /// Transforms all elements with a provided error-throwing closure.
    @inlinable @inline(__always)
    public func tryMap<Result>(
        _ transform: @escaping (Object) throws -> Result?
    ) throws -> Pipe<Result> {
        guard let unwrap = try transform(object) else {
            throw PipeError.foundNilValue(object)
        }
        return .init(unwrap)
    }
    
    /// Transforms all elements with a provided error-throwing closure.
    @inlinable @inline(__always)
    public func tryMap<Result>(
        _ transform: @escaping (Object) async throws -> Result?
    ) async throws -> Pipe<Result> {
        guard let unwrap = try await transform(object) else {
            throw PipeError.foundNilValue(object)
        }
        return .init(unwrap)
    }
    
    /// Transforms all elements with a provided error-throwing closure.
    @inlinable @inline(__always)
    static public func => <Result>(
        lhs: Self, rhs: @escaping (Object) throws -> Result
    ) rethrows -> Pipe<Result> {
        .init(try rhs(lhs.object))
    }
    
    /// Transforms all elements with a provided error-throwing closure.
    @inlinable @inline(__always)
    static public func => <Result>(
        lhs: Self, rhs: @escaping (Object) async throws -> Result
    ) async rethrows -> Pipe<Result> {
        .init(try await rhs(lhs.object))
    }
    
    /// Transforms all elements with a provided error-throwing closure.
    /// > Note: This operator will throw if an `nil` value is produced. For passing `nil` value down to the chain, use `=>?`.
    @inlinable @inline(__always)
    static public func => <Result>(
        lhs: Self, rhs: @escaping (Object) throws -> Result?
    ) throws -> Pipe<Result> {
        guard let unwrap = try rhs(lhs.object) else {
            throw PipeError.foundNilValue(lhs.object)
        }
        return .init(unwrap)
    }
    
    /// Transforms all elements with a provided error-throwing closure.
    /// > Note: This operator will throw if an `nil` value is produced. For passing `nil` value down to the chain, use `=>?`.
    @inlinable @inline(__always)
    static public func => <Result>(
        lhs: Self, rhs: @escaping (Object) async throws -> Result?
    ) async throws -> Pipe<Result> {
        guard let unwrap = try await rhs(lhs.object) else {
            throw PipeError.foundNilValue(lhs.object)
        }
        return .init(unwrap)
    }
    
    @inlinable @inline(__always)
    static public func =>? <Result>(
        lhs: Self, rhs: @escaping (Object) -> Result?
    ) -> Pipe<Result?> {
        .init(rhs(lhs.object))
    }
    
    @inlinable @inline(__always)
    static public func =>? <Result>(
        lhs: Self, rhs: @escaping (Object) async -> Result?
    ) async -> Pipe<Result?> {
        .init(await rhs(lhs.object))
    }
}


precedencegroup PipePrecedence {
    associativity: left
    assignment: true
}
