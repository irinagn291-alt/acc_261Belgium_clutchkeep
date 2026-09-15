import Foundation

/// Role: Hen. Local CSV of the same yard book. Atomic FileManager write. No marketplace.
enum YardSheet {
    static func sheet(from book: YardBook) -> String {
        var lines = ["kind,day,hen,role,kilograms,cost,note"]
        let names = Dictionary(uniqueKeysWithValues: book.hens.map { ($0.id, $0) })
        for hen in book.hens {
            lines.append(row(kind: "hen", day: hen.seatedDay, hen: hen.name, role: hen.role.rawValue))
        }
        for mark in book.layMarks {
            let hen = names[mark.henID]
            lines.append(row(kind: "laymark", day: mark.dayKey, hen: hen?.name ?? "", role: "layer"))
        }
        for credit in book.credits {
            let hen = names[credit.henID]
            lines.append(row(kind: "credit", day: credit.dayKey, hen: hen?.name ?? "", role: hen?.role.rawValue ?? ""))
        }
        for mash in book.mash {
            lines.append(
                row(
                    kind: "mash",
                    day: mash.dayKey,
                    kilograms: number(mash.kilograms),
                    cost: number(mash.cost)
                )
            )
        }
        for dose in book.doses {
            let hen = names[dose.henID]
            lines.append(
                row(
                    kind: "dose",
                    day: dose.dayKey,
                    hen: hen?.name ?? "",
                    role: hen?.role.rawValue ?? "",
                    note: dose.note
                )
            )
        }
        for cull in book.culls {
            let hen = names[cull.henID]
            lines.append(row(kind: "cull", day: cull.dayKey, hen: hen?.name ?? "", role: hen?.role.rawValue ?? ""))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    static func writeAtomically(_ sheet: String, to url: URL, fileManager: FileManager) throws {
        let parent = url.deletingLastPathComponent()
        try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
        guard let data = sheet.data(using: .utf8) else { return }
        try data.write(to: url, options: .atomic)
    }

    private static func row(
        kind: String,
        day: Int,
        hen: String = "",
        role: String = "",
        kilograms: String = "",
        cost: String = "",
        note: String = ""
    ) -> String {
        [kind, String(day), csv(hen), role, kilograms, cost, csv(note)].joined(separator: ",")
    }

    private static func csv(_ text: String) -> String {
        if text.contains(",") || text.contains("\"") || text.contains("\n") {
            return "\"" + text.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return text
    }

    private static func number(_ value: Double) -> String {
        formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 4
        return formatter
    }()
}
