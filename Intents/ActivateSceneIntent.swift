import AppIntents

struct ActivateSceneIntent: AppIntent {
    static var title: LocalizedStringResource = "Activate Scene"
    static var description: IntentDescription = "Activate a smart home scene via Aegis"

    @Parameter(title: "Scene Name")
    var sceneName: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Phase 3: Full scene activation via Siri
        .result(dialog: "Scene activation via Siri coming in Phase 3.")
    }
}
