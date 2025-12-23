# 🔧 Properties vs Methods in Titanium Modules

## The problem you encountered

When you tried:
```javascript
const status = AppleAI.getAvailabilityStatus(); // ❌ ERROR
```

You received: `TypeError: AppleAI.getAvailabilityStatus is not a function`

## Why does this happen?

In Titanium SDK, **methods without parameters** are automatically exposed as **properties (getters)**, not as functions.

### Titanium Rule:

| Swift Code | How to use in JavaScript |
|--------------|-------------------------|
| `func method()` | `module.method` (no parentheses) |
| `func method(args: [Any]?)` | `module.method()` or `module.method(params)` |
| `var property: Type { }` | `module.property` (no parentheses) |

## Solution

### ✅ CORRECT - As property:

**Swift:**
```swift
@objc
var availabilityStatus: [String: Any] {
    // returns dictionary
    return ["available": true, "reason": "ready"]
}
```

**JavaScript:**
```javascript
const status = AppleAI.availabilityStatus; // ✅ NO parentheses
console.log(status.available); // true
console.log(status.reason);    // "ready"
```

### ✅ ALTERNATIVE - As method (with dummy parameter):

**Swift:**
```swift
@objc(checkAvailability:)
func checkAvailability(args: [Any]?) -> [String: Any] {
    return ["available": true, "reason": "ready"]
}
```

**JavaScript:**
```javascript
const status = AppleAI.checkAvailability(); // ✅ WITH parentheses
// or
const status = AppleAI.checkAvailability(null); // also works
```

## Corrected module examples

### ❌ BEFORE (didn't work):

```javascript
// Trying to use as function
if (AppleAI.isAvailable()) {  // ❌ ERROR!
    const status = AppleAI.getAvailabilityStatus();  // ❌ ERROR!
}
```

### ✅ AFTER (correct):

**Option 1 - As properties (recommended):**
```javascript
// Use as properties (without parentheses)
if (AppleAI.isAvailable) {  // ✅
    const status = AppleAI.availabilityStatus;  // ✅
    console.log(status.available);
    console.log(status.reason);
}
```

**Option 2 - As alternative method:**
```javascript
// Alternative method if you prefer using ()
const status = AppleAI.checkAvailability();  // ✅
if (status.available) {
    console.log('Apple Intelligence available!');
}
```

## When to use each approach?

### Use PROPERTIES (without parentheses) when:
- ✅ You're **reading a value/state**
- ✅ The operation is **instantaneous** (no processing)
- ✅ It's a **simple query**

**Examples:**
```javascript
const available = AppleAI.isAvailable;
const status = AppleAI.availabilityStatus;
const version = AppleAI.version;
```

### Use METHODS (with parentheses) when:
- ✅ You're **executing an action**
- ✅ The operation is **asynchronous** (with callback)
- ✅ You pass **parameters**

**Examples:**
```javascript
AppleAI.createSession({ instructions: '...' });
AppleAI.generateText({ prompt: '...', callback: (r) => {} });
AppleAI.summarize({ text: '...', callback: (r) => {} });
```

## Updated module - Quick reference

### Properties (use WITHOUT parentheses):
```javascript
const available = AppleAI.isAvailable;           // Bool
const status = AppleAI.availabilityStatus;        // Object {available, reason}
```

### Methods (use WITH parentheses):
```javascript
// Alternative check
AppleAI.checkAvailability();  // returns same as availabilityStatus

// Session
AppleAI.createSession({ instructions: '...' });

// Text generation
AppleAI.generateText({ 
    prompt: '...', 
    callback: (result) => {} 
});

AppleAI.streamText({ 
    prompt: '...' 
});

AppleAI.summarize({ 
    text: '...', 
    callback: (result) => {} 
});

// Structured generation
AppleAI.analyzeArticle({ 
    text: '...', 
    callback: (result) => {} 
});

AppleAI.extractContacts({ 
    text: '...', 
    callback: (result) => {} 
});

AppleAI.classifyText({ 
    text: '...', 
    categories: [...], 
    callback: (result) => {} 
});

AppleAI.extractKeywords({ 
    text: '...', 
    maxKeywords: 5, 
    callback: (result) => {} 
});

AppleAI.generateWithSchema({ 
    prompt: '...', 
    schema: {...}, 
    callback: (result) => {} 
});
```

## Complete updated example

```javascript
const AppleAI = require('ti.apple.intelligence');

// ✅ Check availability (property)
if (!AppleAI.isAvailable) {
    alert('Apple Intelligence not available');
    return;
}

// ✅ Get detailed status (property)
const status = AppleAI.availabilityStatus;
console.log('Available:', status.available);
console.log('Reason:', status.reason);

// OR use alternative method if you prefer
const statusAlt = AppleAI.checkAvailability();
console.log('Status:', statusAlt);

// ✅ Create session (method with parameters)
AppleAI.createSession({
    instructions: 'You are a helpful assistant.'
});

// ✅ Generate text (asynchronous method)
AppleAI.generateText({
    prompt: 'Explain artificial intelligence',
    callback: (result) => {
        if (result.success) {
            console.log('Response:', result.text);
        }
    }
});

// ✅ Analyze article (asynchronous method with @Generable)
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
```

## Professional tip

If you're creating your own Titanium modules and want to expose something as a **method** even without parameters, use this syntax:

```swift
// Exposes as METHOD (with parentheses in JS)
@objc(methodName:)
func methodName(args: [Any]?) -> ReturnType {
    // even if args is not used
    return value
}
```

The `:` at the end of `@objc(methodName:)` forces Titanium to treat it as a method.

## Summary

| Situation | Swift | JavaScript |
|----------|-------|------------|
| Getter/State | `var prop: Type { }` | `module.prop` |
| Method without param | `func method() { }` | `module.method` (becomes property!) |
| Force method | `@objc(method:)` `func method(args: [Any]?)` | `module.method()` |
| Method with params | `func method(args: [Any]?)` | `module.method(params)` |

**Remember**: In Titanium, if it has no parameters, it should probably be a property anyway! It's more idiomatic and clean.