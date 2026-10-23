import AppIntents
import Foundation

struct TurnLightsOnIntent: AppIntent {
    static var title: LocalizedStringResource = "Turn SP105E lights on"
    static var description = IntentDescription("Turns on the SP105E LED strip.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        try await SP105EController.shared.turnPowerOn()
        return .result(dialog: "I sent the light-on command.")
    }
}

struct TurnLightsOffIntent: AppIntent {
    static var title: LocalizedStringResource = "Turn SP105E lights off"
    static var description = IntentDescription("Turns off the SP105E LED strip.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        try await SP105EController.shared.turnPowerOff()
        return .result(dialog: "I sent the light-off command.")
    }
}

struct SetSP105EColorIntent: AppIntent {
    static var title: LocalizedStringResource = "Set SP105E color"
    static var description = IntentDescription("Sets a fixed RGB color on the SP105E LED strip.")
    static var openAppWhenRun = true

    @Parameter(title: "Red", default: 255) var red: Int
    @Parameter(title: "Green", default: 0) var green: Int
    @Parameter(title: "Blue", default: 0) var blue: Int

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let r = UInt8(min(255, max(0, red)))
        let g = UInt8(min(255, max(0, green)))
        let b = UInt8(min(255, max(0, blue)))
        try await SP105EController.shared.setColor(red: r, green: g, blue: b)
        return .result(dialog: "I sent the color command.")
    }
}

struct SP105ESiriShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: TurnLightsOnIntent(), phrases: ["Turn on my lights with \(.applicationName)", "Switch on my SP105E lights"])
        AppShortcut(intent: TurnLightsOffIntent(), phrases: ["Turn off my lights with \(.applicationName)", "Switch off my SP105E lights"])
    }
}
