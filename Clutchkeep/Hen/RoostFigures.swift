import Foundation

/// Role: Hen. Locale figures for qty, mash, costPerUnit, FCR, and healthScore. Round only at display.
enum RoostFigures {
    static func qty(_ value: Int, locale: Locale = .current) -> String {
        integer(value, locale: locale)
    }

    static func integer(_ value: Int, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: value)) ?? "—"
    }

    static func score(_ value: Double, locale: Locale = .current) -> String {
        decimal(value, fraction: 0, locale: locale)
    }

    static func kilograms(_ value: Double, locale: Locale = .current) -> String {
        decimal(value, fraction: 2, locale: locale)
    }

    static func cost(_ value: Double, locale: Locale = .current) -> String {
        decimal(value, fraction: 2, locale: locale)
    }

    static func perEgg(_ value: Double, locale: Locale = .current) -> String {
        decimal(value, fraction: 2, locale: locale)
    }

    static func ratio(_ value: Double, locale: Locale = .current) -> String {
        decimal(value, fraction: 2, locale: locale)
    }

    static func optional(_ value: Double?, style: (Double, Locale) -> String, locale: Locale = .current) -> String {
        guard let value else { return "—" }
        return style(value, locale)
    }

    static func day(_ key: Int, calendar: Calendar = .current, locale: Locale = .current) -> String {
        guard let date = RoostDay(rawValue: key).date(calendar: calendar) else { return "—" }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    static func parseKilograms(_ raw: String, locale: Locale = .current) -> Double? {
        guard let value = parseDecimal(raw, locale: locale) else { return nil }
        guard value > 0 else { return nil }
        return value
    }

    static func parseCost(_ raw: String, locale: Locale = .current) -> Double? {
        guard let value = parseDecimal(raw, locale: locale) else { return nil }
        guard value >= 0 else { return nil }
        return value
    }

    static func sanitizeDecimal(_ raw: String, locale: Locale = .current) -> String {
        let separator = locale.decimalSeparator ?? "."
        var seenSeparator = false
        var out = ""
        for character in raw {
            if character.isNumber {
                out.append(character)
            } else if String(character) == separator || character == "." || character == "," {
                guard !seenSeparator else { continue }
                seenSeparator = true
                out.append(contentsOf: separator)
            }
        }
        return out
    }

    private static func parseDecimal(_ raw: String, locale: Locale = .current) -> Double? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        guard let value = formatter.number(from: trimmed)?.doubleValue else { return nil }
        guard value.isFinite else { return nil }
        return value
    }

    private static func decimal(_ value: Double, fraction: Int, locale: Locale) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = fraction
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: value)) ?? "—"
    }
}
