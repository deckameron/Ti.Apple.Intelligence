const AppleAI = require('ti.apple.intelligence');

// Check availability (property)
if (!AppleAI.isAvailable) {
    alert('Apple Intelligence not available');
    return;
}

// Get detailed status (property)
const status = AppleAI.availabilityStatus;
console.log('Available:', status.available);
console.log('Reason:', status.reason);

// OR use alternative method if you prefer
const statusAlt = AppleAI.checkAvailability();
console.log('Status:', statusAlt);

// Create session (method with parameters)
AppleAI.createSession({
    instructions: 'You are a helpful assistant.'
});

// Generate text (asynchronous method)
AppleAI.generateText({
    prompt: 'Explain artificial intelligence',
    callback: (result) => {
        if (result.success) {
            console.log('Response:', result.text);
        }
    }
});

// Analyze article (asynchronous method with @Generable)
AppleAI.analyzeArticle({
    text: myArticle,
    callback: (result) => {
        if (result.success) {
            console.log('Title:', result.data.titulo);
            console.log('Summary:', result.data.resumo);
            console.log('Sentiment:', result.data.sentimento);
        }
    }
});