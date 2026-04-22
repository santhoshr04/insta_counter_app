Create a production-ready Flutter application named "InstaCounter Pro".

### 🎯 App Goal

A premium IoT companion app to control an ESP32-based split-flap Instagram follower display device.

---

### 🧱 Core Requirements

Build a modern, clean, dark-themed Flutter app with the following architecture:

* State Management: Provider (or Riverpod if preferred)
* Folder Structure:

  * /core (theme, constants, utils)
  * /features

    * /auth (dummy profile/login)
    * /device (scan, connect, wifi setup)
    * /dashboard (counter + controls)
    * /analytics (dummy insights)
  * /widgets (reusable UI components)

---

### 🎨 UI/UX Design

* Dark premium UI (black + subtle gradients)
* Large animated counter (split-flap style feel)
* Smooth animations using AnimatedSwitcher / Tween
* Rounded cards, modern spacing
* Responsive layout

---

### 📱 Screens to Build

#### 1. Splash Screen

* App logo
* Auto navigate to Home

---

#### 2. Home / Dashboard Screen

* Large animated follower counter
* Buttons:

  * +250
  * +2.5k
  * +10k
  * Reset
* Slider to control count
* Toggle:

  * Pause live updates
  * Speed control (slow / normal / fast)

---

#### 3. Device Scan Screen (Dummy for now)

* List of mock devices:

  * ESP32_Device_1
  * ESP32_Cafe_Display
* Button: "Scan Devices"
* Simulate loading animation
* Tap → Connect

---

#### 4. Device Setup Screen

* Input fields:

  * WiFi Name (SSID)
  * Password
* Button: "Send to Device"
* Show success message (mock)

---

#### 5. Analytics Screen (Dummy Data)

* Cards:

  * Total Followers
  * Growth Today
  * Weekly Growth
* Simple chart (use placeholder data)

---

#### 6. Profile Screen (Dummy)

* Profile image (placeholder)
* Name: "Demo User"
* Email: [demo@email.com](mailto:demo@email.com)
* Settings list:

  * Change Theme
  * Device Settings
  * Logout

---

### 🔄 Navigation

Use Bottom Navigation Bar with 4 tabs:

* Dashboard
* Devices
* Analytics
* Profile

---

### ⚙️ Functionality (IMPORTANT)

* Maintain a global "count" state
* All UI updates reflect count changes
* Slider, buttons, and toggles should sync
* Simulate live updates (timer increasing count every few seconds)

---

### 🔌 Future-Ready Code

Prepare structure for:

* ESP32 communication (HTTP/MQTT placeholders)
* API integration
* Device connection status

---

### 🧩 Reusable Components

Create:

* CounterDisplay widget
* ControlButton widget
* DeviceCard widget
* InfoCard widget

---

### 🧪 Mock Data

Use dummy JSON/local data for:

* Devices
* Analytics
* Profile

---

### 📦 Packages to Use

* provider (or flutter_riverpod)
* http
* google_fonts
* fl_chart (for analytics)
* flutter_animate (optional animations)

---

### 🧼 Code Quality

* Clean, readable, modular code
* Null safety
* Comments for important parts

---

### 🎁 Bonus (if possible)

* Add subtle sound/vibration feedback on count change
* Add loading shimmer effects

---

### 🚫 Do NOT implement yet

* Real ESP32 connection
* Real API calls

Use mock services instead.

---

### ✅ Final Output

Deliver a fully runnable Flutter app with:

* Proper folder structure
* Multiple screens
* Smooth UI
* Dummy data working
* Ready for future hardware integration