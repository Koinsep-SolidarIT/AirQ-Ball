We are trying to create a network of air-pollution sensors in Greece that also sends data to sensor.community.
We have built the sensors, and now it’s time to create a visual-representation project. This way, you can have the sensor, for example, on your balcony, but still see exactly what is happening inside your living room.

Wemos D1 Mini ↔ WS2812B LED Ring (7 LEDs)
┌─────────────┐    ┌─────────────────┐
│             │    │                 │
│   D4 (GPIO2)│────│▶ DIN (Data In)  │
│             │    │                 │
│     5V      │────│   VCC (+5V)     │
│             │    │                 │
│     GND     │────│   GND (Ground)  │
│             │    │                 │
└─────────────┘    └─────────────────┘
Detailed Connection Guide
Wemos D1 Mini Pins:
    D4 (GPIO2) → LED Data line (DIN)
    5V → LED Power (VCC)
    GND → LED Ground (GND)

LED Ring Connections:
    DIN (Data Input) - First LED in the chain
    VCC - 5V power supply
    GND - Ground

WEMOS D1 MINI
┌──────────────────┐
│              [USB]│
│ 5V  GND  D4  ... │
│ │    │    │       │
└─┼────┼────┼───────┘
  │    │    │
  │    │    │
  ▼    ▼    ▼
LED RING (WS2812B)
┌──────────────────┐
│ VCC GND DIN      │
│ ●   ●   ●        │
│ │   │   │        │
│ 1○  2○  3○  ... 7○│
└──────────────────┘

Power Considerations

For 7 LEDs:
    You can power directly from Wemos D1 Mini's 5V pin
    Each LED draws ~20-60mA when fully lit
    7 LEDs × 60mA = ~420mA maximum (within USB power limits)

For more LEDs (if you expand later):
    Use external 5V power supply
    Connect power directly to LED ring
    Connect Wemos GND to LED ring GND
    Keep data connection from D4 to DIN

Important Notes:

    Data Pin: Your code uses #define LED_PIN D4 which is GPIO2
    Power: Make sure you're using the 5V pin, NOT 3.3V
    Ground: Always connect grounds together
    LED Order: The first LED in the chain is the one connected to DIN
    Capacitor: For stability, add a 100-1000μF capacitor across VCC and GND near the LEDs

If LEDs Don't Light Up:
    Check data line connection to D4
    Verify 5V power (not 3.3V)
    Check all ground connections
    Ensure LED ring is the correct type (WS2812B/NeoPixel)
    Try reducing brightness in code if power issues
