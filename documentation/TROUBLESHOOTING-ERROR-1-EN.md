#  Troubleshooting: FoundationModels GenerationError -1

## The Error

```
The operation couldn't be completed. 
(FoundationModels.LanguageModelSession.GenerationError error -1.)
```

This is the most common error when using the Foundation Models framework and usually indicates that the model is not actually ready, even though `isAvailable` returns `true`.

## Solutions (in priority order)

### 1️⃣ Configure Entitlements

The Titanium module needs the correct entitlements. Create or edit the `Entitlements.plist` file in your project:

**tiapp.xml - Add the entitlements section:**

```xml
<ios>
    <entitlements>
        <dict>
            <!-- Foundation Models / Apple Intelligence -->
            <key>com.apple.developer.foundation-models.access</key>
            <string>$(AppIdentifierPrefix)$(CFBundleIdentifier)</string>
            
            <!-- Allow local model access -->
            <key>com.apple.developer.foundation-models.on-device</key>
            <true/>
        </dict>
    </entitlements>
</ios>
```

### 2️⃣ Configure Info.plist

Add required permissions in `tiapp.xml`:

```xml
<ios>
    <plist>
        <dict>
            <!-- AI usage description -->
            <key>NSAppleIntelligenceUsageDescription</key>
            <string>This app uses Apple Intelligence to process text and provide intelligent responses locally on the device.</string>
            
            <!-- Allow Foundation Models -->
            <key>NSSupportsFoundationModels</key>
            <true/>
            
            <!-- Minimum iOS -->
            <key>MinimumOSVersion</key>
            <string>26.0</string>
        </dict>
    </plist>
</ios>
```

### 3️⃣ Verify System Requirements

**MANDATORY Requirements:**
- iOS 26.0 Beta or later
- iPhone 15 Pro / 15 Pro Max / 16 / 16 Pro (or iPad with M1+)
- Siri Language: English (US), Portuguese (BR), or other supported
- Apple Intelligence ENABLED in Settings on your iPhone or Mac (Simulator)
- At least 7 GB free storage
- Model fully downloaded (may take time)

**Check on device:**
1. Settings > Apple Intelligence & Siri > Apple Intelligence
2. Make sure it's **ENABLED**
3. Verify the model has finished downloading

### 4️⃣ Add Robust Code Checks

Update the module with more detailed checks:

```swift
// Add diagnostics method
@objc(diagnostics:)
func diagnostics(args: [Any]?) -> [String: Any] {
    var info: [String: Any] = [:]
    
    if #available(iOS 26.0, *) {
        // Basic status
        info["ios_version"] = UIDevice.current.systemVersion
        info["device_model"] = UIDevice.current.model
        
        // Check availability
        let model = SystemLanguageModel.default
        info["is_available"] = model.isAvailable
        
        switch model.availability {
        case .available:
            info["status"] = "available"
            
            // Try creating a test session
            do {
                let testSession = LanguageModelSession()
                info["session_created"] = true
                
                // Try a simple operation
                Task {
                    do {
                        let _ = try await testSession.respond(to: "Test")
                        info["test_generation"] = "success"
                    } catch {
                        info["test_generation"] = "failed"
                        info["test_error"] = error.localizedDescription
                    }
                }
            } catch {
                info["session_created"] = false
                info["session_error"] = error.localizedDescription
            }
            
        case .unavailable(let reason):
            info["status"] = "unavailable"
            switch reason {
            case .appleIntelligenceNotEnabled:
                info["reason"] = "not_enabled"
                info["fix"] = "Enable Apple Intelligence in Settings"
            case .deviceNotEligible:
                info["reason"] = "device_not_eligible"
                info["fix"] = "Requires iPhone 15 Pro+ or iPad M1+"
            case .modelNotReady:
                info["reason"] = "model_downloading"
                info["fix"] = "Wait for model download to complete"
            @unknown default:
                info["reason"] = "unknown"
            }
        }
        
        // Check disk space
        if let space = try? FileManager.default.attributesOfFileSystem(
            forPath: NSHomeDirectory()
        )[.systemFreeSize] as? Int64 {
            let gb = Double(space) / 1_000_000_000
            info["free_space_gb"] = String(format: "%.1f", gb)
            info["enough_space"] = gb >= 7.0
        }
        
    } else {
        info["error"] = "iOS 26+ required"
    }
    
    return info
}

// Add method to wait for model to be ready
@objc(waitForModel:)
func waitForModel(args: [Any]?) {
    guard #available(iOS 26.0, *),
          let dict = args?.first as? [String: Any],
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
            // Try creating a test session
            do {
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
                        // Model not really ready yet
                        if attempts < maxAttempts {
                            DispatchQueue.main.asyncAfter(deadline: .now() + delaySeconds) {
                                checkAvailability()
                            }
                        } else {
                            DispatchQueue.main.async {
                                callback.call([[
                                    "ready": false,
                                    "error": "Timeout waiting for model",
                                    "attempts": attempts
                                ]], thisObject: nil)
                            }
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    callback.call([[
                        "ready": false,
                        "error": error.localizedDescription,
                        "attempts": attempts
                    ]], thisObject: nil)
                }
            }
            
        case .unavailable(let reason):
            DispatchQueue.main.async {
                var reasonStr = ""
                switch reason {
                case .appleIntelligenceNotEnabled:
                    reasonStr = "Apple Intelligence is not enabled"
                case .deviceNotEligible:
                    reasonStr = "Device is not eligible"
                case .modelNotReady:
                    reasonStr = "Model still downloading"
                @unknown default:
                    reasonStr = "Unknown reason"
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
```

