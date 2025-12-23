# Apple Intelligence for Titanium SDK

Titanium SDK module for integration with Apple Foundation Models. A local 3B generative AI on iOS 26+.

##  Table of Contents

- [Overview](#overview)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Quick Start](#quick-start)
- [Troubleshooting](#troubleshooting)
- [Documentation](#documentation)
- [Examples](#examples)

---

##  Overview

This module enables the use of the **Apple Foundation Models** framework in Titanium SDK apps, bringing fully local (on-device) generative AI to your iOS applications.

### Key Features:

✅ **Text generation** with real-time streaming  
✅ **Structured analysis** using @Generable types  
✅ **Data extraction** (contacts, keywords, entities)  
✅ **Text classification** into custom categories  
✅ **Dynamic schemas** for flexible data structures  
✅ **100% private** - local device processing  
✅ **Zero network latency** - no internet required  

### What the model does WELL:

- ✅ Text summarization
- ✅ Structured information extraction
- ✅ Classification and categorization
- ✅ Sentiment analysis
- ✅ Short/medium text generation
- ✅ Entity extraction

### What the model does NOT do:

- ❌ General world knowledge (uses server model)
- ❌ Complex mathematical reasoning
- ❌ Code generation
- ❌ Long responses (~4096 token limit)

---

##  Requirements

### Hardware

| Requirement | Specification |
|-----------|---------------|
| **iPhone** | 15 Pro, 15 Pro Max, 16, 16 Pro, 16 Pro Max |
| **iPad** | Models with M1 chip or later |
| **Storage** | Minimum 7 GB free space (model uses ~3 GB) |

### Software

| Requirement | Version |
|-----------|---------|
| **iOS** | 26.0 Beta or later |
| **Titanium SDK** | 12.0.0+ |
| **Xcode** | Version compatible with iOS 26 Beta |
| **Swift** | 5.9+ |

### Device Settings

- ✅ Apple Intelligence **ENABLED** in Settings
- ✅ Siri Language: English (US) or other supported
- ✅ Model fully **downloaded** (~3 GB)

⚠️ **IMPORTANT**: In order to work on Simulator, you need to enable Apple Intelligence on your Mac.

---

##  Installation

### 1. Install the module in your Titanium project

```bash
# Copy the compiled module to:
{YOUR_PROJECT}/modules/iphone/
```

### 2. Add to tiapp.xml

```xml
<modules>
    <module platform="iphone">ti.apple.intelligence</module>
</modules>
```

---

##  Configuration

### 1. Configure tiapp.xml

Edit your **`tiapp.xml`** and adapt for your project.

**REQUIRED sections:**

```xml
<ios>    
    <!-- Entitlements -->
    <entitlements>
        <dict>
            <key>com.apple.developer.foundation-models.access</key>
            <string>$(AppIdentifierPrefix)$(CFBundleIdentifier)</string>
            
            <key>com.apple.developer.foundation-models.on-device</key>
            <true/>
        </dict>
    </entitlements>
    
    <!-- Info.plist -->
    <plist>
        <dict>
            <key>NSAppleIntelligenceUsageDescription</key>
            <string>This app uses Apple Intelligence to process text locally.</string>
            
            <key>NSSupportsFoundationModels</key>
            <true/>
            
            <key>MinimumOSVersion</key>
            <string>26.0</string>
        </dict>
    </plist>
</ios>
```

### 2. Verify if on device

1. Open **Settings** > **Apple Intelligence & Siri**
2. Enable **Apple Intelligence**
3. Wait for model download to complete
4. Check available storage (needs 7+ GB)

---

##  Quick Start

### Basic Example

```javascript
const AppleAI = require('ti.apple.intelligence');

// 1. Check availability (property, no parentheses!)
if (!AppleAI.isAvailable) {
    alert('Apple Intelligence not available');
    return;
}

// 2. Wait for model to be ready (IMPORTANT!)
AppleAI.waitForModel({
    maxAttempts: 15,
    delay: 2.0,
    callback: (result) => {
        if (result.ready) {
            // 3. Now you can use it!
            generateText();
        } else {
            alert('Model not ready: ' + result.error);
        }
    }
});

function generateText() {
    AppleAI.generateText({
        prompt: 'Explain AI in 2 sentences.',
        callback: (result) => {
            if (result.success) {
                console.log('Response:', result.text);
            } else {
                console.error('Error:', result.error);
            }
        }
    });
}
```

### Example with Structured Analysis

```javascript
// Article analysis with structured data
AppleAI.analyzeArticle({
    text: myText,
    callback: (result) => {
        if (result.success) {
            console.log('Title:', result.data.titulo);
            console.log('Summary:', result.data.resumo);
            console.log('Sentiment:', result.data.sentimento);
            console.log('Key Points:', result.data.pontosChave);
            console.log('Topics:', result.data.topicos);
        }
    }
});
```

### Example with Custom Schema

```javascript
// Flexible schema for specific cases
const schema = {
    rating: {
        type: 'number',
        description: 'Rating from 0 to 10',
        required: true
    },
    recommends: {
        type: 'boolean',
        description: 'Whether it recommends',
        required: true
    },
    aspects: {
        type: 'array',
        items: 'string',
        description: 'Positive aspects'
    }
};

AppleAI.generateWithSchema({
    prompt: `Analyze this review: "${review}"`,
    schema: schema,
    callback: (result) => {
        if (result.success) {
            console.log('Rating:', result.data.rating);
            console.log('Recommends:', result.data.recommends);
        }
    }
});
```

---

##  Troubleshooting

### ❌ Error: "GenerationError -1"

This is the most common error. It means the model is not actually ready.

**Solution**: Read the complete guide **`TROUBLESHOOTING-ERROR-1.md`**

**Quick Fix:**

1. Check if entitlements are in tiapp.xml
2. Check if Info.plist has required permissions
3. Use `waitForModel()` before any operation
4. Confirm Apple Intelligence is enabled on your iPhone or Mac

### ❌ Error: "is not a function"

**Problem**: Methods without parameters are properties in Titanium.

**Solution**: Use without parentheses:

```javascript
// ❌ WRONG
const status = AppleAI.getAvailabilityStatus();

// ✅ CORRECT
const status = AppleAI.availabilityStatus;
```

Read: **`TITANIUM-PROPERTIES-VS-METHODS.md`**

### ❌ Model doesn't become ready

**Possible solutions:**

1. Restart the device
2. Disable and re-enable Apple Intelligence
3. Check if download completed (Settings > Storage)
4. Free up more space (7+ GB needed)
5. Wait longer (model may still be preparing)

### 🔍 Diagnostics

Use the diagnostics method to investigate:

```javascript
const diag = AppleAI.diagnostics();
console.log(JSON.stringify(diag, null, 2));

// Returns detailed information:
// - iOS version
// - Device model
// - Model status
// - Free space
// - Unavailability reason (if any)
```

---

##  Documentation

### Included files:

| File | Description |
|---------|-----------|
| [`STRUCTURED-GENERATION-GUIDE.md`](https://github.com/deckameron/Apple-Intelligence-for-Titanium-SDK/blob/main/documentation/STRUCTURED-GENERATION-GUIDE-EN.md) | Complete schema guide |
| [`TITANIUM-PROPERTIES-VS-METHODS.md`](https://github.com/deckameron/Apple-Intelligence-for-Titanium-SDK/blob/main/documentation/TITANIUM-PROPERTIES-VS-METHODS-EN.md) | Understanding Titanium conventions |
| [`TROUBLESHOOTING-ERROR-1.md`](https://github.com/deckameron/Apple-Intelligence-for-Titanium-SDK/blob/main/documentation/TROUBLESHOOTING-ERROR-1-EN.md) | Solving GenerationError -1 |

### API Reference

#### Properties

```javascript
AppleAI.isAvailable                 // Bool - If available
AppleAI.availabilityStatus          // Object - Detailed status
```

#### Main Methods

```javascript
AppleAI.checkAvailability()         // Alternative check
AppleAI.diagnostics()               // Complete diagnostics
AppleAI.waitForModel({...})         // Wait for model to be ready
AppleAI.createSession({...})        // Create session with instructions
AppleAI.generateText({...})         // Generate text
AppleAI.streamText({...})           // Real-time streaming
AppleAI.summarize({...})            // Summarize text
```

#### Methods with @Generable

```javascript
AppleAI.analyzeArticle({...})       // Structured analysis
AppleAI.extractContacts({...})      // Contact extraction
AppleAI.classifyText({...})         // Classification
AppleAI.extractKeywords({...})      // Keywords
AppleAI.generateWithSchema({...})   // Dynamic schema
```

---

##  Examples

### 1. Robust Verification

Use **`example-robust-verification.js`** as base:

```javascript
const helpers = require('example-robust-verification');

helpers.checkModelReady((status) => {
    if (status.ready) {
        // Model ready, can use!
        AppleAI.generateText({...});
    } else {
        alert(status.error);
    }
});
```

### 2. Feedback Analysis

```javascript
AppleAI.classifyText({
    text: userFeedback,
    categories: ['positive', 'negative', 'bug', 'suggestion'],
    callback: (result) => {
        if (result.success) {
            // Take action based on category
            processFeedback(result.categoria, result.confianca);
        }
    }
});
```

### 3. Data Extraction

```javascript
AppleAI.extractContacts({
    text: emailText,
    callback: (result) => {
        if (result.success) {
            // Save contacts to database
            result.contatos.forEach(contact => {
                saveContact(contact);
            });
        }
    }
});
```

---

##  Implementation Checklist

Before starting, verify:

- [ ] iOS 26+ installed on device
- [ ] Compatible hardware (iPhone 15 Pro+ or iPad M1+)
- [ ] Apple Intelligence enabled on device
- [ ] Model fully downloaded
- [ ] 7+ GB free space
- [ ] tiapp.xml configured with entitlements
- [ ] Info.plist with required permissions
- [ ] Module installed in project
- [ ] Using `waitForModel()` before operations

---

##  Best Practices

### ✅ DO

1. **Always** use `waitForModel()` before operations
2. **Always** check `isAvailable` first
3. **Always** handle errors in callbacks
4. Use pre-defined @Generable types when possible
5. Test on real physical device if possible
6. Keep prompts clear and concise
7. Use streaming for responsive UIs
8. Release sessions when no longer needed

### ❌ DON'T

1. Don't rely only on `isAvailable` (use `waitForModel`)
2. Don't use on simulator (doesn't work)
3. Don't make multiple simultaneous requests
4. Don't create overly complex/nested schemas
5. Don't expect general world knowledge
6. Don't send texts larger than ~3000 words
7. Don't ignore callback errors
8. Don't forget to check `result.success`

---

##  Support

### Problems?

1. Read **`TROUBLESHOOTING-ERROR-1.md`** first
2. Run diagnostics script: `AppleAI.diagnostics()`
3. Check logs with `console.log`
4. Test complete example: `example-robust-verification.js`

### Frequently Asked Questions

**Q: Does it work on Simulator?**  
A: ✅ Yes. But Apple Intelligence must be ON on your Mac.

**Q: Does it need internet?**  
A: ❌ No. 100% local processing.

**Q: Can I use it offline?**  
A: ✅ Yes! Works 100% offline after model download.

**Q: How much space does it use?**  
A: ~3 GB for model, 7+ GB free recommended.

**Q: Which languages does it support?**  
A: English, Portuguese, Spanish, French, German, among others.

**Q: Does the model learn from my usage?**  
A: ❌ No. The model is fixed and doesn't change.

---

**Version**: 1.0.0  
**Last Updated**: December 2025  
**Compatibility**: iOS 26.0+, Titanium SDK 13.0.1+