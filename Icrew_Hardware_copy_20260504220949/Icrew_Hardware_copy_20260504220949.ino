#include <ArduinoJson.h>
#include <ESPmDNS.h>
#include <HTTPClient.h>
#include <Preferences.h>
#include <Stepper.h>
#include <WebServer.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>

// ============== SOFTAP PROVISIONING ==============
static const IPAddress kApIp(192, 168, 4, 1);
static const IPAddress kApGw(192, 168, 4, 1);
static const IPAddress kApMask(255, 255, 255, 0);

// Optional: set a unique short label per board (letters/digits, ≤8 recommended).
// Leave empty string to derive ID from chip MAC (shown as IcrewSetup-XXXXXXXX).
static const char kManualDeviceCode[] = "";

static String gDeviceCode;
static String gApSsid;
static String gMdnsHost;

void computeDeviceIdentity() {
  if (strlen(kManualDeviceCode) > 0) {
    gDeviceCode = String(kManualDeviceCode);
  } else {
    uint64_t mac = ESP.getEfuseMac();
    char hex[20];
    snprintf(hex, sizeof(hex), "%04X%04X", (unsigned)((mac >> 16) & 0xFFFF),
             (unsigned)(mac & 0xFFFF));
    gDeviceCode = String(hex);
  }
  gApSsid = String("IcrewSetup-") + gDeviceCode;
  if (gApSsid.length() > 32) {
    gApSsid = gApSsid.substring(0, 32);
  }
  gMdnsHost = String("icrew-") + gDeviceCode;
  gMdnsHost.toLowerCase();
}

Preferences prefs;
WebServer server(80);
bool provisioningMode = false;

// ================= JOKE SETTINGS =================
bool jokeEnabled = true;
unsigned long jokeInterval = 10000;

// ================= MOTOR TIMER SETTINGS =================
bool intervalMode = false;
unsigned long lastMotorTime = 0;
unsigned long motorInterval = 15000;

// ================= STEPPER =================
const int stepsPerRevolution = 2048;
Stepper myStepper(stepsPerRevolution, 13, 14, 26, 27);

// ================= MOTOR SETTINGS =================
int rotationSteps = 256;
int direction = 1;
int motorSpeedRPM = 10;

bool continuousMode = false;
int remainingRotations = 0;

String serialBuffer = "";

// ---------- NVS ----------
void saveWifiCredentials(const String& ssid, const String& pass) {
  prefs.begin("icrew", false);
  prefs.putString("ssid", ssid);
  prefs.putString("pass", pass);
  prefs.putBool("cfg", true);
  prefs.end();
}

bool loadWifiCredentials(String& outSsid, String& outPass) {
  prefs.begin("icrew", true);
  const bool configured = prefs.getBool("cfg", false);
  outSsid = prefs.getString("ssid", "");
  outPass = prefs.getString("pass", "");
  prefs.end();
  return configured && outSsid.length() > 0;
}

void clearWifiCredentials() {
  prefs.begin("icrew", false);
  prefs.clear();
  prefs.end();
}

bool connectStaWithRetries(const String& ssid, const String& pass, int maxAttempts) {
  Serial.println("\nConnecting STA...");
  WiFi.mode(WIFI_STA);
  WiFi.setAutoReconnect(true);
  WiFi.begin(ssid.c_str(), pass.c_str());

  int attempt = 0;
  while (WiFi.status() != WL_CONNECTED && attempt < maxAttempts) {
    delay(400);
    Serial.print('.');
    attempt++;
  }

  Serial.println();
  return WiFi.status() == WL_CONNECTED;
}

void startProvisioningAp() {
  provisioningMode = true;
  WiFi.mode(WIFI_AP);
  WiFi.disconnect(true);

  WiFi.softAP(gApSsid.c_str());  // Open AP — join from phone during setup
  delay(400);
  if (!WiFi.softAPConfig(kApIp, kApGw, kApMask)) {
    Serial.println("softAPConfig failed — using default SoftAP subnet");
  }

  Serial.printf("Provisioning AP \"%s\" (code %s) at %s\n", gApSsid.c_str(),
                gDeviceCode.c_str(), WiFi.softAPIP().toString().c_str());
}