### 5️⃣ Use Robust Check in JavaScript

```javascript
const AppleAI = require('ti.apple.intelligence');

// Helper function to check if really ready
function checkModelReady(callback) {
    // First, basic availability check
    if (!AppleAI.isAvailable) {
        const status = AppleAI.availabilityStatus;
        callback({
            ready: false,
            error: 'Apple Intelligence not available: ' + status.reason
        });
        return;
    }
    
    // Run full diagnostics
    const diag = AppleAI.diagnostics();
    console.log('=== DIAGNOSTICS ===');
    console.log(JSON.stringify(diag, null, 2));
    
    // If diagnostics indicate problems
    if (!diag.is_available) {
        callback({
            ready: false,
            error: 'Model not available: ' + (diag.reason || 'unknown'),
            diagnostics: diag
        });
        return;
    }
    
    // Wait for model to be really ready
    console.log('Waiting for model to be ready...');
    AppleAI.waitForModel({
        maxAttempts: 15,  // Try for up to 30 seconds
        delay: 2.0,       // Check every 2 seconds
        callback: (result) => {
            if (result.ready) {
                console.log('✅ Model ready after', result.attempts, 'attempts');
                callback({ ready: true });
            } else {
                console.error('❌ Model not ready:', result.error);
                callback({
                    ready: false,
                    error: result.error,
                    attempts: result.attempts
                });
            }
        }
    });
}

// Use before any operation
checkModelReady((status) => {
    if (status.ready) {
        // Now it's safe to use the model!
        AppleAI.generateText({
            prompt: 'Hello, how are you?',
            callback: (result) => {
                if (result.success) {
                    console.log('Response:', result.text);
                } else {
                    console.error('Error:', result.error);
                }
            }
        });
    } else {
        alert('Model not ready: ' + status.error);
        
        // Show diagnostics to user
        if (status.diagnostics) {
            console.log('Suggestion:', status.diagnostics.fix || 'Check settings');
        }
    }
});
```

### 6️⃣ Xcode Configuration (if compiling manually)

If you're compiling the module manually in Xcode:

1. **Target > Signing & Capabilities**
2. Add capability: **Foundation Models**
3. **Build Settings > Other Linker Flags**: add `-framework FoundationModels`

### 7️⃣ Testing on Real Device if Possible

- iPhone 15 Pro or later
- iPad with M1 chip or later
- Running iOS 26 Beta

