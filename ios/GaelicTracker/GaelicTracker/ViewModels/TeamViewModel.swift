import Foundation
import SwiftData
import Observation

@Observable
final class TeamViewModel {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func createTeam(name: String, shortName: String, colourHex: String, format: TeamFormat) -> Team {
        let team = Team(name: name, shortName: shortName, colourHex: colourHex, format: format)
        context.insert(team)
        try? context.save()
        return team
    }

    func updateTeam(_ team: Team, name: String, shortName: String, colourHex: String, format: TeamFormat, crestImageData: Data?) {
        team.name = name
        team.shortName = String(shortName.prefix(4)).uppercased()
        team.colourHex = colourHex
        team.format = format
        team.crestImageData = crestImageData
        try? context.save()
    }

    func deleteTeam(_ team: Team) {
        context.delete(team)
        try? context.save()
    }

    func addPlayer(to team: Team, name: String, jerseyNumber: Int, position: GaelicPosition? = nil) {
        let player = Player(name: name, jerseyNumber: jerseyNumber, position: position)
        player.team = team
        team.players.append(player)
        context.insert(player)
        try? context.save()
    }

    func updatePlayer(_ player: Player, name: String, jerseyNumber: Int, position: GaelicPosition? = nil) {
        player.name = name
        player.jerseyNumber = jerseyNumber
        player.position = position
        try? context.save()
    }

    func removePlayer(_ player: Player) {
        context.delete(player)
        try? context.save()
    }

    func isJerseyNumberTaken(_ number: Int, in team: Team, excluding player: Player? = nil) -> Bool {
        team.players.contains { p in
            p.jerseyNumber == number && p.id != player?.id
        }
    }

    // MARK: - CSV Import

    /// Creates a `Team` and its `Player` records from a successfully parsed CSV.
    @discardableResult
    func importTeam(from parsed: ParsedTeam) -> Team {
        let team = Team(
            name: parsed.name,
            shortName: parsed.shortName,
            colourHex: parsed.colourHex,
            format: parsed.format
        )
        context.insert(team)

        for parsedPlayer in parsed.players {
            let player = Player(name: parsedPlayer.name, jerseyNumber: parsedPlayer.jerseyNumber)
            player.team = team
            team.players.append(player)
            context.insert(player)
        }

        try? context.save()
        return team
    }

    // MARK: - Numbered squad

    /// Removes all existing players and creates numbered placeholders #1 through the team's format count.
    /// Player names are set to the jersey number string (e.g. "1", "2") for quick anonymous tracking.
    func generateNumberedSquad(for team: Team) {
        for player in team.players {
            context.delete(player)
        }
        team.players = []

        for number in 1...team.format.maxActivePlayers {
            let position = GaelicPosition.suggested(for: number)
            let player = Player(name: "\(number)", jerseyNumber: number, position: position)
            player.team = team
            team.players.append(player)
            context.insert(player)
        }
        try? context.save()
    }
}
