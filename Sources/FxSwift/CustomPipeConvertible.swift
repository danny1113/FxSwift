//
//  CustomPipeConvertible.swift
//  
//
//  Created by Danny on 2022/9/7.
//


import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif


public protocol CustomPipeConvertible {
    associatedtype Object

    func pipe() -> Pipe<Object>
}

extension CustomPipeConvertible {

    public func pipe() -> Pipe<Self> {
        .init(self)
    }
}
