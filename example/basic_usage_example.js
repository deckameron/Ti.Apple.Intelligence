// ============================================
// BASIC USAGE EXAMPLE
// Ti Apple Intelligence Module
// ============================================

const AppleAI = require('ti.apple.intelligence');

// ============================================
// AVAILABILITY CHECK
// ============================================

//  Method 1: Quick check (property)
if (!AppleAI.isAvailable) {
    alert('Apple Intelligence is not available on this device.');
    console.log('Requirements: iOS 26+, iPhone 15 Pro+');
    return;
}

//  Method 2: Detailed status (property)
const status = AppleAI.availabilityStatus;
console.log('=== APPLE INTELLIGENCE STATUS ===');
console.log('Available:', status.available);
console.log('Reason:', status.reason);

// Possible status.reason values:
// - "ready" - Ready to use
// - "apple_intelligence_disabled" - User hasn't enabled it
// - "device_not_eligible" - Hardware not supported
// - "model_downloading" - Model still downloading
// - "ios_version_too_low" - iOS < 26

//  Method 3: Alternative method (if you prefer using parentheses)
const statusAlt = AppleAI.checkAvailability();
console.log('Alternative status:', statusAlt);

// Handle specific cases
switch (status.reason) {
    case 'ready':
        console.log(' All ready to use!');
        break;
    case 'apple_intelligence_disabled':
        alert('Please enable Apple Intelligence in device Settings.');
        break;
    case 'device_not_eligible':
        alert('Your device does not support Apple Intelligence. iPhone 15 Pro or later required.');
        break;
    case 'model_downloading':
        alert('The AI model is being downloaded. Please wait a few minutes.');
        break;
    case 'ios_version_too_low':
        alert('iOS 26 or later is required to use this feature.');
        break;
}

// ============================================
// CREATING A SESSION
// ============================================

// Create session with custom instructions
AppleAI.createSession({
    instructions: 'You are a helpful assistant that responds in English clearly and concisely.'
});

// Listener to confirm creation
AppleAI.addEventListener('sessionCreated', (e) => {
    console.log('Session created successfully');
});

// ============================================
// SIMPLE TEXT GENERATION
// ============================================

function exampleSimpleGeneration() {
    AppleAI.generateText({
        prompt: 'Explain what artificial intelligence is in 3 sentences.',
        callback: (result) => {
            if (result.success) {
                console.log('=== RESPONSE ===');
                console.log(result.text);
                
                // Update UI
                $.responseLabel.text = result.text;
            } else {
                console.error('Error:', result.error);
                alert('An error occurred: ' + result.error);
            }
        }
    });
}

// ============================================
// TEXT STREAMING (REAL-TIME UI)
// ============================================

function exampleStreaming() {
    let fullText = '';
    
    // Listener for text chunks
    AppleAI.addEventListener('textChunk', (e) => {
        if (!e.isComplete) {
            fullText += e.text;
            $.streamingLabel.text = fullText;
            
            // Auto-scroll if in a scrollable view
            if ($.scrollView) {
                $.scrollView.scrollToBottom();
            }
        } else {
            console.log('Streaming complete');
            console.log('Final text:', fullText);
        }
    });
    
    // Start streaming
    AppleAI.streamText({
        prompt: 'Write a short story about a robot learning to feel emotions.'
    });
}

// ============================================
// SUMMARIZATION
// ============================================

function exampleSummarization() {
    const longText = `
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. 
        Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. 
        Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris 
        nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in 
        reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla 
        pariatur. Excepteur sint occaecat cupidatat non proident, sunt in 
        culpa qui officia deserunt mollit anim id est laborum.
    `;
    
    AppleAI.summarize({
        text: longText,
        callback: (result) => {
            if (result.success) {
                console.log('=== SUMMARY ===');
                console.log(result.summary);
                $.summaryLabel.text = result.summary;
            } else {
                console.error('Error summarizing:', result.error);
            }
        }
    });
}

// ============================================
// STRUCTURED ARTICLE ANALYSIS
// ============================================

function exampleArticleAnalysis() {
    const article = `
        Artificial intelligence is revolutionizing how we interact 
        with technology. With increasingly sophisticated models, we can 
        process natural language, generate images and even create code. 
        The future of AI promises even deeper transformations in all 
        areas of society.
    `;
    
    AppleAI.analyzeArticle({
        text: article,
        callback: (result) => {
            if (result.success) {
                console.log('=== COMPLETE ANALYSIS ===');
                console.log('Title:', result.data.title);
                console.log('Summary:', result.data.summary);
                console.log('Sentiment:', result.data.sentiment);
                console.log('Key points:');
                result.data.pontosChave.forEach((point, i) => {
                    console.log(`  ${i + 1}. ${point}`);
                });
                console.log('Topics:', result.data.topics.join(', '));
                
                // Returned structure:
                // {
                //     title: String,
                //     summary: String,
                //     keyPoints: [String],
                //     sentiment: 'positivo'|'neutro'|'negativo'|'misto',
                //     topics: [String]
                // }
            }
        }
    });
}

