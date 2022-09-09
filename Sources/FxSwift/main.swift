//
//  main.swift
//
//
//  Created by Danny on 2022/9/7.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(Combine)
import Combine
#endif
#if canImport(OpenCombine)
import OpenCombineShim
#endif


let base = "https://getpantry.cloud/apiv1/pantry/"
let apiKey = "7e56f8f2-06de-446a-91dd-c336b6ba6b59"
let basketName = "LTE_USAGE_2022-09"


func requestWithContentType(url: URL) -> URLRequest {
    var request = URLRequest(url: url)
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    return request
}

func decodeJSON(data: Data) throws -> Any {
    try JSONSerialization.jsonObject(with: data)
}

func dataTaskPublisher(with request: URLRequest) -> AnyPublisher<Data, URLError> {
    URLSession.shared.dataTaskPublisher(for: request)
        .map(\.data)
        .eraseToAnyPublisher()
}

func composeBasketURL(_ key: String) -> (String) -> String {
    let base = "https://getpantry.cloud/apiv1/pantry/"
    return { name in
        "\(base)\(key)/basket/\(name)"
    }
}

func basketURL(_ basket: String) throws -> Pipe<URL> {
    let url = composeBasketURL(apiKey)(basket)
    return try Pipe(url) => URL.init
}

func decode<T: Decodable>(data: Data) throws -> T {
    try JSONDecoder().decode(T.self, from: data)
}

func dataTaskPipe(basket: String) async throws -> Pipe<String> {
    try await basketURL(basket)
    => requestWithContentType(url:)
    => dataTaskPublisher(with:)
    // => decode(data:)
    => { String(data: $0, encoding: .utf8 ) }
}

func dataTaskOptionalPipe(basket: String) async throws {
    let pipe: Pipe<String> = try await Pipe(basket)
    => { basket in
        composeBasketURL(apiKey)(basket)
    } =>? URL.init => { url in
        guard let url = url else {
            throw PipeError.foundNilValue(url as Any)
        }
        return dataTaskPublisher(with: URLRequest(url: url))
    } => decode(data:)
    
    print(pipe)
}

let semaphore = DispatchSemaphore(value: 0)

let subject = PassthroughSubject<String, Never>()
    
let cancellable = subject
    .compactTryMap(dataTaskPipe(basket:))
    // .compactTryMap(basketURL)
    .sink { completion in
        switch completion {
        case .finished: return
        case .failure(let error):
            print(error)
        }
    } receiveValue: { value in
        print(value)
    }

subject.send("PantryKit_Test_Basket1")
subject.send(" a")
subject.send("LTE_USAGE_2022-09")

let _ = semaphore.wait(timeout: .now() + 3)
