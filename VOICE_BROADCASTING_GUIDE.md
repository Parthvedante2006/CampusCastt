# Voice Broadcasting System - Complete Guide

## 🎙️ How Voice Broadcasting Works

### **Architecture Overview**

```
┌─────────────────┐        Socket.IO         ┌──────────────────┐
│  Moderator App  │ ──────────────────────► │  Backend Server  │
│  (Flutter)      │   Real-time PCM Audio    │  (Python/FastAPI)│
└─────────────────┘                         └──────────────────┘
         │                                           │
         │                                           ▼
         │                                   ┌──────────────┐
         │                                   │    FFmpeg    │
         │                                   │  Transcoder  │
         │                                   └──────────────┘
         │                                           │
         │                                           ▼
         │                                   ┌──────────────┐
         │                                   │ HLS Segments │
         │                                   │   (.ts/.m3u8)│
         │                                   └──────────────┘
         │                                           │
         ▼                                           │
┌─────────────────┐          HTTP GET          ◄────┘
│   Student App   │ ◄──────────────────────────
│   (Flutter)     │   Stream HLS Playlist
└─────────────────┘
```

---

## 🚀 For Students (Listeners)

### **1. View Live Announcements**

When you open a subscribed channel's detail page:
- **Live broadcasts** appear at the top with a red "LIVE NOW" badge
- You'll see:
  - 🔴 Live indicator (pulsing red dot)
  - Broadcast title and description
  - Animated waveform visualization
  - "Listen" button

### **2. Join a Live Broadcast**

1. **Tap on a live broadcast card** or click "Listen"
2. The **Live Player Screen** opens automatically
3. You'll see:
   - Channel name and live badge
   - Current listener count (real-time updates)
   - Large play/pause button
   - Buffering indicator while connecting

### **3. Listen to the Stream**

- Audio plays automatically when you join
- **Pause/Resume** using the center button
- **See live listener count** in real-time
- **Close anytime** - streams continue in background until you pause

### **4. Replay Past Announcements**

- Scroll down to **"Past Broadcasts"** section in Announcements tab
- Past broadcasts are marked with "PAST BROADCAST" tag
- **Tap to replay** - uses the same HLS streaming technology
- All past announcements are available indefinitely

---

## 🎤 For Moderators (Broadcasters)

### **1. Start Broadcasting**

Navigate to: **Channel Dashboard → GO LIVE**

1. **Enter Details:**
   - Title: "Important Campus Announcement"
   - Description: Brief summary (optional)

2. **Grant Permissions:**
   - Allow microphone access when prompted

3. **Tap "GO LIVE"**
   - Backend spins up FFmpeg process
   - Socket.IO connection established
   - Broadcast document created in Firestore
   - HLS streaming begins

### **2. During the Broadcast**

- **Mic is active** - speak clearly
- **See listener count** updating live
- **Audio waveform** shows you're transmitting
- **Timer** tracks broadcast duration

### **3. Stop Broadcasting**

1. **Tap "STOP"** button
2. System automatically:
   - Closes mic stream
   - Sends stop signal to backend
   - FFmpeg flushes final audio segments
   - Updates Firestore: `status: 'ended'`
   - **Preserves HLS files** for replay

---

## 🧪 Testing the System

### **Prerequisites**

✅ **Backend Server Running**
```powershell
cd d:\PARTH\CampusCastt\backend
python main.py
```

✅ **ngrok Tunnel Active** (for internet access)
```powershell
ngrok http 8000
```

✅ **Flutter App Config Updated**
Edit `lib/core/constants/app_config.dart`:
```dart
static const String serverUrl = 'https://YOUR-NGROK-URL.ngrok-free.app';
```

✅ **FFmpeg Installed**
```powershell
ffmpeg -version  # Should show version info
```

---

### **Test Scenario 1: Local Testing (Same Device)**

1. **Start Backend:**
   ```powershell
   cd backend
   uvicorn main:socket_app --host 0.0.0.0 --port 8000
   ```

