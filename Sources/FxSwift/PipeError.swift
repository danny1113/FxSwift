//
//  PipeError.swift
//  
//
//  Created by Danny on 2022/9/7.
//


public enum PipeError: Error, CustomStringConvertible {
    case foundNilValue(Any)
    
    public var description: String {
        switch self {
        case .foundNilValue(let value):
            return "Found nil value when compactMap: '\(String(describing: value))'"
        }
    }
}
