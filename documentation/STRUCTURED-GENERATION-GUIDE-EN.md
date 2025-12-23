# Structured Generation with @Generable - Complete Guide

##  Overview

The `ti.apple.intelligence` module offers two ways to get structured data from Apple's AI model:

### 1️⃣ **Pre-defined @Generable Types** (Recommended)
- **Performance**: Faster and more reliable
- **Type-safety**: Guaranteed by Swift at compile-time
- **Usage**: Specific methods like `analyzeArticle()`, `extractContacts()`
- **Ideal for**: Common and recurring use cases

### 2️⃣ **Dynamic Schema**
- **Flexibility**: Define custom structures at runtime
- **Performance**: Slightly slower (uses prompt engineering)
- **Usage**: `generateWithSchema()` method
- **Ideal for**: Unique cases or rapid experimentation

---

##  Pre-defined @Generable Types

### ArticleAnalysis
Complete analysis of articles and long texts.

**Returned structure:**
```javascript
{
    titulo: String,           // Main title/subject
    resumo: String,           // Summary in 2-3 sentences
    pontosChave: [String],    // 3-5 main points
    sentimento: String,       // 'positivo', 'neutro', 'negativo', 'misto'
    topicos: [String]         // 2-4 main topics
}
```

**Usage example:**
```javascript
AppleAI.analyzeArticle({
    text: myText,
    callback: (result) => {
        if (result.success) {
            console.log(result.data.titulo);
            console.log(result.data.resumo);
            // ... use other fields
        }
    }
});
```

### ContactExtraction
Extracts contact information from texts (emails, documents, etc).

**Returned structure:**
```javascript
{
    contatos: [
        {
            nome: String,        // Full name
            email: String?,      // Email (optional)
            telefone: String?,   // Phone (optional)
            empresa: String?     // Company (optional)
        }
    ]
}
```

**Usage example:**
```javascript
AppleAI.extractContacts({
    text: emailText,
    callback: (result) => {
        result.contatos.forEach(contact => {
            console.log(contact.nome, contact.email);
        });
    }
});
```

### TextClassification
Classifies text into predefined categories.

**Returned structure:**
```javascript
{
    categoria: String,        // Chosen category
    confianca: Number,        // 0.0 to 1.0
    explicacao: String        // Justification
}
```

**Usage example:**
```javascript
AppleAI.classifyText({
    text: comment,
    categories: ['positive', 'negative', 'neutral', 'question', 'bug'],
    callback: (result) => {
        console.log(`${result.categoria} (${result.confianca * 100}%)`);
    }
});
```

### KeywordExtraction
Extracts relevant keywords from texts.

**Returned structure:**
```javascript
{
    keywords: [String]    // List of keywords
}
```

**Usage example:**
```javascript
AppleAI.extractKeywords({
    text: description,
    maxKeywords: 5,
    callback: (result) => {
        console.log('Tags:', result.keywords.join(', '));
    }
});
```

---

##  Dynamic Schema

For cases where you need a custom structure, use `generateWithSchema()`.

### Defining a Schema

```javascript
const mySchema = {
    field1: {
        type: 'string',              // Types: 'string', 'number', 'boolean', 'array'
        description: 'Description',   // Helps model understand
        required: true,               // If it's required
        options: ['op1', 'op2']      // Allowed values (optional)
    },
    field2: {
        type: 'array',
        items: 'string',             // Array item type
        description: 'List of items',
        required: false
    },
    field3: {
        type: 'number',
        description: 'Numeric value from 0 to 10',
        required: true
    }
};
```

### Supported Types

| Type | Description | Example |
|------|-----------|---------|
| `string` | Text | `"Hello"` |
| `number` | Number | `42` or `3.14` |
| `boolean` | Boolean | `true` or `false` |
| `array` | List | `["item1", "item2"]` |

### Optional Fields

- **type**: Field type (default: `'string'`)
- **description**: Guidance for the model
- **required**: If it's required (default: `false`)
- **options**: List of valid values (for enums)
- **items**: Type of array elements

### Complete Example

```javascript
// Schema for movie review analysis
const reviewSchema = {
    movie_title: {
        type: 'string',
        description: 'Name of the movie mentioned',
        required: true
    },
    rating: {
        type: 'number',
        description: 'Rating from 0 to 10 given by reviewer',
        required: true
    },
    positive_aspects: {
        type: 'array',
        items: 'string',
        description: 'Positive points mentioned',
        required: false
    },
    negative_aspects: {
        type: 'array',
        items: 'string',
        description: 'Negative points mentioned',
        required: false
    },
    recommends: {
        type: 'boolean',
        description: 'Whether reviewer recommends the movie',
        required: true
    },
    movie_type: {
        type: 'string',
        description: 'Main genre of the movie',
        options: ['action', 'comedy', 'drama', 'horror', 'scifi', 'romance'],
        required: false
    }
};

// Use the schema
AppleAI.generateWithSchema({
    prompt: `Analyze this review: "${reviewText}"`,
    schema: reviewSchema,
    callback: (result) => {
        if (result.success) {
            const data = result.data;
            console.log('Movie:', data.movie_title);
            console.log('Rating:', data.rating);
            console.log('Recommends?', data.recommends ? 'Yes' : 'No');
            console.log('Positive:', data.positive_aspects);
            console.log('Negative:', data.negative_aspects);
        }
    }
});
```

