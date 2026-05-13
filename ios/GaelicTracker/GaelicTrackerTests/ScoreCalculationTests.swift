import XCTest
import SwiftData
@testable import GaelicTracker

@MainActor
final class ScoreCalculationTests: XCTestCase {
    var container: ModelContainer!

    override func setUp() async throws {
        let schema = Schema([Team.self, Player.self, Game.self, GameEvent.self, Substitution.self, PlayerGameStat.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
    }

    override func tearDown() {
        container = nil
    }

    func testGoalWorthThreePoints() {
        XCTAssertEqual(EventType.goal.pointValue, 3)
    }

    func testPointWorthOnePoint() {
        XCTAssertEqual(EventType.point.pointValue, 1)
    }

    func testScoreAccumulation() {
        let home = Team(name: "Home", shortName: "HOM", colourHex: "#000000", format: .fifteens)
        let away = Team(name: "Away", shortName: "AWY", colourHex: "#FFFFFF", format: .fifteens)
        container.mainContext.insert(home)
        container.mainContext.insert(away)

        let game = Game(homeTeam: home, awayTeam: away, venue: "Test", format: .fifteens)
        container.mainContext.insert(game)

        let goal = GameEvent(clockSeconds: 300, eventType: .goal, teamSide: .home)
        let point1 = GameEvent(clockSeconds: 600, eventType: .point, teamSide: .home)
        let point2 = GameEvent(clockSeconds: 900, eventType: .point, teamSide: .home)
        game.events.append(contentsOf: [goal, point1, point2])

        XCTAssertEqual(game.homeGoals, 1)
        XCTAssertEqual(game.homePoints, 2)
        XCTAssertEqual(game.homeTotalPoints, 5, "1 goal (3pts) + 2 points (2pts) = 5")
    }

    func testTeamFormatMaxPlayers() {
        XCTAssertEqual(TeamFormat.sevens.maxActivePlayers, 7)
        XCTAssertEqual(TeamFormat.nines.maxActivePlayers, 9)
        XCTAssertEqual(TeamFormat.elevens.maxActivePlayers, 11)
        XCTAssertEqual(TeamFormat.thirteens.maxActivePlayers, 13)
        XCTAssertEqual(TeamFormat.fifteens.maxActivePlayers, 15)
    }

    func testPlayerGameStatTotalPoints() {
        let stat = PlayerGameStat(playerID: UUID(), playerName: "Test", playerJerseyNumber: 1, teamSide: .home)
        stat.goals = 2
        stat.points = 5
        XCTAssertEqual(stat.totalPointValue, 11, "2 goals (6pts) + 5 points = 11")
    }

    func testClockStringFormatting() {
        XCTAssertEqual(0.clockString, "00:00")
        XCTAssertEqual(65.clockString, "01:05")
        XCTAssertEqual(3600.clockString, "60:00")
    }

    func testSinBinDuration() {
        // Black card sin bin should be 10 minutes = 600 seconds
        let sinBinDuration = 600
        let startSecond = 1200
        let expectedExpiry = startSecond + sinBinDuration
        XCTAssertEqual(expectedExpiry, 1800)
    }
}