bool startStaHttpAndMdns() {
  provisioningMode = false;

  Serial.println("\nWiFi connected!");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());

  if (!MDNS.begin(gMdnsHost.c_str())) {
    Serial.println("mDNS start failed — use IP address from router");
  } else {
    // ESP32 core 3.x: addService(service, proto, port) only — use setInstanceName for the label.
    MDNS.setInstanceName(gDeviceCode.c_str());
    MDNS.addService("icrew", "tcp", 80);
    MDNS.addServiceTxt("icrew", "tcp", "code", gDeviceCode.c_str());
    Serial.printf("mDNS: http://%s.local\n", gMdnsHost.c_str());
  }

  server.on("/", HTTP_GET, HTTP_GET_handleRootSta);
  server.on("/api/ping", HTTP_GET, HTTP_GET_ping);
  server.on("/api/command", HTTP_GET, HTTP_handleCommandVerb);
  server.on("/api/command", HTTP_POST, HTTP_handleCommandVerb);
  server.on("/api/status", HTTP_GET, HTTP_GET_status);
  server.on("/api/joke", HTTP_GET, HTTP_GET_joke);
  server.on("/api/factory", HTTP_POST, HTTP_POST_factory);

  server.begin();
  return true;
}

void startProvisioningHandlers() {
  server.on("/", HTTP_GET, HTTP_GET_handleRootProvision);
  server.on("/api/ping", HTTP_GET, HTTP_GET_ping);
  // Allow basic control even while the phone is joined to the device hotspot.
  // (Useful for testing motors before provisioning STA Wi‑Fi.)
  server.on("/api/command", HTTP_GET, HTTP_handleCommandVerb);
  server.on("/api/command", HTTP_POST, HTTP_handleCommandVerb);
  server.on("/api/status", HTTP_GET, HTTP_GET_status);
  server.on("/api/wifi", HTTP_POST, HTTP_POST_wifi);
  server.on("/api/factory", HTTP_POST, HTTP_POST_factory);
}

// ============ HTTP HANDLERS ============
void HTTP_GET_handleRootSta() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "text/plain",
               "Icrew ESP32 — POST /api/command (form: cmd=run) JSON status: "
               "/api/status\n");
}

void HTTP_GET_handleRootProvision() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(
      200, "text/html",
      "<!DOCTYPE html><html><head><meta charset=\"utf-8\"><title>Icrew "
      "Setup</title></head><body><p>Provisioning mode. Send Wi-Fi from "
               "InstaCounter app (<code>http://192.168.4.1</code>).</p></body></html>");
}

void HTTP_GET_ping() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  DynamicJsonDocument doc(256);
  doc["ok"] = true;
  doc["deviceCode"] = gDeviceCode;
  doc["provisioning"] = provisioningMode;
  doc["apSsid"] = provisioningMode ? gApSsid : "";
  doc["mdnsHost"] = gMdnsHost;
  String body;
  serializeJson(doc, body);
  server.send(200, "application/json", body);
}

void HTTP_GET_joke() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  if (!jokeEnabled) {
    server.send(403, "application/json",
                "{\"ok\":false,\"error\":\"jokes_disabled\"}");
    return;
  }
  if (provisioningMode || WiFi.status() != WL_CONNECTED) {
    server.send(503, "application/json",
                "{\"ok\":false,\"error\":\"no_sta_internet\"}");
    return;
  }
  String joke;
  if (!fetchJokeIntoString(joke)) {
    server.send(502, "application/json",
                "{\"ok\":false,\"error\":\"joke_fetch_failed\"}");
    return;
  }
  DynamicJsonDocument doc(6144);
  doc["ok"] = true;
  doc["joke"] = joke;
  String body;
  serializeJson(doc, body);
  server.send(200, "application/json", body);
}

void HTTP_POST_wifi() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  if (server.method() != HTTP_POST) {
    server.send(405, "application/json",
                "{\"ok\":false,\"error\":\"method_not_allowed\"}");
    return;
  }

  const String ssid = server.arg("ssid");
  const String password = server.arg("password");

  if (ssid.length() == 0) {
    server.send(400, "application/json", "{\"ok\":false,\"error\":\"missing_ssid\"}");
    return;
  }

  saveWifiCredentials(ssid, password);

  StaticJsonDocument<128> reply;
  reply["ok"] = true;
  reply["msg"] = "saved_restarting";
  String body;
  serializeJson(reply, body);
  server.send(200, "application/json", body);

  delay(350);
  ESP.restart();
}

void HTTP_POST_factory() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  clearWifiCredentials();
  server.send(200, "application/json", "{\"ok\":true}");
  delay(350);
  ESP.restart();
}