---

##  Practical Use Cases

### 1. App Feedback Analysis

```javascript
const feedbackSchema = {
    type: {
        type: 'string',
        options: ['praise', 'criticism', 'bug', 'suggestion', 'question'],
        required: true
    },
    priority: {
        type: 'string',
        options: ['low', 'medium', 'high', 'critical'],
        required: true
    },
    features_mentioned: {
        type: 'array',
        items: 'string',
        description: 'App features mentioned',
        required: false
    },
    sentiment: {
        type: 'number',
        description: 'Sentiment from -1 (negative) to 1 (positive)',
        required: true
    },
    short_summary: {
        type: 'string',
        description: 'Summary in one sentence',
        required: true
    }
};

function analyzeFeedback(text) {
    AppleAI.generateWithSchema({
        prompt: `Analyze this user app feedback: "${text}"`,
        schema: feedbackSchema,
        callback: (r) => {
            if (r.success) {
                // Save to ticket system
                createTicket({
                    type: r.data.type,
                    priority: r.data.priority,
                    features: r.data.features_mentioned,
                    summary: r.data.short_summary
                });
                
                // Notify team if critical
                if (r.data.priority === 'critical') {
                    notifyTeam(r.data);
                }
            }
        }
    });
}
```

### 2. Recipe Data Extraction

```javascript
const recipeSchema = {
    name: {
        type: 'string',
        description: 'Recipe name',
        required: true
    },
    prep_time_minutes: {
        type: 'number',
        description: 'Preparation time in minutes',
        required: true
    },
    servings: {
        type: 'number',
        description: 'Number of servings',
        required: true
    },
    ingredients: {
        type: 'array',
        items: 'string',
        description: 'List of ingredients with quantities',
        required: true
    },
    instructions: {
        type: 'array',
        items: 'string',
        description: 'Preparation steps',
        required: true
    },
    difficulty: {
        type: 'string',
        options: ['easy', 'medium', 'hard'],
        required: true
    },
    dish_type: {
        type: 'string',
        options: ['appetizer', 'main_course', 'dessert', 'beverage', 'snack'],
        required: true
    }
};

function extractRecipe(text) {
    AppleAI.generateWithSchema({
        prompt: `Extract data from this recipe: "${text}"`,
        schema: recipeSchema,
        callback: (r) => {
            if (r.success) {
                saveRecipe(r.data);
            }
        }
    });
}
```

### 3. Social Media Post Analysis

```javascript
const socialSchema = {
    overall_sentiment: {
        type: 'string',
        options: ['very_positive', 'positive', 'neutral', 'negative', 'very_negative'],
        required: true
    },
    topics: {
        type: 'array',
        items: 'string',
        description: 'Main topics discussed',
        required: true
    },
    mentions: {
        type: 'array',
        items: 'string',
        description: 'People or brands mentioned',
        required: false
    },
    suggested_hashtags: {
        type: 'array',
        items: 'string',
        description: 'Relevant hashtags for the post',
        required: false
    },
    engagement_potential: {
        type: 'string',
        options: ['low', 'medium', 'high', 'viral'],
        required: true
    },
    best_time: {
        type: 'string',
        description: 'Best time to post',
        options: ['morning', 'afternoon', 'evening', 'late_night'],
        required: false
    }
};
```

### 4. Event Extraction from Text

```javascript
const eventSchema = {
    event_title: {
        type: 'string',
        description: 'Event name',
        required: true
    },
    date: {
        type: 'string',
        description: 'Date in YYYY-MM-DD format',
        required: false
    },
    time: {
        type: 'string',
        description: 'Event time',
        required: false
    },
    location: {
        type: 'string',
        description: 'Event location',
        required: false
    },
    participants: {
        type: 'array',
        items: 'string',
        description: 'People who will participate',
        required: false
    },
    type: {
        type: 'string',
        options: ['meeting', 'conference', 'party', 'workshop', 'webinar', 'other'],
        required: true
    }
};

function extractEvent(text) {
    AppleAI.generateWithSchema({
        prompt: `Extract event information from this text: "${text}"`,
        schema: eventSchema,
        callback: (r) => {
            if (r.success) {
                // Add to calendar
                addToCalendar(r.data);
            }
        }
    });
}
```

---

##  Best Practices

### ✅ DO

