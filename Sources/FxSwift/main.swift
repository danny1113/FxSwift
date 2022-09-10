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

func dataTaskPublisher(for request: URLRequest) -> AnyPublisher<Data, URLError> {
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

func dataTaskPipe(basket: String) async throws -> Pipe<String> {
    try await Pipe(basket)
    => composeBasketURL(apiKey)
    => URL.init(string:)
    => requestWithContentType(url:)
    => dataTaskPublisher(for:)
    => { String(data: $0, encoding: .utf8) }
}

let pipe = try await dataTaskPipe(basket: basketName)
+ dataTaskPipe(basket: "PantryKit_Test_Basket1")
=> { $0 + "\n" + $1 }

print(pipe.unwrap())


let semaphore = DispatchSemaphore(value: 0)

let subject = PassthroughSubject<String, Never>()

let cancellable = subject
    .compactTryMap(dataTaskPipe(basket:))
    .map { $0 }
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
