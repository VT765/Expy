import Foundation

/// Minimal .xlsx reader: first worksheet as a string table.
enum XLSXReader {
    static func firstSheet(_ data: Data) throws -> [[String]] {
        let files = try unzip(data)
        let shared = files["xl/sharedStrings.xml"].map(SharedStringsParser.parse) ?? []
        guard let sheet = files.keys.filter({ $0.hasPrefix("xl/worksheets/sheet") }).sorted().first.flatMap({ files[$0] }) else {
            throw StatementError(message: "That Excel file has no worksheet.")
        }
        return SheetParser.parse(sheet, shared: shared)
    }

    private static func unzip(_ data: Data) throws -> [String: Data] {
        let b = [UInt8](data)
        func u16(_ o: Int) -> Int { Int(b[o]) | Int(b[o + 1]) << 8 }
        func u32(_ o: Int) -> Int { u16(o) | u16(o + 2) << 16 }
        guard let eocd = stride(from: b.count - 22, through: max(0, b.count - 65_557), by: -1).first(where: { u32($0) == 0x0605_4B50 }) else {
            throw StatementError(message: "That doesn't look like an .xlsx file.")
        }
        var out: [String: Data] = [:]
        var p = u32(eocd + 16)
        for _ in 0..<u16(eocd + 10) {
            guard u32(p) == 0x0201_4B50 else { break }
            let method = u16(p + 10), csize = u32(p + 20), nameLen = u16(p + 28), extra = u16(p + 30), comment = u16(p + 32), local = u32(p + 42)
            let name = String(decoding: b[(p + 46)..<(p + 46 + nameLen)], as: UTF8.self)
            p += 46 + nameLen + extra + comment
            guard name.hasSuffix(".xml") else { continue }
            let start = local + 30 + u16(local + 26) + u16(local + 28)
            let raw = Data(b[start..<(start + csize)])
            if method == 0 { out[name] = raw }
            else if method == 8, let inflated = try? (raw as NSData).decompressed(using: .zlib) as Data { out[name] = inflated }
        }
        return out
    }

    private final class SharedStringsParser: NSObject, XMLParserDelegate {
        var strings: [String] = []
        var current = ""
        var inText = false
        static func parse(_ d: Data) -> [String] {
            let p = SharedStringsParser()
            let x = XMLParser(data: d)
            x.delegate = p
            x.parse()
            return p.strings
        }
        func parser(_ parser: XMLParser, didStartElement e: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String] = [:]) {
            if e == "si" { current = "" }
            if e == "t" { inText = true }
        }
        func parser(_ parser: XMLParser, foundCharacters s: String) { if inText { current += s } }
        func parser(_ parser: XMLParser, didEndElement e: String, namespaceURI: String?, qualifiedName: String?) {
            if e == "t" { inText = false }
            if e == "si" { strings.append(current) }
        }
    }

    private final class SheetParser: NSObject, XMLParserDelegate {
        var rows: [[String]] = []
        var row: [Int: String] = [:]
        var col = 0
        var type = ""
        var value = ""
        var capture = false
        var shared: [String] = []

        static func parse(_ d: Data, shared: [String]) -> [[String]] {
            let p = SheetParser()
            p.shared = shared
            let x = XMLParser(data: d)
            x.delegate = p
            x.parse()
            return p.rows
        }

        func parser(_ parser: XMLParser, didStartElement e: String, namespaceURI: String?, qualifiedName: String?, attributes a: [String: String] = [:]) {
            switch e {
            case "row": row = [:]
            case "c":
                type = a["t"] ?? ""
                value = ""
                let letters = (a["r"] ?? "").prefix { $0.isLetter }
                col = letters.reduce(0) { $0 * 26 + Int($1.asciiValue! - 64) } - 1
            case "v", "t": capture = true
            default: break
            }
        }
        func parser(_ parser: XMLParser, foundCharacters s: String) { if capture { value += s } }
        func parser(_ parser: XMLParser, didEndElement e: String, namespaceURI: String?, qualifiedName: String?) {
            switch e {
            case "v", "t": capture = false
            case "c": row[max(0, col)] = type == "s" ? (Int(value).flatMap { $0 < shared.count ? shared[$0] : nil } ?? "") : value
            case "row":
                let width = (row.keys.max() ?? -1) + 1
                rows.append((0..<width).map { row[$0] ?? "" })
            default: break
            }
        }
    }
}
