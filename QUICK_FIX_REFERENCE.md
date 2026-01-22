# Quick Fix Reference: Silent Audio Validation

## Problem
100% accuracy for silent/empty audio recordings

## Solution Summary
Multi-layer validation on iOS and backend

---

## iOS Changes

### File: `AudioRecorder.swift`

**New Validation Thresholds**:
```swift
Minimum duration:     0.5 seconds
Minimum file size:    5,000 bytes (5KB)
Minimum peak level:   0.05 (normalized 0-1)
Minimum avg level:    0.02 (normalized 0-1)
```

**New Error Types**:
- `AudioRecordingError.recordingTooShort`
- `AudioRecordingError.recordingTooQuiet`
- `AudioRecordingError.fileTooSmall`

**How It Works**:
```swift
// Tracks audio levels during recording
private var peakAudioLevel: Float = 0.0
private var audioLevelSamples: [Float] = []

// Validates before returning file
func stopRecording() async throws -> URL {
    try validateRecordingQuality(...)
    return fileURL
}
```

---

## Backend Changes

### File: `lessonStep.controller.js`

**Added**:
```javascript
// Reject files < 5KB
if (audioFile.size < 5000) {
    throw new AppError('Audio file too small', 400);
}

// Early return for no speech
if (noSpeechDetected) {
    return res.json({ score: 0, passed: false });
}
```

### File: `geminiSTT.service.js` (CRITICAL FIX)

**Changed**:
```javascript
// Line 461 - THE FIX
languageMatch: false,  // Was: true ❌
```

**Why This Matters**:
- `languageMatch: true` → validation proceeds → possible 100% score
- `languageMatch: false` → treated as mismatch → max 10% score

---

## Testing

### Manual Test
```
1. Open app
2. Start recording
3. Stay silent for 2s
4. Stop recording
Expected: Error "No speech detected"
```

### Automated Test
```bash
cd language-luid-backend
node test-silent-audio-validation.js
```

---

## Adjusting Thresholds

If validation is too strict (rejecting valid speech):

### iOS (`AudioRecorder.swift`)
```swift
// Line 457: Lower minimum duration
let minimumDuration: TimeInterval = 0.3  // Was: 0.5

// Line 466: Lower file size threshold
let minimumFileSize: Int64 = 3_000  // Was: 5_000

// Line 476: Lower peak level threshold
let minimumPeakLevel: Float = 0.03  // Was: 0.05

// Line 486: Lower average level threshold
let minimumAverageLevel: Float = 0.01  // Was: 0.02
```

### Backend (`lessonStep.controller.js`)
```javascript
// Line 41: Lower file size threshold
const minAudioSize = 3000;  // Was: 5000
```

---

## Monitoring

### iOS Console Logs
```
✅ "Recording quality validation passed"
❌ "Recording too quiet: peak level 0.01 (minimum: 0.05)"
❌ "Recording too short: 0.3 seconds (minimum: 0.5)"
❌ "Recording file too small: 2048 bytes (minimum: 5000)"
```

### Backend Logs
```
✅ "STT result with language detection"
❌ "Audio file too small: 2048 bytes (minimum: 5000)"
❌ "No speech detected in audio - returning validation failure"
⚠️  "Fallback mode: Cannot verify language match"
```

---

## Rollback Plan

If fix causes issues:

1. **iOS Only**: Revert `AudioRecorder.swift` changes
2. **Backend Only**: Change `languageMatch: false` back to `true` (line 461)
3. **Full Rollback**: Revert all changes

---

## Quick Debugging

### Issue: Legitimate speech rejected

**Check**:
1. Audio level too low? → Lower `minimumPeakLevel`
2. Speaking too fast? → Lower `minimumDuration`
3. Device/environment issue? → Check microphone settings

### Issue: Silent audio still passing

**Check**:
1. iOS validation disabled? → Verify `validateRecordingQuality()` is called
2. Backend validation disabled? → Check file size validation
3. Fallback mode triggered? → Check `languageMatch` value in logs

---

## File Locations

```
iOS:
├── AudioRecorder.swift
│   └── /Source/Core/Audio/AudioRecorder.swift
└── SpeechValidationService.swift
    └── /Source/Services/SpeechValidationService.swift

Backend:
├── lessonStep.controller.js
│   └── /src/controllers/lessonStep.controller.js
├── geminiSTT.service.js (CRITICAL)
│   └── /src/services/geminiSTT.service.js
└── test-silent-audio-validation.js
    └── /test-silent-audio-validation.js
```

---

## Key Metrics

**Before Fix**:
- Silent audio → 100% score ❌
- Empty file → 100% score ❌
- 0.1s recording → 100% score ❌

**After Fix**:
- Silent audio → Error, no upload ✅
- Empty file → Error, no upload ✅
- 0.1s recording → Error, no upload ✅

---

## Related Files

- Full documentation: `BUGFIX_SILENT_AUDIO_VALIDATION.md`
- Summary: `BUGFIX_SUMMARY.md`
- Test suite: `test-silent-audio-validation.js`