2. **Run Flutter App:**
   ```powershell
   flutter run
   ```

3. **Login as Moderator** (channel owner)

4. **Start Broadcast:**
   - Go to Channel Dashboard → GO LIVE
   - Enter "Test Announcement"
   - Tap GO LIVE → speak into mic

5. **Check Backend Logs:**
   ```
   [broadcast_start] ✅ FFmpeg started for 'abc-123-def'
   [ffmpeg] Started broadcast 'abc-123-def' (PID 12345)
   ```

6. **Verify HLS Files Created:**
   ```powershell
   ls backend/hls_output/abc-123-def/
   # Should see: stream.m3u8, stream0.ts, stream1.ts, etc.
   ```

---

### **Test Scenario 2: Multi-User Testing (Real Broadcast)**

**Setup:**
- **Device A:** Moderator (broadcasts)
- **Device B:** Student (listens)
- **Both devices:** Connected to internet, using ngrok URL

**Steps:**

1. **Device A (Moderator):**
   - Login as channel owner
   - Go to GO LIVE screen
   - Start broadcast: "Live Test"
   - Speak continuously

2. **Device B (Student):**
   - Login as student
   - Subscribe to moderator's channel
   - Open channel detail page
   - Should see **red "LIVE NOW"** card at top
   - Tap "Listen"
   - Hear audio within 2-3 seconds

3. **Verify:**
   - ✅ Audio syncs properly
   - ✅ Listener count increases on moderator screen
   - ✅ Student can pause/resume
   - ✅ Both see same broadcast title

4. **Stop & Replay:**
   - Moderator taps STOP
   - Student sees broadcast move to "Past Broadcasts"
   - Student taps past broadcast
   - Should play same audio from HLS files

---

### **Test Scenario 3: Backend-Only Test (No Flutter)**

Use the provided test script:

```powershell
cd backend
python test_broadcast.py
```

This simulates a Flutter client:
- Connects via Socket.IO
- Sends `broadcast_start` event
- Streams dummy audio chunks
- Sends `broadcast_stop` event

**Expected Output:**
```
[socket] Connected to server
[broadcast_start] ✅ FFmpeg started for 'test001'
[audio_chunk] Sending chunk 1/100...
...
[broadcast_stop] ✅ FFmpeg stopped for 'test001'
```

**Check HLS Output:**
```powershell
ls backend/hls_output/test001/
# stream.m3u8, stream0.ts, stream1.ts, etc.
```

**Play in VLC:**
```powershell
# Copy the full URL
http://localhost:8000/stream/test001/stream.m3u8

# Open in VLC Media Player → Network Stream
```

---

## 📊 Key Technical Details

### **Audio Format**

| Stage | Format | Details |
|-------|--------|---------|
| **Flutter Mic** | Raw PCM | 16-bit LE, 44100 Hz, Mono |
| **Socket.IO Transmission** | Binary bytes | Uint8List chunks |
| **FFmpeg Input** | stdin pipe | Continuous PCM stream |
| **FFmpeg Output** | AAC in HLS | 128 kbps, segmented |
| **Student Playback** | HLS (.m3u8) | just_audio package |

### **Network Flow**

1. **Moderator → Backend:** WebSocket (Socket.IO) - Real-time
2. **Backend → FFmpeg:** stdin pipe - Process communication
3. **Student → Backend:** HTTP GET - Standard file serving

### **File Structure**

```
backend/hls_output/
├── broadcast-id-1/
│   ├── stream.m3u8      ← Master playlist
│   ├── stream0.ts       ← Audio segment 1
│   ├── stream1.ts       ← Audio segment 2
│   └── stream2.ts       ← Audio segment 3
│
├── broadcast-id-2/
│   └── ...
```

- **Each segment:** 2 seconds of audio (configurable in `config.py`)
- **Playlist keeps:** Last 5 segments (rolling window for live)
- **After broadcast ends:** All segments preserved for replay

