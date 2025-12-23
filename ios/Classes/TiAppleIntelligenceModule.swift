//
//  TiAppleIntelligenceModule.swift
//  Ti.Apple.Intelligence
//
//  Created by Your Name
//  Copyright (c) 2025 Your Company. All rights reserved.
//

import UIKit
import TitaniumKit
import FoundationModels

/**
 
 Titanium Swift Module Requirements
 ---
 
 1. Use the @objc annotation to expose your class to Objective-C (used by the Titanium core)
 2. Use the @objc annotation to expose your method to Objective-C as well.
 3. Method arguments always have the "[Any]" type, specifying a various number of arguments.
 Unwrap them like you would do in Swift, e.g. "guard let arguments = arguments, let message = arguments.first"
 4. You can use any public Titanium API like before, e.g. TiUtils. Remember the type safety of Swift, like Int vs Int32
 and NSString vs. String.
 
 */

@available(iOS 26.0, *)
@objc(TiAppleIntelligenceModule)
@MainActor
class TiAppleIntelligenceModule: TiModule {
    
    private var session: LanguageModelSession?
    
    @objc override func moduleId() -> String! {
        return "ti.apple.intelligence"
    }

    override func startup() {
      super.startup()
      debugPrint("[DEBUG] \(self) loaded")
    }
    
