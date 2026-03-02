import AppIntents

struct ControlLightsIntent: AppIntent {
    static var title: LocalizedStringResource = "Control Lights"
    static var description: IntentDescription = "Control smart home lights via Aegis"

    @Parameter(title: "Room")
    var room: String

    @Parameter(title: "Action")
    var action: String  // "on", "off", "dim"

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Phase 3: Full smart home Siri integration
        .result(dialog: "Light control via Siri coming in Phase 3.")
    }
}
