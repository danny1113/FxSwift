
import XCTest
import FxSwift
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if canImport(Combine)
import Combine
#elseif canImport(OpenCombine)
import OpenCombineShim
#endif


final class FxSwiftTests: XCTestCase {
    
    typealias Pipe = FxSwift.Pipe
    
    func testPipeOperator() throws {
        let hello = Pipe("hello")
        let world = Pipe("world")
        let ex = Pipe("!")
        
        func split(lhs: String, rhs: String) -> String {
            lhs + ", " + rhs
        }
        
        func combine(lhs: String, rhs: String) -> String {
            lhs + rhs
        }

        let pipe = hello
            .combine(world)  // Pipe<(String, String)>
            .map(split)      // Pipe<String>
            .combine(ex)     // Pipe<(String, String)>
            .map(combine)    // Pipe<String>
        
        let pipe2 = hello + world => split(lhs:rhs:)  // hello, world
                  + ex => combine(lhs:rhs:)           // hello, world!

        XCTAssertEqual(pipe, pipe2)
    }
    
    func testJSONDecode() throws {
        struct TestModel: Decodable {
            let value: String
        }
        
        let jsonString = #"{"value": "ok"}"#
        let pipe = try Pipe(jsonString)
        => { $0.data(using: .utf8) }
        => decode(data:)
        => { (data: TestModel) -> TestModel in
            data
        }
        print(pipe)
    }

    func testOptionPipe() throws {
        XCTAssertNil(toURL(string: "https:// www.example.com").unwrap())
        XCTAssertNotNil(toURL(string: "https://www.example.com").unwrap())
    }

    
    func toURL(string: String) -> Pipe<URL?> {
        Pipe(string) =>? URL.init(string:)
    }
    
    func requestWithContentType(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    func decodeJSON(data: Data) throws -> Any {
        try JSONSerialization.jsonObject(with: data)
    }
    
    func decode<T: Decodable>(data: Data) throws -> T {
        try JSONDecoder().decode(T.self, from: data)
    }

#if canImport(Combine) || canImport(OpenCombine)

    func dataTaskPublisher(for request: URLRequest) -> AnyPublisher<Data, URLError> {
        URLSession.shared.dataTaskPublisher(for: request)
            .retry(2)
            .map(\.data)
            .eraseToAnyPublisher()
    }
    
    private var cancellable: AnyCancellable?
    
    func testCombineInteroperate() throws {
        
        let expectation = expectation(description: "Combine_Interop")
        let subject = PassthroughSubject<String, Never>()
        
        var counter = 0
        
        cancellable = subject
            .compactMap(toURL(string:))
            .sink { completion in
                switch completion {
                case .finished: return
                case .failure(let error):
                    print(error)
                }
            } receiveValue: { value in
                print(value)
                counter += 1
                if counter == 2 {
                    expectation.fulfill()
                }
            }

        subject.send("http://www.example.com")
        subject.send("http://www.example2.com ")
        subject.send("http://www.example3.com")
        wait(for: [expectation], timeout: 1)
    }

#endif

}