### 8️⃣ Verify Model Download

The AI model is large (~3GB) and may take time to download:

**On device:**
1. Settings > General > iPhone Storage
2. Look for "Apple Intelligence" or "Foundation Models"
3. Verify download is complete

**Force download (if needed):**
1. Settings > Apple Intelligence & Siri
2. Disable and re-enable Apple Intelligence
3. Wait a few minutes

##  Complete Test Script

```javascript
const AppleAI = require('ti.apple.intelligence');

function completeTest() {
    console.log('=== STARTING COMPLETE TEST ===\n');
    
    // 1. Basic check
    console.log('1️⃣ Basic check:');
    console.log('   isAvailable:', AppleAI.isAvailable);
    
    const status = AppleAI.availabilityStatus;
    console.log('   Status:', status.available ? '✅ Available' : '❌ Unavailable');
    console.log('   Reason:', status.reason);
    
    if (!status.available) {
        console.log('\n❌ Cannot continue. Reason:', status.reason);
        alert('Apple Intelligence not available: ' + status.reason);
        return;
    }
    
    // 2. Detailed diagnostics
    console.log('\n2️⃣ Detailed diagnostics:');
    const diag = AppleAI.diagnostics();
    console.log('   iOS:', diag.ios_version);
    console.log('   Device:', diag.device_model);
    console.log('   Free Space:', diag.free_space_gb, 'GB');
    console.log('   Enough Space:', diag.enough_space ? '✅' : '❌');
    
    // 3. Wait for model
    console.log('\n3️⃣ Waiting for model to be ready...');
    AppleAI.waitForModel({
        maxAttempts: 20,
        delay: 2.0,
        callback: (result) => {
            if (result.ready) {
                console.log('   ✅ Model ready!');
                console.log('   Attempts:', result.attempts);
                
                // 4. Real test
                console.log('\n4️⃣ Running real test...');
                testGeneration();
            } else {
                console.log('   ❌ Model not ready');
                console.log('   Error:', result.error);
                console.log('   Attempts:', result.attempts);
                alert('Model not ready: ' + result.error);
            }
        }
    });
}

function testGeneration() {
    AppleAI.generateText({
        prompt: 'Say hello in a short sentence.',
        callback: (result) => {
            if (result.success) {
                console.log('   ✅ SUCCESS!');
                console.log('   Response:', result.text);
                alert('It worked! Response: ' + result.text);
            } else {
                console.log('   ❌ ERROR in generation');
                console.log('   Error:', result.error);
                alert('Error: ' + result.error);
            }
        }
    });
}

// Run test
completeTest();
```

##  Verification Checklist

Before using the module, make sure:

- [ ] iOS 26 Beta installed
- [ ] iPhone 15 Pro+ or iPad M1+
- [ ] Apple Intelligence ENABLED in Settings
- [ ] Siri language configured correctly
- [ ] At least 7 GB free space
- [ ] Model fully downloaded
- [ ] Entitlements configured in tiapp.xml
- [ ] NSAppleIntelligenceUsageDescription in Info.plist
- [ ] Testing on REAL device if possible
- [ ] App signed correctly

##  Common Problems

### "Model not ready" even after waiting
**Solution**: Restart device. Sometimes iOS needs a restart to finalize setup.

### "Device not eligible"
**Solution**: You need newer hardware. iPhone 15 Pro minimum.

### "Apple Intelligence not enabled"
**Solution**: Settings > Apple Intelligence & Siri > Enable

### Error persists after everything configured
**Solution**: 
1. Completely uninstall the app
2. Clean Titanium project
3. Rebuild and reinstall
4. Restart device


##  Executive Summary

**Error `-1` means**: The model is not ready for real use, even though basic APIs say it's available.

**Quick solution**:
1. Add entitlements in tiapp.xml
2. Add permissions in Info.plist
3. Use `waitForModel()` before generating text
4. Test on real device with iOS 26 Beta
5. Ensure Apple Intelligence is enabled and model downloaded