String buildStatusJson() {
  DynamicJsonDocument doc(1024);
  doc["provisioning"] = provisioningMode;
  doc["deviceCode"] = gDeviceCode;
  doc["mdnsHost"] = gMdnsHost;
  doc["provisioningApSsid"] = gApSsid;

  JsonObject wifiObj = doc["wifi"].to<JsonObject>();
  if (WiFi.status() == WL_CONNECTED) {
    wifiObj["connected"] = true;
    wifiObj["ssid"] = WiFi.SSID();
    wifiObj["ip"] = WiFi.localIP().toString();
    wifiObj["rssi"] = WiFi.RSSI();
  } else if (provisioningMode) {
    wifiObj["connected"] = false;
    wifiObj["ssid"] = gApSsid;
    wifiObj["ip"] = WiFi.softAPIP().toString();
  } else {
    wifiObj["connected"] = false;
    wifiObj["ssid"] = "";
    wifiObj["ip"] = "";
  }

  doc["rotationSteps"] = rotationSteps;
  doc["motorSpeedRPM"] = motorSpeedRPM;
  doc["direction"] = direction > 0 ? "forward" : "reverse";
  doc["continuousMode"] = continuousMode;
  doc["intervalMode"] = intervalMode;
  doc["motorIntervalMs"] = motorInterval;
  doc["remainingRotations"] = remainingRotations;
  doc["jokeEnabled"] = jokeEnabled;
  doc["jokeIntervalMs"] = jokeInterval;

  String out;
  serializeJson(doc, out);
  return out;
}

void HTTP_GET_status() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "application/json", buildStatusJson());
}

void HTTP_handleCommandVerb() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  if (!server.hasArg("cmd")) {
    server.send(400, "application/json",
                "{\"ok\":false,\"error\":\"missing_cmd\"}");
    return;
  }
  String cmd = server.arg("cmd");
  cmd.trim();
  handleCommand(cmd);
  server.send(200, "application/json", "{\"ok\":true}");
}

// ================= MOTOR FUNCTION =================
void runMotorOnce() {
  myStepper.step(rotationSteps * direction);
}

void printStatus() {
  Serial.println("\n===== STATUS =====");
  Serial.print("Steps per move      : ");
  Serial.println(rotationSteps);

  float degrees = ((float)rotationSteps / (float)stepsPerRevolution) * 360.0;
  Serial.print("Degrees per move    : ");
  Serial.println(degrees, 2);

  Serial.print("Direction           : ");
  Serial.println(direction == 1 ? "FORWARD" : "REVERSE");

  Serial.print("Speed (RPM)         : ");
  Serial.println(motorSpeedRPM);

  Serial.print("Continuous mode     : ");
  Serial.println(continuousMode ? "ON" : "OFF");

  Serial.print("Interval mode       : ");
  Serial.println(intervalMode ? "ON" : "OFF");

  Serial.print("Motor interval (ms) : ");
  Serial.println(motorInterval);

  Serial.print("Remaining count     : ");
  Serial.println(remainingRotations);

  Serial.print("Joke mode           : ");
  Serial.println(jokeEnabled ? "ON" : "OFF");

  Serial.print("Joke interval (ms)  : ");
  Serial.println(jokeInterval);

  Serial.print("WiFi                : ");
  if (WiFi.status() == WL_CONNECTED) {
    Serial.print("Connected ");
    Serial.println(WiFi.localIP());
  } else if (provisioningMode) {
    Serial.print("Provisioning AP ");
    Serial.println(WiFi.softAPIP());
  } else {
    Serial.println("Disconnected");
  }
  Serial.println("==================\n");
}

void printHelp() {
  Serial.println("\n========== COMMANDS ==========");
  Serial.println("help");
  Serial.println("status");
  Serial.println("\nwifi clear      -> wipe saved Wi‑Fi / factory from serial");

  Serial.println("\n-- motor move --");
  Serial.println("run                         -> run once now");
  Serial.println("steps 200                   -> set custom steps");
  Serial.println("deg 25                      -> set custom degree");
  Serial.println("turn full                   -> 360 deg");
  Serial.println("turn half                   -> 180 deg");
  Serial.println("turn quarter                -> 90 deg");
  Serial.println("turn eighth                 -> 45 deg");

  Serial.println("\n-- motor direction / speed --");
  Serial.println("dir forward");
  Serial.println("dir reverse");
  Serial.println("speed 10                    -> set RPM");

  Serial.println("\n-- continuous mode --");
  Serial.println("continuous on               -> nonstop running");
  Serial.println("continuous off              -> stop nonstop running");

  Serial.println("\n-- timed interval mode --");
  Serial.println("interval on                 -> enable timed motor mode");
  Serial.println("interval off                -> disable timed motor mode");
  Serial.println("interval 5                  -> set timed interval to 5 sec");
  Serial.println("count 10                    -> run 10 times on interval");

  Serial.println("\n-- joke api --");
  Serial.println("joke on");
  Serial.println("joke off");
  Serial.println("joke fetch                  -> fetch one joke now (serial)");
  Serial.println("jokeinterval 10             -> set joke interval to 10 sec");

  Serial.println("\n-- stop --");
  Serial.println("stop                        -> stop count + interval + continuous");
  Serial.println("==============================\n");
}

