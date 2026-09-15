import Foundation

/// Role: Hen. Typed transport failures. This product has no remote catalog.
enum RoostWireError: Error, Equatable, Sendable {
    case notFound
    case decoding
    case transport
    case cancelled
    case invalidResponse
}

/// Role: Hen. Sends one HTTP request. Injected so tests never hit the network.
protocol RoostTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

/// Role: Hen. URLSession-backed transport with a 15 s timeout and the app User-Agent.
struct RoostSessionTransport: RoostTransport {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        configuration.httpAdditionalHeaders = ["User-Agent": RoostClient.userAgent]
        self.session = URLSession(configuration: configuration)
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

/// Role: Hen. Accepts a JSON number or a numeric string. Missing values stay nil.
struct WireNumber: Sendable, Equatable {
    var value: Double?
}

extension WireNumber: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = nil
            return
        }
        if let number = try? container.decode(Double.self) {
            value = number
            return
        }
        if let number = try? container.decode(Int.self) {
            value = Double(number)
            return
        }
        if let text = try? container.decode(String.self) {
            value = Double(text)
            return
        }
        value = nil
    }
}

/// Role: Hen. Owns URLSession. Offline yard book; leftover catalog endpoints stay unused.
actor RoostClient {
    static let userAgent = "Clutchkeep/1.0 (iOS; +https://clutchkeep-roost.pro)"

    private let transport: any RoostTransport

    init(transport: any RoostTransport) {
        self.transport = transport
    }

    init() {
        self.transport = RoostSessionTransport()
    }

    func getJSON<DTO: Decodable & Sendable>(_ type: DTO.Type, from url: URL) async throws -> DTO {
        try Task.checkCancellation()
        let data = try await fetch(makeRequest(url: url))
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        do {
            return try decoder.decode(DTO.self, from: data)
        } catch is CancellationError {
            throw RoostWireError.cancelled
        } catch {
            throw RoostWireError.decoding
        }
    }

    private func makeRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    private func fetch(_ request: URLRequest) async throws -> Data {
        do {
            return try await send(request)
        } catch let error as RoostWireError {
            throw error
        } catch is CancellationError {
            throw RoostWireError.cancelled
        } catch {
            if isCancelled(error) {
                throw RoostWireError.cancelled
            }
            guard isTransient(error) else { throw RoostWireError.transport }
            do {
                return try await send(request)
            } catch let error as RoostWireError {
                throw error
            } catch is CancellationError {
                throw RoostWireError.cancelled
            } catch {
                if isCancelled(error) { throw RoostWireError.cancelled }
                throw RoostWireError.transport
            }
        }
    }

    private func send(_ request: URLRequest) async throws -> Data {
        try Task.checkCancellation()
        let (data, response) = try await transport.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw RoostWireError.invalidResponse
        }
        if http.statusCode == 404 {
            throw RoostWireError.notFound
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw RoostWireError.transport
        }
        return data
    }
}

private func isTransient(_ error: Error) -> Bool {
    guard let urlError = error as? URLError else { return false }
    switch urlError.code {
    case .timedOut, .networkConnectionLost, .notConnectedToInternet,
         .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
        return true
    default:
        return false
    }
}

private func isCancelled(_ error: Error) -> Bool {
    if error is CancellationError { return true }
    return (error as? URLError)?.code == .cancelled
}
