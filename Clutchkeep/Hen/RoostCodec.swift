import Foundation

/// Role: Hen. JSON envelope for the versioned yard book. Domain mutations never decode this themselves.
enum RoostCodec {
    static let schema = 1

    enum Fault: Error, Equatable {
        case unsupportedSchema(Int)
        case corrupt
    }

    static func encode(_ book: YardBook) throws -> Data {
        var paper = book
        paper.schemaVersion = schema
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(paper)
    }

    static func decode(_ data: Data) throws -> YardBook {
        let decoder = JSONDecoder()
        let probe: SchemaProbe
        do {
            probe = try decoder.decode(SchemaProbe.self, from: data)
        } catch {
            throw Fault.corrupt
        }
        switch probe.schemaVersion {
        case 1:
            do {
                var book = try decoder.decode(YardBook.self, from: data)
                book.schemaVersion = schema
                return book
            } catch let fault as Fault {
                throw fault
            } catch {
                throw Fault.corrupt
            }
        default:
            throw Fault.unsupportedSchema(probe.schemaVersion)
        }
    }
}

private struct SchemaProbe: Decodable {
    var schemaVersion: Int
}
