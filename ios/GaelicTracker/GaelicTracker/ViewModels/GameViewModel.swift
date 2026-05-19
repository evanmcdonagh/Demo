import Foundation
import SwiftData
import Observation

// MARK: - Guest team descriptor

/// Lightweight value type representing a guest/unknown opponent.
/// No persistent `Team` record is created; numbered `PlayerGameStat`
/// records (#1–N) are seeded directly at game-creation time.
struct GuestTeamInfo {
    var name: String
    var shortName: String
    var colourHex: String = "#8E8E93"   // system gray
}

// MARK: - Team source

enum TeamSource {
    case roster(team: Team, startingPlayers: [Player])
    case guest(info: GuestTeamInfo)
}

// MARK: - ViewModel

@Observable
final class GameViewModel {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Create

    func createGame(
        home: TeamSource,
        away: TeamSource,
        venue: String,
        format: TeamFormat,
        halfDurationMinutes: Int
    ) -> Game {
        // Build raw team data for each side
        let (homeID, homeName, homeShort, homeColour, homeCrest) = teamData(for: home)
        let (awayID, awayName, awayShort, awayColour, awayCrest) = teamData(for: away)

        let game = Game(
            homeTeamID: homeID,
            homeTeamName: homeName,
            homeTeamShortName: homeShort,
            homeTeamColourHex: homeColour,
            homeTeamCrestData: homeCrest,
            awayTeamID: awayID,
            awayTeamName: awayName,
            awayTeamShortName: awayShort,
            awayTeamColourHex: awayColour,
            awayTeamCrestData: awayCrest,
            venue: venue,
            format: format,
            halfDurationMinutes: halfDurationMinutes
        )

        // Seed PlayerGameStat records
        seedStats(for: home, side: .home, format: format, into: game)
        seedStats(for: away, side: .away, format: format, into: game)

        context.insert(game)
        try? context.save()
        return game
    }

    // MARK: - Delete

    func deleteGame(_ game: Game) {
        context.delete(game)
        try? context.save()
    }

    // MARK: - Helpers

    private func teamData(for source: TeamSource)
        -> (id: UUID, name: String, shortName: String, colourHex: String, crestData: Data?)
    {
        switch source {
        case .roster(let team, _):
            return (team.id, team.name, team.shortName, team.colourHex, team.crestImageData)
        case .guest(let info):
            return (UUID(), info.name, info.shortName, info.colourHex, nil)
        }
    }

    private func seedStats(
        for source: TeamSource,
        side: EventTeamSide,
        format: TeamFormat,
        into game: Game
    ) {
        switch source {
        case .roster(_, let players):
            for player in players {
                let stat = PlayerGameStat(
                    playerID: player.id,
                    playerName: player.name,
                    playerJerseyNumber: player.jerseyNumber,
                    teamSide: side,
                    fieldEntrySecond: 0
                )
                game.playerStats.append(stat)
                context.insert(stat)
            }

        case .guest:
            // Generate numbered placeholder stats #1 through format count
            for number in 1...format.maxActivePlayers {
                let stat = PlayerGameStat(
                    playerID: UUID(),
                    playerName: "#\(number)",
                    playerJerseyNumber: number,
                    teamSide: side,
                    fieldEntrySecond: 0
                )
                game.playerStats.append(stat)
                context.insert(stat)
            }
        }
    }
}
