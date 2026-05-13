import Foundation

// MARK: - Result types

struct ParsedTeam: Identifiable {
    var id: UUID = UUID()
    var name: String
    var shortName: String
    var colourHex: String
    var format: TeamFormat
    var players: [ParsedPlayer]
    var warnings: [String]
}

struct ParsedPlayer {
    var name: String
    var jerseyNumber: Int
}

// MARK: - Errors

enum CSVParseError: LocalizedError {
    case emptyFile
    case missingTeamName
    case noPlayers

    var errorDescription: String? {
        switch self {
        case .emptyFile:        return "The CSV file is empty."
        case .missingTeamName:  return "The first row must contain a team name."
        case .noPlayers:        return "No valid player rows were found."
        }
    }
}

// MARK: - Parser

/// Parses a CSV file into a `ParsedTeam`.
///
/// **Expected format**
/// ```
/// Team Name, Short Name, #HexColour, Format
/// Player Name, Jersey Number
/// Player Name, Jersey Number
/// ...
/// ```
///
/// - Row 1: team metadata. Only the team name is required.
///   - Column 1: team name (required)
///   - Column 2: short name, 1–4 chars (optional, defaults to first 4 letters of name)
///   - Column 3: hex colour, e.g. `#1A73E8` (optional, defaults to `#3478F6`)
///   - Column 4: format — one of `7`, `9`, `11`, `13`, `15` (optional, defaults to `15`)
/// - Rows 2+: one player per row — name, jersey number.
/// - Lines starting with `#` and blank lines are ignored.
/// - Both `,` and `;` are accepted as delimiters.
enum CSVTeamParser {

    static func parse(_ csvString: String) throws -> ParsedTeam {
        let lines = csvString
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }

        guard !lines.isEmpty else { throw CSVParseError.emptyFile }

        // ── Row 1: team metadata ──────────────────────────────────────────
        let teamCols = split(lines[0])
        guard let rawName = teamCols.first, !rawName.isEmpty else {
            throw CSVParseError.missingTeamName
        }

        let name      = rawName
        let shortName = teamCols.count > 1 && !teamCols[1].isEmpty
            ? String(teamCols[1].prefix(4)).uppercased()
            : String(name.filter { !$0.isWhitespace }.prefix(4)).uppercased()

        let colourHex = teamCols.count > 2 && teamCols[2].hasPrefix("#")
            ? teamCols[2]
            : "#3478F6"

        let format: TeamFormat = {
            if teamCols.count > 3, let raw = Int(teamCols[3]),
               let f = TeamFormat(rawValue: raw) { return f }
            return .fifteens
        }()

        // ── Rows 2+: players ─────────────────────────────────────────────
        var players: [ParsedPlayer] = []
        var warnings: [String] = []
        var seenNumbers: Set<Int> = []

        for (offset, line) in lines.dropFirst().enumerated() {
            let row = offset + 2          // human-readable row number
            let cols = split(line)
            guard cols.count >= 2 else {
                warnings.append("Row \(row): skipped — expected "Name, Number" but got \"\(line)\".")
                continue
            }

            let playerName = cols[0]
            guard !playerName.isEmpty else {
                warnings.append("Row \(row): skipped — player name is blank.")
                continue
            }

            guard let number = Int(cols[1]), (1...99).contains(number) else {
                warnings.append("Row \(row): skipped — "\(cols[1])" is not a valid jersey number (1–99).")
                continue
            }

            if seenNumbers.contains(number) {
                warnings.append("Row \(row): duplicate jersey #\(number) for "\(playerName)" — skipped.")
                continue
            }

            seenNumbers.insert(number)
            players.append(ParsedPlayer(name: playerName, jerseyNumber: number))
        }

        if players.isEmpty { throw CSVParseError.noPlayers }

        return ParsedTeam(
            name: name,
            shortName: shortName,
            colourHex: colourHex,
            format: format,
            players: players,
            warnings: warnings
        )
    }

    // MARK: - Helpers

    private static func split(_ line: String) -> [String] {
        // Support both comma and semicolon delimiters
        let delimiter: Character = line.contains(";") ? ";" : ","
        return line
            .split(separator: delimiter, omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }
}
