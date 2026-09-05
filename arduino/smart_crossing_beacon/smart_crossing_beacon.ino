// ─── RoadMesh: Smart School Crossing Beacon (V2I Roadside Unit) ────────────
//
// Target Board: Arduino UNO (R3 / R4 / Compatible)
// Description: Intelligent V2I Roadside Unit stationed at a school zebra crossing.
// Operation:
//   - Pin 2 (INPUT_PULLUP): Pedestrian "Push to Cross" button (touching to GND triggers)
//   - Pin 13 (LED_BUILTIN): Physical warning strobe light on the roadside pole
//   - Serial (115200 baud): Transmits structured V2I hazard telemetry via USB gateway

const int BUTTON_PIN = 2;       // Pushbutton connected between Pin 2 and GND
const int STROBE_LED_PIN = 13;  // Built-in LED on Arduino Uno

// Timing configuration
const unsigned long ACTIVE_DURATION_MS = 20000;  // Crossing active for 20 seconds
const unsigned long DEBOUNCE_DELAY_MS = 300;     // Button debounce time
const unsigned long STROBE_INTERVAL_MS = 150;    // LED flash interval

bool isCrossingActive = false;
unsigned long crossingStartTime = 0;
unsigned long lastStrobeTime = 0;
bool strobeState = false;
unsigned long lastButtonPress = 0;

void setup() {
    Serial.begin(115200);
    while (!Serial) {
        ; // Wait for serial port to connect (needed for native USB)
    }

    pinMode(BUTTON_PIN, INPUT_PULLUP);
    pinMode(STROBE_LED_PIN, OUTPUT);
    digitalWrite(STROBE_LED_PIN, LOW);

    // Startup announcement
    Serial.println();
    Serial.println(F("╔══════════════════════════════════════════════════════════════╗"));
    Serial.println(F("║   🚸 RoadMesh: Smart Pedestrian & School Crossing RSU v1.0   ║"));
    Serial.println(F("║   Target: Arduino UNO | Infrastructure Node (V2I)            ║"));
    Serial.println(F("║   Status: ONLINE & MONITORING (Touch Pin 2 to GND)           ║"));
    Serial.println(F("╚══════════════════════════════════════════════════════════════╝"));
}

void loop() {
    unsigned long now = millis();

    // Check if pedestrian button is pressed (active LOW due to pull-up)
    if (digitalRead(BUTTON_PIN) == LOW && !isCrossingActive) {
        if (now - lastButtonPress > DEBOUNCE_DELAY_MS) {
            lastButtonPress = now;
            triggerCrossingEvent(now);
        }
    }

    // Check for keyboard triggers from USB Serial Monitor (e.g. typing 't' or 'T')
    if (Serial.available() > 0) {
        char c = Serial.read();
        if ((c == 't' || c == 'T' || c == ' ') && !isCrossingActive) {
            triggerCrossingEvent(now);
        }
    }

    // If crossing beacon is active, handle physical strobe light and timeout
    if (isCrossingActive) {
        // Flash roadside warning strobe
        if (now - lastStrobeTime >= STROBE_INTERVAL_MS) {
            lastStrobeTime = now;
            strobeState = !strobeState;
            digitalWrite(STROBE_LED_PIN, strobeState ? HIGH : LOW);
        }

        // Check if 20-second crossing period has expired
        if (now - crossingStartTime >= ACTIVE_DURATION_MS) {
            endCrossingEvent();
        }
    }
}

/**
 * Trigger active pedestrian crossing event.
 */
void triggerCrossingEvent(unsigned long now) {
    isCrossingActive = true;
    crossingStartTime = now;
    lastStrobeTime = now;
    strobeState = true;
    digitalWrite(STROBE_LED_PIN, HIGH);

    // Send single-line JSON packet to RoadMesh Edge Gateway over Serial
    Serial.println(F("{\"event\":\"PEDESTRIAN_CROSSING\",\"nodeId\":\"rsu-school-01\",\"location\":\"MODEL_SCHOOL\",\"lat\":10.0261,\"lng\":76.3125,\"speedLimit\":20,\"active\":true}"));
}

/**
 * Reset crossing beacon back to standby mode.
 */
void endCrossingEvent() {
    isCrossingActive = false;
    digitalWrite(STROBE_LED_PIN, LOW);

    // Notify gateway that crossing period has cleared
    Serial.println(F("{\"event\":\"CROSSING_CLEARED\",\"nodeId\":\"rsu-school-01\",\"active\":false}"));
}
