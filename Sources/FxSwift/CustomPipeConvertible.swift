//
//  CustomPipeConvertible.swift
//  
//
//  Created by Danny on 2022/9/7.
//


public protocol CustomPipeConvertible {
    associatedtype Object

    func pipe() -> Pipe<Object>
}

extension CustomPipeConvertible {

    public func pipe() -> Pipe<Self> {
        .init(self)
    }
}
