import Fluent
import Vapor

/// Seeds a starter vending machine from `SeedData/vending.csv` on first run (when no
/// vending machines exist yet). The machine can be renamed/edited in the admin app.
enum VendingImporter {
    static func seedIfNeeded(_ app: Application) async throws {
        let existing = try await VendingMachine.query(on: app.db).count()
        guard existing == 0 else { return }

        let path = app.directory.workingDirectory + "SeedData/vending.csv"
        guard let csv = try? String(contentsOfFile: path, encoding: .utf8) else {
            app.logger.info("No vending seed file found; skipping vending seed")
            return
        }

        let machine = VendingMachine(name: "Campus Vending", campus: "Main Campus", location: "Week of 9/25")
        try await machine.save(on: app.db)
        let machineID = try machine.requireID()

        var imported = 0
        let rows = csv.split(whereSeparator: \.isNewline)
        for (index, line) in rows.enumerated() {
            if index == 0 { continue } // header
            let cols = parseCSVLine(String(line))
            guard cols.count >= 4,
                  let slot = Int(cols[0].trimmingCharacters(in: .whitespaces)),
                  let onHand = Int(cols[2].trimmingCharacters(in: .whitespaces)),
                  let hold = Int(cols[3].trimmingCharacters(in: .whitespaces)) else { continue }
            let product = cols[1].trimmingCharacters(in: .whitespaces)
            guard !product.isEmpty else { continue }
            try await VendingSlot(
                machineID: machineID, slotNumber: slot, productName: product, onHand: onHand, hold: hold
            ).save(on: app.db)
            imported += 1
        }

        app.logger.info("Seeded vending machine '\(machine.name)' with \(imported) slots")
    }

    /// Minimal CSV line parser handling quoted fields with embedded commas.
    private static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                fields.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        fields.append(current)
        return fields
    }
}