    // MARK: - Availability Verification
    @objc
    var isAvailable: Bool {
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.isAvailable
        }
        return false
    }
    
    // Adicionar método de diagnóstico
    @objc(diagnostics:)
    func diagnostics(args: [Any]?) -> [String: Any] {
        var info: [String: Any] = [:]
        
        // Status básico
        info["ios_version"] = UIDevice.current.systemVersion
        info["device_model"] = UIDevice.current.model
        
        // Verificar disponibilidade
        let model = SystemLanguageModel.default
        info["is_available"] = model.isAvailable
        
        switch model.availability {
        case .available:
            info["status"] = "available"
            
            // Criar uma sessão de teste
            let testSession = LanguageModelSession()
            info["session_created"] = true
            
            // Note: Test generation happens asynchronously
            // For a synchronous diagnostics result, we can't await here
            info["test_generation"] = "skipped"
            info["note"] = "Use async testing to verify generation capability"
            
        case .unavailable(let reason):
            info["status"] = "unavailable"
            switch reason {
            case .appleIntelligenceNotEnabled:
                info["reason"] = "not_enabled"
                info["fix"] = "Ative Apple Intelligence em Ajustes"
            case .deviceNotEligible:
                info["reason"] = "device_not_eligible"
                info["fix"] = "Necessário iPhone 15 Pro+ ou iPad M1+"
            case .modelNotReady:
                info["reason"] = "model_downloading"
                info["fix"] = "Aguarde o download do modelo terminar"
            @unknown default:
                info["reason"] = "unknown"
            }
        }
        
        // Verificar espaço em disco
        if let space = try? FileManager.default.attributesOfFileSystem(
            forPath: NSHomeDirectory()
        )[.systemFreeSize] as? Int64 {
            let gb = Double(space) / 1_000_000_000
            info["free_space_gb"] = String(format: "%.1f", gb)
            info["enough_space"] = gb >= 7.0
        }
        
        return info
    }
    
    // Adicionar método para esperar o modelo ficar pronto
    @objc(waitForModel:)
    func waitForModel(args: [Any]?) {
        
        guard let dict = args?.first as? [String: Any],
              let callback = dict["callback"] as? KrollCallback else {
            return
        }
        
        let maxAttempts = dict["maxAttempts"] as? Int ?? 30
        let delaySeconds = dict["delay"] as? Double ?? 2.0
        
        var attempts = 0
        
        func checkAvailability() {
            attempts += 1
            
            switch SystemLanguageModel.default.availability {
            case .available:
                // Tentar criar uma sessão de teste
                let testSession = LanguageModelSession()
                
                Task {
                    do {
                        let _ = try await testSession.respond(to: "Test")
                        
                        DispatchQueue.main.async {
                            callback.call([[
                                "ready": true,
                                "attempts": attempts
                            ]], thisObject: nil)
                        }
                        return
                    } catch {
                        // Modelo não está realmente pronto ainda
                        if attempts < maxAttempts {
                            DispatchQueue.main.asyncAfter(deadline: .now() + delaySeconds) {
                                checkAvailability()
                            }
                        } else {
                            DispatchQueue.main.async {
                                callback.call([[
                                    "ready": false,
                                    "error": "Timeout aguardando modelo",
                                    "attempts": attempts
                                ]], thisObject: nil)
                            }
                        }
                    }
                }
                
            case .unavailable(let reason):
                DispatchQueue.main.async {
                    var reasonStr = ""
                    switch reason {
                    case .appleIntelligenceNotEnabled:
                        reasonStr = "Apple Intelligence não está ativado"
                    case .deviceNotEligible:
                        reasonStr = "Dispositivo não é elegível"
                    case .modelNotReady:
                        reasonStr = "Modelo ainda baixando"
                    @unknown default:
                        reasonStr = "Razão desconhecida"
                    }
                    
                    callback.call([[
                        "ready": false,
                        "error": reasonStr,
                        "attempts": attempts
                    ]], thisObject: nil)
                }
            }
        }
        
        checkAvailability()
    }
    
    @objc
    var availabilityStatus: [String: Any] {
        if #available(iOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return ["available": true, "reason": "ready"]
            case .unavailable(let reason):
                let reasonString: String
                switch reason {
                case .appleIntelligenceNotEnabled:
                    reasonString = "apple_intelligence_disabled"
                case .deviceNotEligible:
                    reasonString = "device_not_eligible"
                case .modelNotReady:
                    reasonString = "model_downloading"
                @unknown default:
                    reasonString = "unknown"
                }
                return ["available": false, "reason": reasonString]
            }
        }
        return ["available": false, "reason": "ios_version_too_low"]
    }
    
    // Alternativa: Method with parameters (can be dummy)
    // AppleAI.checkAvailability() or AppleAI.checkAvailability(null)
    @objc(checkAvailability:)
    func checkAvailability(args: [Any]?) -> [String: Any] {
        return availabilityStatus
    }
    
    // MARK: - Session Creation
    
    @objc(createSession:)
    func createSession(args: [Any]?) {
        var instructions: String? = nil
        if let dict = args?.first as? [String: Any] {
            instructions = dict["instructions"] as? String
        }
        
        if let instructions = instructions {
            session = LanguageModelSession(instructions: instructions)
        } else {
            session = LanguageModelSession()
        }
        
        fireEvent("sessionCreated", with: ["success": true])
    }
    
    // MARK: - Text Generation
    
    @objc(generateText:)
    func generateText(args: [Any]?) {
        guard let dict = args?.first as? [String: Any],
              let prompt = dict["prompt"] as? String,
              let callback = dict["callback"] as? KrollCallback else {
            return
        }
        
        let session = self.session ?? LanguageModelSession()
        
        Task {
            do {
                let response = try await session.respond(to: prompt)
                let content = response.content
                
                DispatchQueue.main.async {
                    callback.call([[
                        "success": true,
                        "text": content
                    ]], thisObject: nil)
                }
            } catch {
                let errorMessage = error.localizedDescription
                DispatchQueue.main.async {
                    callback.call([[
                        "success": false,
                        "error": errorMessage
                    ]], thisObject: nil)
                }
            }
        }
    }
    
    // MARK: - Text Streaming
    
    @objc(streamText:)
    func streamText(args: [Any]?) {
        guard let dict = args?.first as? [String: Any],
              let prompt = dict["prompt"] as? String else {
            return
        }
        
        let session = self.session ?? LanguageModelSession()
        
        Task { @MainActor in
            do {
                for try await partial in session.streamResponse(to: prompt) {
                    if self._hasListeners("textChunk") {
                        let content = partial.content
                        self.fireEvent("textChunk", with: [
                            "text": content,
                            "isComplete": false
                        ])
                    }
                }
                
                self.fireEvent("textChunk", with: [
                    "text": "",
                    "isComplete": true
                ])
            } catch {
                let errorMessage = error.localizedDescription
                self.fireEvent("error", with: ["message": errorMessage])
            }
        }
    }
    
    // MARK: - Summarization
    
    @objc(summarize:)
    func summarize(args: [Any]?) {
        guard let dict = args?.first as? [String: Any],
              let text = dict["text"] as? String,
              let callback = dict["callback"] as? KrollCallback else {
            return
        }
        
        let session = LanguageModelSession(instructions:
            "You are an assistant specialized in creating concise and informative summaries.")
        
        Task {
            do {
                let response = try await session.respond(
                    to: "Summarize the following text concisely:\n\n\(text)"
                )
                let summary = response.content
                
                DispatchQueue.main.async {
                    callback.call([[
                        "success": true,
                        "summary": summary
                    ]], thisObject: nil)
                }
            } catch {
                let errorMessage = error.localizedDescription
                DispatchQueue.main.async {
                    callback.call([[
                        "success": false,
                        "error": errorMessage
                    ]], thisObject: nil)
                }
            }
        }
    }
    
    // MARK: - Structured Generation with @Generable
    
    @objc(analyzeArticle:)
    func analyzeArticle(args: [Any]?) {
        guard let dict = args?.first as? [String: Any],
              let text = dict["text"] as? String,
              let callback = dict["callback"] as? KrollCallback else {
            return
        }
        
        let session = LanguageModelSession()
        
        Task {
            do {
                let response = try await session.respond(
                    to: "Analyze this text:\n\n\(text)",
                    generating: ArticleAnalysis.self
                )
                
                let analysis = response.content
                let data: [String: Any] = [
                    "title": analysis.title,
                    "summary": analysis.summary,
                    "keyPoints": analysis.keyPoints,
                    "sentiment": analysis.sentiment,
                    "topics": analysis.topics
                ]
                
                DispatchQueue.main.async {
                    callback.call([[
                        "success": true,
                        "data": data
                    ]], thisObject: nil)
                }
            } catch {
                let errorMessage = error.localizedDescription
                DispatchQueue.main.async {
                    callback.call([[
                        "success": false,
                        "error": errorMessage
                    ]], thisObject: nil)
                }
            }
        }
    }
    
    @objc(extractContacts:)
    func extractContacts(args: [Any]?) {
        guard let dict = args?.first as? [String: Any],
              let text = dict["text"] as? String,
              let callback = dict["callback"] as? KrollCallback else {
            return
        }
        
        let session = LanguageModelSession()
        
        Task {
            do {
                let response = try await session.respond(
                    to: "Extract contact information from this text:\n\n\(text)",
                    generating: ContactExtraction.self
                )
                
                let contacts = response.content.contacts.map { contact in
                    return [
                        "name": contact.name,
                        "email": contact.email ?? "",
                        "phone": contact.phone ?? "",
                        "company": contact.company ?? ""
                    ]
                }
                
                DispatchQueue.main.async {
                    callback.call([[
                        "success": true,
                        "contacts": contacts
                    ]], thisObject: nil)
                }
            } catch {
                let errorMessage = error.localizedDescription
                DispatchQueue.main.async {
                    callback.call([[
                        "success": false,
                        "error": errorMessage
                    ]], thisObject: nil)
                }
            }
        }
    }
    
    @objc(classifyText:)
    func classifyText(args: [Any]?) {
        guard let dict = args?.first as? [String: Any],
              let text = dict["text"] as? String,
              let categories = dict["categories"] as? [String],
              let callback = dict["callback"] as? KrollCallback else {
            return
        }
        
        let session = LanguageModelSession()
        let categoriesStr = categories.joined(separator: ", ")
        
        Task {
            do {
                let response = try await session.respond(
                    to: "Classify this text into ONE of the following categories: \(categoriesStr)\n\nText: \(text)",
                    generating: TextClassification.self
                )
                
                let classification = response.content
                
                DispatchQueue.main.async {
                    callback.call([[
                        "success": true,
                        "category": classification.category,
                        "confidence": classification.confidence,
                        "explanation": classification.explanation
                    ]], thisObject: nil)
                }
            } catch {
                let errorMessage = error.localizedDescription
                DispatchQueue.main.async {
                    callback.call([[
                        "success": false,
                        "error": errorMessage
                    ]], thisObject: nil)
                }
            }
        }
    }
    
    @objc(extractKeywords:)
    func extractKeywords(args: [Any]?) {
        guard let dict = args?.first as? [String: Any],
              let text = dict["text"] as? String,
              let callback = dict["callback"] as? KrollCallback else {
            return
        }
        
        let maxKeywords = dict["maxKeywords"] as? Int ?? 5
        
        let session = LanguageModelSession()
        
        Task {
            do {
                let response = try await session.respond(
                    to: "Extract the \(maxKeywords) most important keywords from this text:\n\n\(text)",
                    generating: KeywordExtraction.self
                )
                
                let keywords = response.content.keywords
                
                DispatchQueue.main.async {
                    callback.call([[
                        "success": true,
                        "keywords": keywords
                    ]], thisObject: nil)
                }
            } catch {
                let errorMessage = error.localizedDescription
                DispatchQueue.main.async {
                    callback.call([[
                        "success": false,
                        "error": errorMessage
                    ]], thisObject: nil)
                }
            }
        }
    }
    
    // Dynamic schema - for more flexible cases
    @objc(generateWithSchema:)
    func generateWithSchema(args: [Any]?) {
        guard let dict = args?.first as? [String: Any],
              let prompt = dict["prompt"] as? String,
              let schema = dict["schema"] as? [String: Any],
              let callback = dict["callback"] as? KrollCallback else {
            return
        }
        
        // Build prompt with schema
        let schemaDescription = buildSchemaDescription(from: schema)
        let enhancedPrompt = """
        \(prompt)
        
        Respond ONLY with a valid JSON following this exact structure:
        \(schemaDescription)
        
        Do not include additional text, markdown, or explanations. Only the pure JSON.
        """
        
        let session = LanguageModelSession()
        
        Task {
            do {
                let response = try await session.respond(to: enhancedPrompt)
                
                // Clean possible markdown
                var cleanedContent = response.content
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "```json", with: "")
                    .replacingOccurrences(of: "```", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Parse JSON response
                if let jsonData = cleanedContent.data(using: .utf8),
                   let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                    
                    DispatchQueue.main.async {
                        callback.call([[
                            "success": true,
                            "data": jsonObject
                        ]], thisObject: nil)
                    }
                } else {
                    // Fallback: return raw text
                    let rawText = cleanedContent
                    DispatchQueue.main.async {
                        callback.call([[
                            "success": true,
                            "data": ["rawText": rawText],
                            "warning": "Could not parse JSON"
                        ]], thisObject: nil)
                    }
                }
            } catch {
                let errorMessage = error.localizedDescription
                DispatchQueue.main.async {
                    callback.call([[
                        "success": false,
                        "error": errorMessage
                    ]], thisObject: nil)
                }
            }
        }
    }
    
    private func buildSchemaDescription(from schema: [String: Any]) -> String {
        var description = "{\n"
        
        for (key, value) in schema.sorted(by: { $0.key < $1.key }) {
            if let fieldSchema = value as? [String: Any] {
                let type = fieldSchema["type"] as? String ?? "string"
                let desc = fieldSchema["description"] as? String ?? ""
                let required = fieldSchema["required"] as? Bool ?? false
                let options = fieldSchema["options"] as? [String]
                
                description += "  \"\(key)\": "
                
                switch type {
                case "array":
                    if let itemType = fieldSchema["items"] as? String {
                        description += "[\"\(itemType)\", ...] // array of \(itemType)"
                    } else {
                        description += "[] // array"
                    }
                case "number":
                    description += "0 // number"
                case "boolean":
                    description += "true // boolean"
                default:
                    if let options = options {
                        description += "\"\(options.first ?? "")\" // one of: \(options.joined(separator: ", "))"
                    } else {
                        description += "\"string\" // string"
                    }
                }
                
                if !desc.isEmpty {
                    description += " - \(desc)"
                }
                if required {
                    description += " (REQUIRED)"
                }
                description += "\n"
            }
        }
        
        description += "}"
        return description
    }
}

