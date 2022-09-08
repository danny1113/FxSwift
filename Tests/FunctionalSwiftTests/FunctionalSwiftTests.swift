
import XCTest
import FunctionalSwift
#if canImport(Combine)
import Combine
#endif
#if canImport(OpenCombine)
import OpenCombineShim
#endif


final class FunctionalSwiftTests: XCTestCase {
    
    typealias Pipe = FunctionalSwift.Pipe
    
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
    
    private var cancellable: AnyCancellable?
    
    func testCombineInteroperate() throws {
        
        let expectation = expectation(description: "Combine_Interop")
        let subject = PassthroughSubject<String, Error>()
        
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
    
    func toURL(string: String) throws -> Pipe<URL> {
        try Pipe(string) => URL.init
    }
    
    func dataTaskPipe(with url: URL) async throws -> Pipe<Any> {
        try await Pipe(url)
        => requestWithContentType(url:)
        +  dataTaskPublisher(with:)
        => decodeJSON(data:)
    }
    
    func requestWithContentType(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }
    
    func dataTaskPublisher(with request: URLRequest) -> AnyPublisher<Data, URLError> {
        URLSession.shared.dataTaskPublisher(for: request)
            .retry(2)
            .map(\.data)
            .eraseToAnyPublisher()
    }

    func decodeJSON(data: Data) throws -> Any {
        try JSONSerialization.jsonObject(with: data)
    }
}
