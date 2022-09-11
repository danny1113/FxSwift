//
//  PipeConvertible.swift
//  
//
//  Created by Danny on 2022/9/7.
//


import Foundation
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
