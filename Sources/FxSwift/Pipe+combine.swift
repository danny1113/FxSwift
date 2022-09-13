//
//  Pipe+combine.swift
//  
//
//  Created by Danny on 2022/9/8.
//


extension Pipe {
    
    @inlinable @inline(__always)
    static public func + <Other>(
        lhs: Self, rhs: Pipe<Other>
    ) -> Pipe<(Object, Other)> {
        .init((lhs.object, rhs.object))
    }
}

extension Pipe {
    
    /// Combine with another pipe and return a new pipe with both values in a tuple.
    @inlinable @inline(__always)
    public func combine<Other>(
        _ other: Pipe<Other>
    ) -> Pipe<(Object, Other)> {
        .init((object, other.object))
    }
    
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