// MARK: - Predefined @Generable Types

@available(iOS 26.0, *)
@Generable
struct ArticleAnalysis {
    @Guide(description: "Title or main subject of the text")
    var title: String
    
    @Guide(description: "Concise summary in 2-3 sentences")
    var summary: String
    
    @Guide(description: "Main points or insights from the text", .count(3...5))
    var keyPoints: [String]
    
    @Guide(description: "Sentiment analysis", .anyOf(["positive", "neutral", "negative", "mixed"]))
    var sentiment: String
    
    @Guide(description: "Main topics or categories covered", .count(2...4))
    var topics: [String]
}

@available(iOS 26.0, *)
@Generable
struct ContactExtraction {
    @Generable
    struct Contact {
        @Guide(description: "Full name of the person")
        var name: String
        
        @Guide(description: "Email address if available")
        var email: String?
        
        @Guide(description: "Phone number if available")
        var phone: String?
        
        @Guide(description: "Company or organization name")
        var company: String?
    }
    
    @Guide(description: "List of contacts found in the text")
    var contacts: [Contact]
}

@available(iOS 26.0, *)
@Generable
struct TextClassification {
    @Guide(description: "Chosen category")
    var category: String
    
    @Guide(description: "Confidence level in the classification (0.0 to 1.0)")
    var confidence: Double
    
    @Guide(description: "Brief explanation of the classification")
    var explanation: String
}

@available(iOS 26.0, *)
@Generable
struct KeywordExtraction {
    @Guide(description: "List of relevant keywords")
    var keywords: [String]
}
