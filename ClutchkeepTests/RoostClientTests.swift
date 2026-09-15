import XCTest
@testable import Clutchkeep

private struct ProbeDTO: Decodable, Sendable {
    var energy: WireNumber
}

private actor QueueTransport: RoostTransport {
    private var results: [Result<(Data, URLResponse), Error>]
    private var requests: [URLRequest] = []

    init(results: [Result<(Data, URLResponse), Error>]) {
        self.results = results
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        guard !results.isEmpty else { throw URLError(.cannotConnectToHost) }
        return try results.removeFirst().get()
    }

    func recordedRequests() -> [URLRequest] {
        requests
    }
}

final class RoostClientTests: XCTestCase {
    private let url = URL(string: "https://clutchkeep-roost.pro/probe")!

    func test_setsUserAgentOnEveryRequest() async throws {
        let transport = QueueTransport(results: [
            .success((Data("{\"energy\":1}".utf8), http(200))),
        ])
        let client = RoostClient(transport: transport)
        _ = try await client.getJSON(ProbeDTO.self, from: url)
        let request = await transport.recordedRequests().first
        XCTAssertEqual(request?.value(forHTTPHeaderField: "User-Agent"), RoostClient.userAgent)
        XCTAssertEqual(RoostClient.userAgent, "Clutchkeep/1.0 (iOS; +https://clutchkeep-roost.pro)")
        XCTAssertEqual(request?.timeoutInterval, 15)
    }

    func test_retriesTransientTransportOnce() async throws {
        let transport = QueueTransport(results: [
            .failure(URLError(.timedOut)),
            .success((Data("{\"energy\":\"4.5\"}".utf8), http(200))),
        ])
        let client = RoostClient(transport: transport)
        let dto = try await client.getJSON(ProbeDTO.self, from: url)
        XCTAssertEqual(dto.energy.value, 4.5)
        let count = await transport.recordedRequests().count
        XCTAssertEqual(count, 2)
    }

    func test_doesNotRetry404() async {
        let transport = QueueTransport(results: [
            .success((Data(), http(404))),
            .success((Data("{\"energy\":1}".utf8), http(200))),
        ])
        let client = RoostClient(transport: transport)
        do {
            _ = try await client.getJSON(ProbeDTO.self, from: url)
            XCTFail("expected notFound")
        } catch {
            XCTAssertEqual(error as? RoostWireError, .notFound)
        }
        let count = await transport.recordedRequests().count
        XCTAssertEqual(count, 1)
    }

    func test_malformedJSONIsDecodingError() async {
        let transport = QueueTransport(results: [
            .success((Data("{".utf8), http(200))),
        ])
        let client = RoostClient(transport: transport)
        do {
            _ = try await client.getJSON(ProbeDTO.self, from: url)
            XCTFail("expected decoding")
        } catch {
            XCTAssertEqual(error as? RoostWireError, .decoding)
        }
    }

    func test_wireNumberAcceptsNumberAndString() throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        let number = try decoder.decode(ProbeDTO.self, from: Data("{\"energy\":12.5}".utf8))
        let string = try decoder.decode(ProbeDTO.self, from: Data("{\"energy\":\"12.5\"}".utf8))
        let missing = try decoder.decode(ProbeDTO.self, from: Data("{\"energy\":null}".utf8))
        XCTAssertEqual(number.energy.value, 12.5)
        XCTAssertEqual(string.energy.value, 12.5)
        XCTAssertNil(missing.energy.value)
    }

    private func http(_ status: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
    }
}
