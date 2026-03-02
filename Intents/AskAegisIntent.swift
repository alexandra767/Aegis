import AppIntents

struct AskAegisIntent: AppIntent {
    static let title: LocalizedStringResource = "Ask Aegis"
    static let description: IntentDescription = "Send a message to Aegis and get a response"

    @Parameter(title: "Message")
    var message: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Phase 3: Full Siri Shortcuts integration
        .result(dialog: "Aegis Siri integration coming soon.")
    }
}
