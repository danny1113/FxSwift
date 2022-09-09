//
//  main.swift
//  
//
//  Created by Danny on 2022/9/7.
//

import Foundation
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
    => decode(data:)
}


func split(lhs: String, rhs: String) -> String {
    lhs + ", " + rhs
}
func combine(lhs: String, rhs: String) -> String {
    lhs + rhs
}

let hello = Pipe("hello")
let world = Pipe("world")
let ex = Pipe("!")

let pipe = hello
    .combine(world)  // Pipe<(String, String)>
    .map(split)      // Pipe<String>
    .combine(ex)     // Pipe<(String, String)>
    .map(combine)    // Pipe<String>

// or
let pipe2 = hello + world => split  // hello, world
         + ex => combine           // hello, world!

let result: String = pipe.unwrap() // hello, world!
print(pipe == pipe2)
let semaphore = DispatchSemaphore(value: 0)

let subject = PassthroughSubject<String, Error>()

let cancellable = subject
    .compactMap(dataTaskPipe(basket:))
//    .flatMap(basketURL(_:))
//    .compactMap(basketURL(_:))
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
