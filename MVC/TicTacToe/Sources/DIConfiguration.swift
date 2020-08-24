import AtomicDI
import UIKit

struct DIConfiguration {
    func makeRootViewController() -> UIViewController {
        AtomicDI.makeRoot(createRootScope)
    }
}

// MARK: dependency export types

private struct RootExports: ExportedRootDependencies {
    let playersStream: PlayersStream
    let mutablePlayersStream: MutablePlayersStream
}

private struct LoggedInExports: ExportedDependencies {
    let scoreStream: ScoreStream
    let mutableScoreStream: MutableScoreStream

    let parentExport: RootExports
}

private typealias LoggedOutExports = EmptyExports<RootExports>

private typealias GameExports = EmptyExports<LoggedInExports>

private typealias ScoreSheetExports = EmptyExports<LoggedInExports>

// MARK: scope factories

private func createRootScope(ctx: Context<RootExports>) -> Scope<UIViewController, RootExports> {
    let loggedOutScopeFactory = ctx.factoryMaker.make(createLoggedOutScope)
    let loggedInScopeFactory = ctx.factoryMaker.make(createLoggedInScope)

    let playersStream = PlayersStreamImpl()
    let rootViewController = RootViewController(
        playersStream: playersStream,
        loggedOutBuilder: loggedOutScopeFactory,
        loggedInBuilder: loggedInScopeFactory
    )

    return Scope(
        result: rootViewController,
        export: RootExports(
            playersStream: playersStream,
            mutablePlayersStream: playersStream
        )
    )
}

private func createLoggedOutScope(_ ctx: Context<LoggedOutExports>) -> Scope<UIViewController, LoggedOutExports> {
    let loggedOutViewController = LoggedOutViewController(mutablePlayersStream: ctx.mutablePlayersStream)

    return Scope(
        result: loggedOutViewController,
        export: LoggedOutExports(parentExport: ctx.parentExport)
    )
}

private func createLoggedInScope(_ ctx: Context<LoggedInExports>) -> Scope<UIViewController, LoggedInExports> {
    let gameScopeFactory = ctx.factoryMaker.make(createGameScope)
    let scoreSheetScopeFactory = ctx.factoryMaker.make(createScoreSheetScope)

    let scoreStream = ScoreStreamImpl()

    let loggedInViewController = LoggedInViewController(
        gameBuilder: gameScopeFactory,
        scoreStream: scoreStream,
        scoreSheetBuilder: scoreSheetScopeFactory
    )

    return Scope(
        result: loggedInViewController,
        export: LoggedInExports(
            scoreStream: scoreStream,
            mutableScoreStream: scoreStream,
            parentExport: ctx.parentExport
        )
    )
}

private func createGameScope(_ ctx: Context<GameExports>) -> Scope<UIViewController, GameExports> {
    let scoreSheetScopeFactory = ctx.factoryMaker.make(createScoreSheetScope)

    let gameViewController = GameViewController(
        mutableScoreStream: ctx.mutableScoreStream,
        playersStream: ctx.playersStream,
        scoreSheetBuilder: scoreSheetScopeFactory
    )

    return Scope(
        result: gameViewController,
        export: GameExports(parentExport: ctx.parentExport)
    )
}

private func createScoreSheetScope(_ ctx: Context<ScoreSheetExports>) -> Scope<UIViewController, ScoreSheetExports> {
    let scoreSheetViewController = ScoreSheetViewController(scoreStream: ctx.scoreStream)

    return Scope(
        result: scoreSheetViewController,
        export: ScoreSheetExports(parentExport: ctx.parentExport)
    )
}
