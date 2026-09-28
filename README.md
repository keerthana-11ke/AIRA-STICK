# AIRA – AI-Powered Context-Aware Assistive Navigation System for the Visually Impaired

## Project Overview

AIRA is an ESP32-based assistive navigation system designed to support visually impaired users during walking and navigation. The system combines a Smart Stick with an AIRA mobile application to provide obstacle detection, pit detection, water detection, audio feedback, and GPS-based destination navigation.

The Smart Stick continuously monitors the surrounding environment using ultrasonic and water sensors. When a potential hazard is detected, the system provides an audio warning through a DFPlayer Mini and speaker. The AIRA mobile application supports saved destinations and GPS-based navigation, while Bluetooth Low Energy (BLE) is used for communication between the mobile application and the Smart Stick.

## Objectives

* Detect obstacles in front of the user.
* Detect pits, steps, or ground-level hazards.
* Detect the presence of water.
* Provide immediate audio warnings to the user.
* Support destination-based navigation using GPS.
* Provide wireless communication between the Smart Stick and mobile application.
* Provide visual status information using an LCD and LED indicators.
* Improve safety and independence during walking.

## System Architecture

The AIRA system consists of two main parts:

### 1. AIRA Smart Stick

The Smart Stick is built around an ESP32 microcontroller. It collects information from the sensors and provides audio and visual feedback.

Main functions include:

* Front obstacle detection
* Pit/step detection
* Water detection
* Audio warning generation
* Navigation instruction playback
* LCD status display
* LED status indication
* BLE communication with the mobile application

### 2. AIRA Mobile Application

The AIRA mobile application provides the navigation interface and destination management.

Main functions include:

* Saved and predefined destinations
* GPS-based current location
* Destination selection
* Navigation support
* BLE communication with the Smart Stick
* Sending navigation instructions to the Smart Stick

## Hardware Components

| Component                 | Purpose                            |
| ------------------------- | ---------------------------------- |
| ESP32 Development Board   | Main controller of the Smart Stick |
| HC-SR04 Ultrasonic Sensor | Front obstacle detection           |
| HC-SR04 Ultrasonic Sensor | Pit/step detection                 |
| Water Sensor              | Water detection                    |
| DFPlayer Mini             | Audio playback                     |
| 8Ω Speaker                | Audio output                       |
| 16×2 I2C LCD              | System status display              |
| Green LED                 | Normal operating status            |
| Red LED                   | Hazard indication                  |
| Battery/Power Supply      | Provides power to the system       |
| Connecting Wires          | Electrical connections             |

## Software Technologies

* Arduino IDE
* Embedded C/C++
* ESP32 Arduino Core
* Flutter
* Dart
* Bluetooth Low Energy (BLE)
* GPS-based location services

## Sensors and Detection

### Obstacle Detection

The front HC-SR04 ultrasonic sensor measures the distance between the Smart Stick and an object. When an obstacle is detected within the configured detection range, the Smart Stick provides an audio warning.

### Pit Detection

A second HC-SR04 ultrasonic sensor is used to monitor the ground-level distance. A significant increase in measured distance can indicate a pit, step-down, or similar ground hazard.

### Water Detection

The water sensor detects the presence of water on the walking path. When water is detected, the Smart Stick provides an immediate audio warning.

## Audio Feedback

The DFPlayer Mini is used to play pre-recorded audio files stored on a microSD card.

The system provides audio for:

* System startup
* Obstacle warning
* Pit warning
* Water warning
* Left turn
* Right turn
* Straight direction
* Destination arrival
* Navigation cancellation
* Destination announcement

This allows the user to receive important information without continuously looking at a display.

## Navigation

The AIRA mobile application stores predefined destinations such as:

* Railway Station
* College
* Hospital
* Bus Stand
* Library

The guardian can select a destination through the application. GPS is used by the mobile application to support navigation, and navigation instructions are communicated to the Smart Stick through BLE.

The Smart Stick then provides the received navigation instructions through the speaker.

## BLE Communication

The ESP32 Smart Stick communicates with the AIRA mobile application using Bluetooth Low Energy.

**BLE Device Name:**

```text
AIRA-STICK
```

**Service UUID:**

```text
12345678-1234-1234-1234-123456789abc
```

The BLE communication is used for:

* Connecting the Smart Stick with the mobile application
* Destination selection
* Navigation instructions
* Navigation status
* Sensor status information
* Navigation cancellation
* Arrival notification

## Visual Indicators

The Smart Stick also provides visual status information.

### LCD

The 16×2 I2C LCD displays information such as:

* Navigation status
* Selected destination
* Front sensor distance
* Pit sensor distance
* Water status
* Bluetooth status

### LEDs

* **Green LED:** Normal operating condition
* **Red LED:** Hazard detected

## Project Structure

```text
AIRA-STICK
│
├── ESP32_Smart_Stick
│   └── AIRA_Smart_Stick.ino
│
├── AIRA_Mobile_Application
│   └── Flutter Project Files
│
└── README.md
```

## Working Principle

1. The ESP32 Smart Stick is powered on.
2. The connected sensors continuously monitor the environment.
3. The front ultrasonic sensor checks for obstacles.
4. The second ultrasonic sensor checks for pits or ground-level hazards.
5. The water sensor checks for water.
6. When a hazard is detected, the appropriate warning audio is played through the speaker.
7. The LCD and LED provide additional system status information.
8. The AIRA mobile application uses GPS for navigation support.
9. The user/guardian selects a saved destination through the application.
10. Navigation information is communicated between the application and Smart Stick using BLE.
11. The Smart Stick plays the received navigation instructions through the speaker.
12. Safety monitoring continues while navigation is active.

## Key Features

* ESP32-based Smart Stick
* Obstacle detection
* Pit and step detection
* Water detection
* Audio-based safety alerts
* GPS-based destination navigation
* BLE communication
* Saved destinations
* LCD status display
* LED hazard indication
* Continuous safety monitoring during navigation

## Applications

The AIRA system can be used to support:

* Personal mobility for visually impaired users
* Walking on roads and pathways
* Navigation around educational campuses
* Access to public transportation locations
* Indoor and outdoor mobility support where GPS navigation is available
* Assistive navigation in residential and public walking areas

## Limitations

* The current prototype detects specific hazards using ultrasonic and water sensors and does not identify every type of object.
* GPS-based navigation depends on the availability and accuracy of GPS signals.
* Navigation requires communication with the AIRA mobile application.
* Audio feedback may be affected by high environmental noise.
* The current implementation is a prototype and requires further real-world testing and refinement.

## Future Scope

Future development can include:

* Advanced camera-based object detection
* Improved navigation and route planning
* Additional environmental sensors
* Improved voice interaction
* Better power management
* Expanded destination management
* More extensive real-world testing
* Integration of additional assistive technologies

## Project Status

**Current Status:** Prototype development and hardware implementation.

The ESP32 Smart Stick has been developed with environmental sensing, audio feedback, LCD/LED status indication, and BLE communication. The AIRA mobile application provides destination management and GPS-based navigation support.

## Repository Contents

This repository contains the source code and project resources for the AIRA system, including:

* ESP32 Smart Stick Embedded C/Arduino source code
* AIRA mobile application source code
* Project documentation and supporting files

## Team Project

**Project:** AIRA – AI-Powered Context-Aware Assistive Navigation System for the Visually Impaired

**Domain:** Assistive Technology / Embedded Systems / Mobile Application / Navigation

## License

This project was developed as an academic engineering project. The source code and materials in this repository are intended for educational and project-development purposes.