// ============================================
// CONTACT EXTRACTION
// ============================================

function exampleContactExtraction() {
    const email = `
        Hello,
        
        Here are the team contacts:
        
        John Silva - john@company.com - (11) 98765-4321
        Company: Tech Solutions
        
        Mary Santos - mary@company.com
        Company: Startup Tech
    `;
    
    AppleAI.extractContacts({
        text: email,
        callback: (result) => {
            if (result.success) {
                console.log('=== EXTRACTED CONTACTS ===');
                
                result.contatos.forEach((contact, i) => {
                    console.log(`\nContact ${i + 1}:`);
                    console.log('  Name:', contact.nome);
                    if (contact.email) console.log('  Email:', contact.email);
                    if (contact.telefone) console.log('  Phone:', contact.telefone);
                    if (contact.empresa) console.log('  Company:', contact.empresa);
                });
                
                // Returned structure:
                // {
                //     contatos: [
                //         {
                //             name: String,
                //             email?: String,
                //             phone?: String,
                //             company?: String
                //         }
                //     ]
                // }
            }
        }
    });
}

// ============================================
// TEXT CLASSIFICATION
// ============================================

function exampleClassification() {
    const comment = "Loved the app! Very useful and well made.";
    
    const categories = [
        'positive_feedback',
        'negative_feedback',
        'bug_report',
        'feature_request',
        'question'
    ];
    
    AppleAI.classifyText({
        text: comment,
        categories: categories,
        callback: (result) => {
            if (result.success) {
                console.log('=== CLASSIFICATION ===');
                console.log('Category:', result.categoria);
                console.log('Confidence:', (result.confianca * 100).toFixed(1) + '%');
                console.log('Explanation:', result.explicacao);
                
                // Returned structure:
                // {
                //     category: String (one of the provided categories),
                //     confidence: Number (0.0 to 1.0),
                //     explanation: String
                // }
            }
        }
    });
}

// ============================================
// KEYWORD EXTRACTION
// ============================================

function exampleKeywords() {
    const text = `
        An epic science fiction film about space exploration,
        with impressive visual effects and a memorable soundtrack.
    `;
    
    AppleAI.extractKeywords({
        text: text,
        maxKeywords: 5,
        callback: (result) => {
            if (result.success) {
                console.log('=== KEYWORDS ===');
                console.log(result.keywords.join(', '));
                
                // Create visual tags
                result.keywords.forEach(keyword => {
                    console.log('Tag:', keyword);
                });
                
                // Returned structure:
                // {
                //     keywords: [String]
                // }
            }
        }
    });
}

// ============================================
// DYNAMIC SCHEMA
// ============================================

function exampleDynamicSchema() {
    const review = "Excellent product, but the price is a bit steep.";
    
    // Define custom schema
    const schema = {
        rating: {
            type: 'number',
            description: 'Rating from 0 to 10',
            required: true
        },
        positive_aspects: {
            type: 'array',
            items: 'string',
            description: 'Positive aspects mentioned',
            required: true
        },
        negative_aspects: {
            type: 'array',
            items: 'string',
            description: 'Negative aspects mentioned',
            required: true
        },
        recommends: {
            type: 'boolean',
            description: 'Whether it recommends the product',
            required: true
        }
    };
    
    AppleAI.generateWithSchema({
        prompt: `Analyze this review: "${review}"`,
        schema: schema,
        callback: (result) => {
            if (result.success) {
                console.log('=== REVIEW ANALYSIS ===');
                console.log('Rating:', result.data.rating);
                console.log('Recommends:', result.data.recommends ? 'Yes' : 'No');
                console.log('Positive:', result.data.positive_aspects);
                console.log('Negative:', result.data.negative_aspects);
                
                // result.data contains the fields defined in schema
            }
        }
    });
}

// ============================================
// ERROR HANDLER
// ============================================

AppleAI.addEventListener('error', (e) => {
    console.error('Apple Intelligence error:', e.message);
    alert('An error occurred: ' + e.message);
});

// ============================================
// EXPORT FUNCTIONS FOR APP USE
// ============================================

module.exports = {
    exampleSimpleGeneration,
    exampleStreaming,
    exampleSummarization,
    exampleArticleAnalysis,
    exampleContactExtraction,
    exampleClassification,
    exampleKeywords,
    exampleDynamicSchema
};

// ============================================
// USAGE IN APP
// ============================================

// In your main file (app.js or alloy.js):
/*
const AppleAI = require('ti.apple.intelligence');
const examples = require('example-basic-usage');

// Check availability first
if (AppleAI.isAvailable) {
    // All ready!
    examples.exampleSimpleGeneration();
} else {
    const status = AppleAI.availabilityStatus;
    alert('Apple Intelligence not available: ' + status.reason);
}
*/