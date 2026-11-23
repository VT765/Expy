import Foundation

/// Minimal store-only (uncompressed) ZIP writer: enough for .xlsx packages.
struct ZipWriter {
    private var data = Data()
    private var central = Data()
    private var count: UInt16 = 0

    private static let crcTable: [UInt32] = (0..<256).map { i -> UInt32 in
        var c = UInt32(i)
        for _ in 0..<8 { c = (c & 1) != 0 ? 0xEDB8_8320 ^ (c >> 1) : c >> 1 }
        return c
    }

    static func crc32(_ d: Data) -> UInt32 {
        var c: UInt32 = 0xFFFF_FFFF
        for b in d { c = crcTable[Int((c ^ UInt32(b)) & 0xFF)] ^ (c >> 8) }
        return c ^ 0xFFFF_FFFF
    }

    mutating func add(_ path: String, _ content: String) {
        let body = Data(content.utf8)
        let name = Data(path.utf8)
        let crc = Self.crc32(body)
        let offset = UInt32(data.count)

        var local = Data()
        local.le32(0x0403_4B50); local.le16(20); local.le16(0x0800); local.le16(0) // version, UTF-8 flag, stored
        local.le16(0); local.le16(0x21) // time, date (1980-01-01)
        local.le32(crc); local.le32(UInt32(body.count)); local.le32(UInt32(body.count))
        local.le16(UInt16(name.count)); local.le16(0)
        data.append(local); data.append(name); data.append(body)

        var c = Data()
        c.le32(0x0201_4B50); c.le16(20); c.le16(20); c.le16(0x0800); c.le16(0)
        c.le16(0); c.le16(0x21)
        c.le32(crc); c.le32(UInt32(body.count)); c.le32(UInt32(body.count))
        c.le16(UInt16(name.count)); c.le16(0); c.le16(0); c.le16(0); c.le16(0); c.le32(0); c.le32(offset)
        central.append(c); central.append(name)
        count += 1
    }

    func finish() -> Data {
        var out = data
        let start = UInt32(out.count)
        out.append(central)
        var end = Data()
        end.le32(0x0605_4B50); end.le16(0); end.le16(0); end.le16(count); end.le16(count)
        end.le32(UInt32(central.count)); end.le32(start); end.le16(0)
        out.append(end)
        return out
    }
}

private extension Data {
    mutating func le16(_ v: UInt16) { Swift.withUnsafeBytes(of: v.littleEndian) { append(contentsOf: $0) } }
    mutating func le32(_ v: UInt32) { Swift.withUnsafeBytes(of: v.littleEndian) { append(contentsOf: $0) } }
}
