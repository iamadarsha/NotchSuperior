// NOTCHSUPERIOR ADDITION
import Foundation

// Supported providers
enum NSAIProvider: String, Codable, CaseIterable {
    case openAI    = "openai"
    case claude    = "claude"
    case gemini    = "gemini"
    var displayName: String {
        switch self {
        case .openAI:  return "OpenAI (GPT-4o)"
        case .claude:  return "Anthropic (Claude)"
        case .gemini:  return "Google (Gemini)"
        }
    }
    var baseURL: String {
        switch self {
        case .openAI:  return "https://api.openai.com/v1/chat/completions"
        case .claude:  return "https://api.anthropic.com/v1/messages"
        case .gemini:  return "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
        }
    }
}

struct NSAIChatMessage: Identifiable, Codable {
    let id: UUID
    let role: String   // "user" | "assistant" | "system"
    var content: String
    let timestamp: Date
}

struct NSAIConversation: Identifiable, Codable {
    let id: UUID
    var title: String
    var provider: NSAIProvider
    var messages: [NSAIChatMessage]
    var createdAt: Date
    var updatedAt: Date
}

struct NSAINote: Identifiable, Codable {
    let id: UUID
    var title: String
    var rawTranscript: String?   // original voice or typed text
    var summary: String?         // AI-generated bullets
    var template: NSAINoteTemplate
    var createdAt: Date
    var updatedAt: Date
}

enum NSAINoteTemplate: String, Codable, CaseIterable {
    case freeform, todos, bugReport, meetingMinutes, researchOutline
    var displayName: String {
        switch self {
        case .freeform:        return "Free-form"
        case .todos:           return "To-Do List"
        case .bugReport:       return "Bug Report"
        case .meetingMinutes:  return "Meeting Minutes"
        case .researchOutline: return "Research Outline"
        }
    }
    var systemPrompt: String {
        switch self {
        case .freeform:
            return "Summarize the following text into clear bullet points."
        case .todos:
            return "Extract actionable to-do items from the following text. Format as a numbered list."
        case .bugReport:
            return "Structure the following notes into a bug report with: Summary, Steps to Reproduce, Expected Behavior, Actual Behavior, and Environment."
        case .meetingMinutes:
            return "Structure the following as meeting minutes with: Attendees (if mentioned), Agenda, Key Decisions, and Action Items."
        case .researchOutline:
            return "Convert the following notes into a structured research outline with headings and sub-bullets."
        }
    }
}