void stopAllMotorModes() {
  continuousMode = false;
  intervalMode = false;
  remainingRotations = 0;
}

void handleCommand(String cmd) {
  cmd.trim();

  String lower = cmd;
  lower.toLowerCase();

  // Factory / WiFi wipe (preserve case-sensitive paths not needed — whole line lower ok)
  if (lower == "wifi clear") {
    clearWifiCredentials();
    Serial.println("✅ Wi‑Fi forgotten. Reboot…");
    delay(250);
    ESP.restart();
    return;
  }

  cmd = lower;

  if (cmd == "help") {
    printHelp();
  } else if (cmd == "status") {
    printStatus();
  }

  // ===== MOTOR MOVE =====
  else if (cmd == "run") {
    Serial.println("⚙️ Motor Running...");
    runMotorOnce();
    Serial.println("✅ Motor Done");
  } else if (cmd.startsWith("steps ")) {
    int val = cmd.substring(6).toInt();
    if (val > 0) {
      rotationSteps = val;
      Serial.print("✅ Rotation steps set to: ");
      Serial.println(rotationSteps);
    } else {
      Serial.println("❌ Invalid steps");
    }
  } else if (cmd.startsWith("deg ")) {
    float deg = cmd.substring(4).toFloat();
    if (deg > 0 && deg <= 360) {
      rotationSteps = (int)((deg / 360.0) * stepsPerRevolution);
      if (rotationSteps < 1) rotationSteps = 1;

      Serial.print("✅ Degree set to: ");
      Serial.print(deg);
      Serial.print(" => steps: ");
      Serial.println(rotationSteps);
    } else {
      Serial.println("❌ Invalid degree");
    }
  } else if (cmd == "turn full") {
    rotationSteps = stepsPerRevolution;
    Serial.println("✅ Turn set to FULL");
  } else if (cmd == "turn half") {
    rotationSteps = stepsPerRevolution / 2;
    Serial.println("✅ Turn set to HALF");
  } else if (cmd == "turn quarter") {
    rotationSteps = stepsPerRevolution / 4;
    Serial.println("✅ Turn set to QUARTER");
  } else if (cmd == "turn eighth") {
    rotationSteps = stepsPerRevolution / 8;
    Serial.println("✅ Turn set to EIGHTH");
  }

  // ===== DIRECTION / SPEED =====
  else if (cmd == "dir forward") {
    direction = 1;
    Serial.println("✅ Direction set to FORWARD");
  } else if (cmd == "dir reverse") {
    direction = -1;
    Serial.println("✅ Direction set to REVERSE");
  } else if (cmd.startsWith("speed ")) {
    int rpm = cmd.substring(6).toInt();
    if (rpm > 0) {
      motorSpeedRPM = rpm;
      myStepper.setSpeed(motorSpeedRPM);
      Serial.print("✅ Speed set to RPM: ");
      Serial.println(motorSpeedRPM);
    } else {
      Serial.println("❌ Invalid speed");
    }
  }

  // ===== CONTINUOUS =====
  else if (cmd == "continuous on") {
    continuousMode = true;
    intervalMode = false;
    remainingRotations = 0;
    Serial.println("✅ Continuous mode ON");
  } else if (cmd == "continuous off") {
    continuousMode = false;
    Serial.println("✅ Continuous mode OFF");
  }

  // ===== INTERVAL / COUNT =====
  else if (cmd == "interval on") {
    intervalMode = true;
    continuousMode = false;
    lastMotorTime = millis();
    Serial.println("✅ Interval mode ON");
  } else if (cmd == "interval off") {
    intervalMode = false;
    remainingRotations = 0;
    Serial.println("✅ Interval mode OFF");
  } else if (cmd.startsWith("interval ")) {
    String arg = cmd.substring(9);
    arg.trim();

    if (arg == "on") {
      intervalMode = true;
      continuousMode = false;
      lastMotorTime = millis();
      Serial.println("✅ Interval mode ON");
    } else if (arg == "off") {
      intervalMode = false;
      remainingRotations = 0;
      Serial.println("✅ Interval mode OFF");
    } else {
      int sec = arg.toInt();
      if (sec > 0) {
        motorInterval = (unsigned long)sec * 1000UL;
        Serial.print("✅ Motor interval set to ");
        Serial.print(sec);
        Serial.println(" sec");
      } else {
        Serial.println("❌ Invalid interval");
      }
    }
  } else if (cmd.startsWith("count ")) {
    int val = cmd.substring(6).toInt();
    if (val > 0) {
      remainingRotations = val;
      intervalMode = true;
      continuousMode = false;
      lastMotorTime = millis();
      Serial.print("✅ Count set to ");
      Serial.println(remainingRotations);
    } else {
      Serial.println("❌ Invalid count");
    }
  }

  // ===== JOKE =====
  else if (cmd == "joke on") {
    jokeEnabled = true;
    Serial.println("✅ Joke mode ON");
  }   else if (cmd == "joke off") {
    jokeEnabled = false;
    Serial.println("✅ Joke mode OFF");
  } else if (cmd == "joke fetch") {
    String j;
    if (fetchJokeIntoString(j)) {
      Serial.println("😂 Joke:");
      Serial.println(j);
      Serial.println("----------------------");
    } else {
      Serial.println("❌ Joke fetch failed");
    }
  } else if (cmd.startsWith("jokeinterval ")) {
    int sec = cmd.substring(13).toInt();
    if (sec > 0) {
      jokeInterval = (unsigned long)sec * 1000UL;
      Serial.print("✅ Joke interval set to ");
      Serial.print(sec);
      Serial.println(" sec");
    } else {
      Serial.println("❌ Invalid joke interval");
    }
  }

  // ===== STOP =====
  else if (cmd == "stop") {
    stopAllMotorModes();
    Serial.println("✅ All motor modes stopped");
  } else {
    Serial.println("❌ Unknown command. Type: help");
  }
}