1. **Use pre-defined types when possible**
   ```javascript
   // ✅ GOOD
   AppleAI.analyzeArticle({ text, callback });
   
   // ❌ UNNECESSARY
   AppleAI.generateWithSchema({ 
       prompt: "Analyze this article", 
       schema: articleSchema 
   });
   ```

2. **Be specific in descriptions**
   ```javascript
   // ✅ GOOD
   {
       rating: {
           description: 'Rating from 0 to 10, where 0 is terrible and 10 is excellent',
           type: 'number'
       }
   }
   
   // ❌ VAGUE
   {
       rating: {
           description: 'A rating',
           type: 'number'
       }
   }
   ```

3. **Use `options` for enums**
   ```javascript
   // ✅ GOOD
   {
       status: {
           type: 'string',
           options: ['active', 'inactive', 'pending']
       }
   }
   ```

4. **Validate the result**
   ```javascript
   callback: (result) => {
       if (result.success) {
           // Check required fields
           if (!result.data.important_field) {
               console.warn('Important field missing');
               // Use default value or ask again
           }
       }
   }
   ```

### ❌ DON'T

1. **Don't create overly complex schemas**
   ```javascript
   // ❌ BAD - Too deep
   {
       user: {
           type: 'object',  // ❌ Nested objects not supported
           properties: {
               name: { type: 'string' },
               address: {
                   type: 'object',
                   properties: { ... }
               }
           }
       }
   }
   
   // ✅ GOOD - Use flat fields
   {
       user_name: { type: 'string' },
       user_address_street: { type: 'string' },
       user_address_city: { type: 'string' }
   }
   ```

2. **Don't blindly trust the result**
   ```javascript
   // ❌ BAD
   const rating = result.data.rating;
   saveToDatabase(rating);  // What if rating is invalid?
   
   // ✅ GOOD
   const rating = parseFloat(result.data.rating);
   if (isNaN(rating) || rating < 0 || rating > 10) {
       console.error('Invalid rating:', result.data.rating);
       return;
   }
   saveToDatabase(rating);
   ```

3. **Don't ignore errors**
   ```javascript
   // ❌ BAD
   AppleAI.generateWithSchema({ prompt, schema, callback: (r) => {
       console.log(r.data);
   }});
   
   // ✅ GOOD
   AppleAI.generateWithSchema({ 
       prompt, 
       schema, 
       callback: (r) => {
           if (r.success) {
               process(r.data);
           } else {
               console.error('Error:', r.error);
               showFallback();
           }
       }
   });
   ```

---

##  Performance and Optimization

### Expected Times (approximate)

| Operation | Average time |
|----------|-------------|
| `analyzeArticle()` | 2-4s |
| `extractContacts()` | 1-3s |
| `classifyText()` | 1-2s |
| `extractKeywords()` | 1-2s |
| `generateWithSchema()` | 2-5s |

### Performance Tips

1. **Reuse sessions**
   ```javascript
   // Create a persistent session
   AppleAI.createSession({
       instructions: 'You are an assistant specialized in text analysis.'
   });
   
   // Use same session for multiple operations
   AppleAI.generateText({ prompt: '...', callback });
   AppleAI.generateText({ prompt: '...', callback });
   ```

2. **Batch processing with delays**
   ```javascript
   async function processBatch(texts) {
       for (let i = 0; i < texts.length; i++) {
           await processText(texts[i]);
           
           // Pause between processings
           if (i < texts.length - 1) {
               await sleep(500);  // 500ms between each
           }
       }
   }
   ```

3. **Limit text sizes**
   ```javascript
   function processText(text) {
       // Model has limit of ~4096 tokens (~3000 words)
       const MAX_CHARS = 12000;  // ~3000 words
       
       if (text.length > MAX_CHARS) {
           text = text.substring(0, MAX_CHARS) + '...';
       }
       
       AppleAI.analyzeArticle({ text: text, callback });
   }
   ```

---

##  Troubleshooting

### "Could not parse JSON"

**Problem**: Dynamic schema returned `warning: "Could not parse JSON"`

**Solutions**:
1. Simplify the schema (fewer fields)
2. Be more specific in descriptions
3. Use pre-defined types (@Generable) when possible
4. Rephrase prompt to be clearer

### Missing or incorrect fields

**Problem**: `result.data.field` is empty or has wrong value

**Solutions**:
1. Add more context to the prompt
2. Make the field `required: true`
3. Use `options` to restrict values
4. Check if text actually contains the information

### Slow performance

**Problem**: Operations taking more than 10s

**Solutions**:
1. Reduce text size
2. Simplify schema (fewer fields)
3. Check if device has available resources
4. Use `isResponding` before making new request

---

##  References

- [Apple Foundation Models Framework](https://developer.apple.com/videos/play/wwdc2025/286/)
- [Complete module documentation](./TiAppleIntelligenceModule.swift)
- [Usage examples](./examples-generable-usage.js)
- [Titanium SDK Docs](https://docs.appcelerator.com/)
