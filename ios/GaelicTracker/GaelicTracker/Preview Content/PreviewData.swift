import Foundation
import SwiftData

@MainActor
enum PreviewData {
    static var container: ModelContainer = {
        let schema = Schema([Team.self, Player.self, Game.self, GameEvent.self, Substitution.self, PlayerGameStat.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        insertSampleData(into: container.mainContext)
        return container
    }()

    static func insertSampleData(into context: ModelContext) {
        let crokes = Team(name: "Kilmacud Crokes", shortName: "CRO", colourHex: "#1A73E8", format: .fifteens)
        let ballymun = Team(name: "Ballymun Kickhams", shortName: "BKH", colourHex: "#E8341A", format: .fifteens)

        let crokesPlayers = [
            ("Ciarán Murphy", 1), ("Paul Mannion", 2), ("Tom Shields", 3),
            ("Rory O'Carroll", 4), ("Conor Casey", 5), ("Mark Vaughan", 6),
        ]
        for (name, num) in crokesPlayers {
            let p = Player(name: name, jerseyNumber: num)
            p.team = crokes
            crokes.players.append(p)
            context.insert(p)
        }

        let ballymunPlayers = [
            ("Dean Rock", 1), ("Andrew McGowan", 2), ("Paddy Small", 3),
            ("Jonny Cooper", 4), ("John Stynes", 5), ("Keith Beirne", 6),
        ]
        for (name, num) in ballymunPlayers {
            let p = Player(name: name, jerseyNumber: num)
            p.team = ballymun
            ballymun.players.append(p)
            context.insert(p)
        }

        context.insert(crokes)
        context.insert(ballymun)

        // Sample completed game
        let game = Game(homeTeam: crokes, awayTeam: ballymun, venue: "Parnell Park", format: .fifteens)
        game.status = .fullTime
        game.clockElapsedSeconds = 3600

        // Starting stats
        for (i, p) in crokes.players.enumerated() {
            let s = PlayerGameStat(playerID: p.id, playerName: p.name, playerJerseyNumber: p.jerseyNumber, teamSide: .home)
            s.goals = i == 1 ? 1 : 0
            s.points = [0, 4, 2, 0, 1, 3][i]
            s.minutesPlayed = 60
            game.playerStats.append(s)
            context.insert(s)
        }
        for (i, p) in ballymun.players.enumerated() {
            let s = PlayerGameStat(playerID: p.id, playerName: p.name, playerJerseyNumber: p.jerseyNumber, teamSide: .away)
            s.goals = 0
            s.points = [0, 5, 0, 1, 0, 2][i]
            s.minutesPlayed = 60
            game.playerStats.append(s)
            context.insert(s)
        }

        // Sample events
        let events: [(Int, EventType, EventTeamSide)] = [
            (300, .point, .home), (720, .goal, .home),
            (1080, .point, .away), (1500, .point, .home),
            (2100, .freeAwarded, .away), (2400, .point, .away),
            (2700, .yellowCard, .home), (3000, .point, .home),
        ]
        for (sec, type, side) in events {
            let e = GameEvent(clockSeconds: sec, eventType: type, teamSide: side,
                              pitchX: type.needsPitchLocation ? Double.random(in: 0.1...0.9) : nil,
                              pitchY: type.needsPitchLocation ? Double.random(in: 0.1...0.9) : nil)
            game.events.append(e)
            context.insert(e)
        }

        context.insert(game)
        try? context.save()
    }
}
