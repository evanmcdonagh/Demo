import Foundation
import SwiftData
import Observation

@Observable
final class GameViewModel {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func createGame(
        homeTeam: Team,
        awayTeam: Team,
        venue: String,
        format: TeamFormat,
        halfDurationMinutes: Int,
        startingHomePlayers: [Player],
        startingAwayPlayers: [Player]
    ) -> Game {
        let game = Game(
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            venue: venue,
            format: format,
            halfDurationMinutes: halfDurationMinutes
        )

        // Seed starting PlayerGameStat records for the initial rosters
        for player in startingHomePlayers {
            let stat = PlayerGameStat(
                playerID: player.id,
                playerName: player.name,
                playerJerseyNumber: player.jerseyNumber,
                teamSide: .home,
                fieldEntrySecond: 0
            )
            game.playerStats.append(stat)
            context.insert(stat)
        }

        for player in startingAwayPlayers {
            let stat = PlayerGameStat(
                playerID: player.id,
                playerName: player.name,
                playerJerseyNumber: player.jerseyNumber,
                teamSide: .away,
                fieldEntrySecond: 0
            )
            game.playerStats.append(stat)
            context.insert(stat)
        }

        context.insert(game)
        try? context.save()
        return game
    }

    func deleteGame(_ game: Game) {
        context.delete(game)
        try? context.save()
    }
}
