#include <Wire.h>
#include <Adafruit_ADS1X15.h>
#include <BluetoothSerial.h>

// --- HARDWARE OBJECTS ---
Adafruit_ADS1115 ads;  // The High-Res ADC
BluetoothSerial SerialBT; // The Bluetooth Radio

// --- SETTINGS ---
// I2C Pins for ESP32
#define SDA_PIN 21
#define SCL_PIN 22

void setup() {
  // 1. Start Serial for Debugging (USB cable)
  Serial.begin(115200);
  
  // 2. Start Bluetooth (This is what your App sees)
  // The name in quotes is what appears on your phone
  SerialBT.begin("PULSO_ECG_Device"); 
  Serial.println("Bluetooth Started! Ready to pair...");

  // 3. Start the Connection to ADS1115
  Wire.begin(SDA_PIN, SCL_PIN);
  
  if (!ads.begin()) {
    Serial.println("Failed to initialize ADS1115. Check wiring!");
    while (1); // Stop here if hardware is broken
  }

  // 4. Configure ADC for Medical Precision
  // GAIN_ONE = +/- 4.096V range (Perfect for 3.3V signals)
  ads.setGain(GAIN_ONE);
  
  // RATE_860SPS = 860 Samples Per Second
  // We need speed to capture the sharp 'R' peak of the heart
ads.setDataRate(RATE_ADS1115_860SPS);
}

void loop() {
  // 5. Read the Raw Signal
  int16_t ecgValue = ads.readADC_SingleEnded(0); // Reading Pin A0

  // 6. Send to Phone (Bluetooth)
  // We send it as text with a newline ("\n") so the App knows when a number ends
  SerialBT.println(ecgValue);

  // 7. Send to Computer (Serial Plotter) - Optional, for testing
  // Serial.println(ecgValue); 

  // 8. Timing Control
  // We don't use delay() because it blocks the processor.
  // The ADS1115 speed limit naturally paces the loop.
}