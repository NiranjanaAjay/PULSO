# PULSO 💓

A minimally invasive heart monitoring system that leverages AI-powered ECG analysis for accessible cardiac health monitoring.

## 🎬 Promo Video

[![PULSO Promo Video](https://img.youtube.com/vi/sxMXJyR7pvI/0.jpg)](https://www.youtube.com/watch?v=sxMXJyR7pvI)

▶️ **[Watch our promo video on YouTube](https://www.youtube.com/watch?v=sxMXJyR7pvI)**

---

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![ESP32](https://img.shields.io/badge/ESP32-E7352C?style=for-the-badge&logo=espressif&logoColor=white)
![Arduino](https://img.shields.io/badge/Arduino_IDE-00979D?style=for-the-badge&logo=arduino&logoColor=white)

## 🌟 Features

- **🤖 AI-Powered ECG Analysis** - Gemini AI integration for intelligent ECG interpretation
- **📊 ECG Session Management** - Record, store, and track ECG sessions over time
- **💊 Medication Tracking** - Keep track of medications and health routines
- **🔐 Secure Authentication** - JWT-based authentication via Supabase
- **📱 Cross-Platform** - Available on Android, iOS, Web, Windows, macOS, and Linux
- **📡 Bluetooth Connectivity** - Real-time ECG data streaming via Classic Bluetooth

---

## 🔧 Hardware Components

### Circuit Diagram

![Circuit Diagram](docs/images/circuit_diagram.png)

*Schematic for ESP32-based ECG Data Acquisition System*

### Component Overview

| Component | Description | Purpose |
|-----------|-------------|---------|
| **ESP32 DevKit V1** | Dual-core microcontroller with Wi-Fi & Bluetooth | Main processing unit & wireless communication |
| **AD8232** | Single-lead heart rate monitor front-end | ECG signal acquisition & conditioning |
| **ADS1115** | 16-bit ADC with I²C interface | High-resolution analog-to-digital conversion |

---

### 🎛️ ESP32 DevKit V1

The **ESP32** is the brain of the PULSO hardware system. It handles:

- **Bluetooth Serial Communication** - Uses Classic Bluetooth (SPP - Serial Port Profile) via UART for reliable data transmission to the smartphone app
- **I²C Master** - Communicates with the ADS1115 ADC
- **Real-time Processing** - Reads ECG data at 860 samples per second

**Key Specifications:**
| Parameter | Value |
|-----------|-------|
| Processor | Dual-core Xtensa LX6 @ 240 MHz |
| Bluetooth | Classic BT + BLE |
| Operating Voltage | 3.3V |
| I²C Pins | GPIO 21 (SDA), GPIO 22 (SCL) |

**Development Environment:** Arduino IDE with ESP32 board support package

---

### 💓 AD8232 ECG Module

The **AD8232** is a specialized integrated signal conditioning block for ECG and other biopotential measurement applications.

**Key Features:**
- **Integrated Instrumentation Amplifier** - High gain for weak biopotential signals
- **Two-pole High-Pass Filter** - Removes DC offset and motion artifacts
- **Two-pole Low-Pass Filter** - Anti-aliasing filter for clean signals
- **Right Leg Drive (RLD)** - Improves common-mode rejection
- **Leads-Off Detection** - Detects electrode disconnection (LO+ and LO- pins)

**Key Specifications:**
| Parameter | Value |
|-----------|-------|
| Operating Voltage | 2.0V - 3.5V |
| Supply Current | 170 µA |
| Common-Mode Rejection | 80 dB |
| Bandwidth | 0.5 Hz - 40 Hz (typical ECG range) |

**Electrode Placement (3-Lead Configuration):**
| Electrode Color | Placement | Function |
|-----------------|-----------|----------|
| 🔴 Red | Right chest (near shoulder) | RA (Right Arm) |
| 🟡 Yellow | Left chest (above heart) | LA (Left Arm) |
| 🟢 Green | Right hip / lower abdomen | RL (Right Leg - Ground Reference) |

---

### 📏 ADS1115 16-Bit ADC

The **ADS1115** provides high-resolution analog-to-digital conversion, essential for capturing the fine details of ECG waveforms that the ESP32's built-in 12-bit ADC would miss.

**Why ADS1115 over ESP32's internal ADC?**
- **16-bit resolution** vs 12-bit (16x more precision)
- **Programmable Gain Amplifier (PGA)** for optimal signal range
- **Lower noise** for cleaner ECG signals
- **I²C interface** for easy integration

**Key Specifications:**
| Parameter | Value |
|-----------|-------|
| Resolution | 16-bit |
| Data Rate | Up to 860 SPS |
| I²C Address | 0x48 (default) |
| Input Channels | 4 single-ended / 2 differential |
| PGA Range | ±0.256V to ±6.144V |

**Configuration Used in PULSO:**
| Setting | Value | Reason |
|---------|-------|--------|
| Gain | GAIN_ONE (±4.096V) | Optimal for 3.3V signals |
| Data Rate | 860 SPS | Fast enough to capture R-peaks |
| Mode | Single-ended (A0) | Reading AD8232 output |

---

### 🔌 Wiring Connections

```
┌─────────────────────────────────────────────────────────────────────┐
│                    POWER DISTRIBUTION                               │
├─────────────────────────────────────────────────────────────────────┤
│  ESP32 3.3V  ──────┬──────────────────┬──────────────────────────   │
│                    │                  │                             │
│               ADS1115 VDD        AD8232 3.3V                        │
│                                                                     │
│  ESP32 GND   ──────┴──────────────────┴──────────────────────────   │
│                    │                  │                             │
│               ADS1115 GND        AD8232 GND                         │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                    I²C CONNECTION                                   │
├─────────────────────────────────────────────────────────────────────┤
│  ESP32 GPIO 21 (SDA)  ─────────────  ADS1115 SDA                    │
│  ESP32 GPIO 22 (SCL)  ─────────────  ADS1115 SCL                    │
│  ADS1115 ADDR         ─────────────  GND (Address: 0x48)            │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                    SIGNAL CONNECTION                                │
├─────────────────────────────────────────────────────────────────────┤
│  AD8232 OUTPUT  ───────────────────  ADS1115 A0                     │
│  AD8232 LO+     ───────────────────  (Unconnected/Optional)         │
│  AD8232 LO-     ───────────────────  (Unconnected/Optional)         │
└─────────────────────────────────────────────────────────────────────┘
```

---

### 📡 Bluetooth Communication

PULSO uses **Classic Bluetooth** (not BLE) for communication between the ESP32 and the smartphone app.

**Why Classic Bluetooth over BLE?**
| Feature | Classic BT (SPP) | BLE |
|---------|------------------|-----|
| Data Rate | Higher throughput | Limited |
| Latency | Lower | Higher |
| Continuous Streaming | ✅ Ideal | ❌ Not designed for |
| Power Consumption | Higher | Lower |

For ECG streaming at 860 samples/second, Classic Bluetooth's higher throughput and lower latency make it the better choice.

**Bluetooth Configuration:**
- **Device Name:** `PULSO_ECG_Device`
- **Protocol:** Serial Port Profile (SPP)
- **Data Format:** ASCII text with newline delimiter (`\n`)

---

## 🏗️ Project Structure

```
PULSO/
├── lib/                    # Flutter application source code
├── backend/                # FastAPI backend server
├── ecg.ino                 # ESP32 firmware (Arduino)
├── android/                # Android-specific files
├── ios/                    # iOS-specific files
├── web/                    # Web-specific files
├── windows/                # Windows-specific files
├── macos/                  # macOS-specific files
├── linux/                  # Linux-specific files
├── packages/               # Custom packages
├── supabase_migrations/    # Database migrations
└── test/                   # Test files
```

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x or higher)
- [Python 3.10+](https://www.python.org/downloads/)
- [Arduino IDE](https://www.arduino.cc/en/software) (for ESP32 firmware)
- [Supabase Account](https://supabase.com/)
- [Google Gemini API Key](https://ai.google.dev/)

### Hardware Setup

1. **Assemble the circuit** according to the wiring diagram above
2. **Connect electrodes** to the AD8232 module
3. **Power the circuit** via ESP32's USB or external 3.3V supply

### ESP32 Firmware Setup (Arduino IDE)

1. **Install ESP32 Board Support:**
   - Open Arduino IDE → File → Preferences
   - Add to "Additional Board Manager URLs":
     ```
     https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
     ```
   - Go to Tools → Board → Boards Manager → Search "ESP32" → Install

2. **Install Required Libraries:**
   - Sketch → Include Library → Manage Libraries
   - Install: `Adafruit ADS1X15`
   - Install: `Adafruit BusIO`

3. **Upload the Firmware:**
   - Open `ecg.ino`
   - Select Board: "ESP32 Dev Module"
   - Select Port: Your ESP32's COM port
   - Click Upload

### Frontend Setup (Flutter)

1. **Clone the repository:**
   ```bash
   git clone https://github.com/nik1740/PULSO.git
   cd PULSO
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

### Backend Setup (FastAPI)

1. **Navigate to backend directory:**
   ```bash
   cd backend
   ```

2. **Create and activate virtual environment:**
   ```bash
   python -m venv venv
   # Windows
   venv\Scripts\activate
   # Linux/Mac
   source venv/bin/activate
   ```

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Configure environment:**
   - Copy `.env.example` to `.env`
   - Add your Supabase and Gemini API keys

5. **Run the server:**
   ```bash
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

6. **Access API documentation:**
   - Swagger UI: http://localhost:8000/docs
   - ReDoc: http://localhost:8000/redoc

## 📡 API Endpoints

### ECG Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/ecg/questionnaire` | Save session questionnaire |
| POST | `/api/v1/ecg/snapshot/{reading_id}` | Upload ECG image |
| GET | `/api/v1/ecg/session/{reading_id}` | Get session details |
| GET | `/api/v1/ecg/sessions` | List user sessions |

### Analysis Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/analysis/request/{reading_id}` | Request AI analysis |
| GET | `/api/v1/analysis/{reading_id}` | Get analysis results |
| GET | `/api/v1/analysis/history/list` | Get analysis history |

### User Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/user/profile` | Get user profile |
| GET | `/api/v1/user/medications` | List medications |
| POST | `/api/v1/user/medications` | Add medication |

## 🔒 Security Features

- **JWT Authentication** - All endpoints require authentication (except health check)
- **Rate Limiting** - Analysis endpoint limited to 5 requests/hour
- **Input Sanitization** - Protection against XSS attacks

## 🛠️ Tech Stack

| Component | Technology |
|-----------|------------|
| Frontend | Flutter / Dart |
| Backend | FastAPI / Python |
| Database | Supabase (PostgreSQL) |
| AI/ML | Google Gemini |
| Authentication | Supabase Auth (JWT) |
| Microcontroller | ESP32 (Arduino IDE) |
| ECG Frontend | AD8232 |
| ADC | ADS1115 (16-bit) |
| Communication | Classic Bluetooth (SPP) |

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Supabase Documentation](https://supabase.com/docs)
- [Gemini AI Documentation](https://ai.google.dev/docs)
- [ESP32 Arduino Core](https://docs.espressif.com/projects/arduino-esp32/)
- [AD8232 Datasheet](https://www.analog.com/media/en/technical-documentation/data-sheets/ad8232.pdf)
- [ADS1115 Datasheet](https://www.ti.com/lit/ds/symlink/ads1115.pdf)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is open source. See the repository for license details.

---

<p align="center">Made with ❤️ for better heart health</p>