### **Firestore Schema**

**Broadcast Document:**
```javascript
{
  broadcastId: "abc-123-def",
  channelId: "ch001",
  streamUrl: "https://server.com/stream/abc-123-def/stream.m3u8",
  title: "Important Announcement",
  description: "Campus update",
  status: "live" | "ended",
  listeners: 15,
  startedAt: Timestamp,
  endedAt: Timestamp | null
}
```

---

## 🔧 Troubleshooting

### **Issue: Student Can't Hear Audio**

**Check:**
1. ✅ Backend server running?
2. ✅ ngrok tunnel active?
3. ✅ AppConfig.serverUrl correct?
4. ✅ Firewall blocking port 8000?
5. ✅ FFmpeg process active? (`ps aux | grep ffmpeg`)

**Fix:**
```powershell
# Restart backend
cd backend
uvicorn main:socket_app --reload --host 0.0.0.0 --port 8000
```

---

### **Issue: "Broadcast Not Found" Error**

**Cause:** Firestore document not created or wrong broadcastId

**Fix:**
1. Check Firestore Console → `broadcasts` collection
2. Verify document exists with correct ID
3. Check backend logs for creation errors

---

### **Issue: Audio Cuts Out / Buffering**

**Causes:**
- Slow internet connection
- FFmpeg can't keep up
- Segments too large

**Fix:**
Edit `backend/config.py`:
```python
HLS_SEGMENT_TIME = 1  # Smaller segments (was 2)
HLS_LIST_SIZE = 10    # More segments buffered
```

---

### **Issue: Past Broadcasts Won't Replay**

**Check:**
1. ✅ HLS files still on disk?
   ```powershell
   ls backend/hls_output/<broadcast-id>/
   ```
2. ✅ `streamUrl` field populated in Firestore?
3. ✅ Static file mounting working?

**Fix:**
- Don't delete HLS output folders
- Ensure `streamUrl` saved in `createBroadcast()`

---

## 🎯 Configuration Options

### **Backend (`backend/config.py`)**

```python
# Segment duration (seconds)
HLS_SEGMENT_TIME = 2

# Number of segments in rolling playlist
HLS_LIST_SIZE = 5

# Output folder
HLS_OUTPUT_DIR = "backend/hls_output"

# FFmpeg executable
FFMPEG_PATH = "ffmpeg"  # Use full path if not in PATH
```

### **Flutter (`lib/core/constants/app_config.dart`)**

```dart
class AppConfig {
  // Backend server URL (update with ngrok)
  static const String serverUrl = 'https://abc123.ngrok-free.app';
  
  // Firebase configuration
  // ...
}
```

---

## 📱 Features Summary

✅ **Live Voice Broadcasting**
✅ **Real-time HLS Streaming**
✅ **Multi-listener Support**
✅ **Live Listener Count**
✅ **Automatic Recording for Replay**
✅ **Beautiful UI with Animations**
✅ **Pause/Resume Controls**
✅ **Error Handling & Recovery**
✅ **Network Resilience (HLS buffering)**

---

## 🔐 Security Considerations (Production)

Before deploying to production:

1. **Lock Down CORS:**
   ```python
   ALLOWED_ORIGINS = ["https://yourapp.com"]
   ```

2. **Add Authentication:**
   - Verify Firebase ID tokens in backend
   - Only channel owners can broadcast

3. **Rate Limiting:**
   - Prevent spam broadcasts
   - Limit concurrent connections

4. **Storage Management:**
   - Auto-delete old HLS files (30+ days)
   - Archive to cloud storage (S3, GCS)

5. **HTTPS Only:**
   - Deploy behind nginx with SSL
   - Use Let's Encrypt certificates

---

## 📞 Support

For issues or questions:
1. Check logs: Backend terminal + Flutter debug console
2. Verify all requirements installed (FFmpeg, Python packages, Flutter packages)
3. Test with `test_broadcast.py` first to isolate issues

**Happy Broadcasting! 🎉**