void readSerialCommands() {
  while (Serial.available()) {
    char c = Serial.read();

    if (c == '\n' || c == '\r') {
      if (serialBuffer.length() > 0) {
        handleCommand(serialBuffer);
        serialBuffer = "";
      }
    } else {
      serialBuffer += c;
    }
  }
}

bool fetchJokeIntoString(String& out) {
  out = "";
  if (WiFi.status() != WL_CONNECTED || provisioningMode) {
    return false;
  }

  WiFiClientSecure client;
  client.setInsecure();

  HTTPClient http;
  http.begin(client,
             "https://v2.jokeapi.dev/joke/Programming?blacklistFlags=political&type=single");

  const int httpCode = http.GET();
  if (httpCode <= 0) {
    http.end();
    return false;
  }

  const String payload = http.getString();
  http.end();

  DynamicJsonDocument doc(2048);
  if (deserializeJson(doc, payload)) {
    return false;
  }
  const char* joke = doc["joke"];
  if (!joke) {
    return false;
  }
  out = String(joke);
  return out.length() > 0;
}

void setup() {
  Serial.begin(115200);
  delay(800);

  computeDeviceIdentity();
  Serial.printf("Icrew device code: %s  AP SSID: %s  mDNS: %s.local\n",
                gDeviceCode.c_str(), gApSsid.c_str(), gMdnsHost.c_str());

  myStepper.setSpeed(motorSpeedRPM);

  String ssid, pass;
  const bool haveCfg = loadWifiCredentials(ssid, pass);

  if (haveCfg && connectStaWithRetries(ssid, pass, 40)) {
    startStaHttpAndMdns();
  } else {
    WiFi.disconnect(true, true);
    delay(200);
    Serial.println("STA failed or not configured — starting provisioning AP");
    startProvisioningAp();
    startProvisioningHandlers();
    server.begin();
  }

  printHelp();
  printStatus();
}

void loop() {
  server.handleClient();
  readSerialCommands();

  if (continuousMode) {
    runMotorOnce();
  }

  if (intervalMode && (millis() - lastMotorTime >= motorInterval)) {
    lastMotorTime = millis();

    if (remainingRotations > 0) {
      Serial.println("⚙️ Motor Running (count mode)...");
      runMotorOnce();
      remainingRotations--;
      Serial.print("🔁 Remaining rotations: ");
      Serial.println(remainingRotations);

      if (remainingRotations == 0) {
        intervalMode = false;
        Serial.println("✅ Count mode finished");
      }
    } else if (remainingRotations == 0) {
      Serial.println("⚙️ Motor Running (interval mode)...");
      runMotorOnce();
    }
  }

}
