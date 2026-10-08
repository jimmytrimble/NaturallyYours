import Foundation

/// Parses and serializes product data in the Shopify product-export CSV format,
/// which is what the Naturally Yours store exports. Handles quoted fields that
/// contain commas, embedded quotes, and newlines (multiline HTML bodies), and
/// groups the multiple rows that Shopify emits per product (one per image/variant).
enum ProductCSVService {

    /// A product parsed from the CSV, ready to be upserted into the database.
    struct ParsedProduct {
        var handle: String
        var name: String
        var description: String
        var price: Double
        var salePrice: Double?
        var category: String
        var stockQuantity: Int
        var isActive: Bool
        var imageURLs: [String]
        var sku: String?
        var tags: [String]
    }

    // MARK: - Import

    /// Parses a Shopify-format CSV string into grouped products.
    static func parse(csv: String) -> [ParsedProduct] {
        let rows = parseRows(csv)
        guard let header = rows.first else { return [] }

        // Map header name -> column index (trim whitespace/BOM).
        var columnIndex: [String: Int] = [:]
        for (i, raw) in header.enumerated() {
            columnIndex[raw.trimmingCharacters(in: .whitespacesAndNewlines)] = i
        }

        func value(_ row: [String], _ column: String) -> String {
            guard let idx = columnIndex[column], idx < row.count else { return "" }
            return row[idx].trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Group data rows by Handle, preserving order.
        var order: [String] = []
        var grouped: [String: [[String]]] = [:]
        for row in rows.dropFirst() {
            let handle = value(row, "Handle")
            guard !handle.isEmpty else { continue }
            if grouped[handle] == nil {
                grouped[handle] = []
                order.append(handle)
            }
            grouped[handle]?.append(row)
        }

        var products: [ParsedProduct] = []
        for handle in order {
            guard let group = grouped[handle] else { continue }
            // The "main" row is the first one that carries a Title.
            guard let main = group.first(where: { !value($0, "Title").isEmpty }) else { continue }

            // Collect images across all rows, ordered by "Image Position".
            let images: [String] = group
                .compactMap { row -> (Int, String)? in
                    let src = value(row, "Image Src")
                    guard !src.isEmpty else { return nil }
                    let pos = Int(value(row, "Image Position")) ?? Int.max
                    return (pos, src)
                }
                .sorted { $0.0 < $1.0 }
                .map { $0.1 }
            // De-duplicate while preserving order.
            var seen = Set<String>()
            let imageURLs = images.filter { seen.insert($0).inserted }

            let variantPrice = Double(value(main, "Variant Price")) ?? 0
            let compareAt = Double(value(main, "Variant Compare At Price"))

            // In Shopify, "Compare At Price" is the original (higher) price when on sale.
            let price: Double
            let salePrice: Double?
            if let compareAt, compareAt > variantPrice, variantPrice > 0 {
                price = compareAt
                salePrice = variantPrice
            } else {
                price = variantPrice
                salePrice = nil
            }

            let status = value(main, "Status").lowercased()
            let tagsRaw = value(main, "Tags")
            let tags = tagsRaw
                .split(whereSeparator: { $0 == "," || $0 == ";" })
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            let sku = value(main, "Variant SKU")

            let product = ParsedProduct(
                handle: handle,
                name: value(main, "Title"),
                description: cleanHTML(value(main, "Body (HTML)")),
                price: price,
                salePrice: salePrice,
                category: deriveCategory(
                    googleCategory: value(main, "Product Category"),
                    type: value(main, "Type"),
                    tags: tags,
                    title: value(main, "Title")
                ),
                stockQuantity: Int(value(main, "Variant Inventory Qty")) ?? 0,
                isActive: status.isEmpty ? true : (status == "active"),
                imageURLs: imageURLs,
                sku: sku.isEmpty ? nil : sku,
                tags: tags
            )
            products.append(product)
        }
        return products
    }

    // MARK: - Export

    /// Serializes products to a simple CSV (a readable subset of the Shopify columns).
    static func export(products: [(handle: String, name: String, description: String, price: Double, salePrice: Double?, category: String, stockQuantity: Int, isActive: Bool, imageURLs: [String], sku: String?, tags: [String])]) -> String {
        let header = ["Handle", "Title", "Body (HTML)", "Type", "Tags", "Variant SKU",
                      "Variant Inventory Qty", "Variant Price", "Variant Compare At Price",
                      "Image Src", "Status"]
        var lines = [header.map(escape).joined(separator: ",")]
        for p in products {
            let variantPrice = p.salePrice ?? p.price
            let compareAt = p.salePrice != nil ? String(p.price) : ""
            let row = [
                p.handle,
                p.name,
                p.description,
                p.category,
                p.tags.joined(separator: ", "),
                p.sku ?? "",
                String(p.stockQuantity),
                String(variantPrice),
                compareAt,
                p.imageURLs.first ?? "",
                p.isActive ? "active" : "draft"
            ]
            lines.append(row.map(escape).joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Helpers

    /// RFC-4180-style CSV parser that returns rows of fields. Handles quoted
    /// fields with embedded commas, escaped quotes (""), and newlines.
    static func parseRows(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var field = ""
        var row: [String] = []
        var inQuotes = false
        let scalars = Array(text)
        var i = 0
        while i < scalars.count {
            let c = scalars[i]
            if inQuotes {
                if c == "\"" {
                    if i + 1 < scalars.count && scalars[i + 1] == "\"" {
                        field.append("\"")
                        i += 1
                    } else {
                        inQuotes = false
                    }
                } else {
                    field.append(c)
                }
            } else {
                switch c {
                case "\"":
                    inQuotes = true
                case ",":
                    row.append(field); field = ""
                case "\r":
                    break  // ignore; handled by \n
                case "\n":
                    row.append(field); field = ""
                    rows.append(row); row = []
                default:
                    field.append(c)
                }
            }
            i += 1
        }
        // Final field/row (if the file doesn't end with a newline).
        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            rows.append(row)
        }
        return rows
    }

    /// Quotes a CSV field if it contains a comma, quote, or newline.
    private static func escape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }

    /// Strips HTML tags and decodes a few common entities for a readable description.
    static func cleanHTML(_ html: String) -> String {
        var text = html
        // Turn block-level tags into line breaks before stripping.
        for tag in ["</p>", "<br>", "<br/>", "<br />", "</li>", "</div>"] {
            text = text.replacingOccurrences(of: tag, with: "\n", options: .caseInsensitive)
        }
        for tag in ["<li>"] {
            text = text.replacingOccurrences(of: tag, with: "• ", options: .caseInsensitive)
        }
        // Remove all remaining tags.
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        // Decode common entities.
        let entities = ["&amp;": "&", "&nbsp;": " ", "&lt;": "<", "&gt;": ">",
                        "&quot;": "\"", "&#39;": "'", "&rsquo;": "'", "&trade;": "™"]
        for (k, v) in entities {
            text = text.replacingOccurrences(of: k, with: v)
        }
        // Collapse excessive blank lines/whitespace.
        text = text.replacingOccurrences(of: "[ \\t]+", with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Maps the Shopify/Google category + type + tags to a Naturally Yours storefront category.
    static func deriveCategory(googleCategory: String, type: String, tags: [String], title: String) -> String {
        let haystack = (googleCategory + " " + type + " " + tags.joined(separator: " ") + " " + title).lowercased()
        if haystack.contains("bundle") || haystack.contains("kit") || haystack.contains("set") {
            return "Bundles"
        }
        if haystack.contains("men") {
            return "Men"
        }
        if haystack.contains("treatment") || haystack.contains("mask") || haystack.contains("serum") {
            return "Treatments"
        }
        if haystack.contains("skin") || haystack.contains("face") || haystack.contains("body") || haystack.contains("lotion") {
            return "Skincare"
        }
        if haystack.contains("hair") || haystack.contains("shampoo") || haystack.contains("conditioner")
            || haystack.contains("scalp") || haystack.contains("gloss") || haystack.contains("oil")
            || haystack.contains("edge") || haystack.contains("style") {
            return "Haircare"
        }
        return "Haircare"
    }
}
