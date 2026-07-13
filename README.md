# ⏱️ CODESYS Machine Time & Period Tracker

A lightweight, hardware-independent IEC 61131-3 Function Block developed by **ONX Control** for tracking machine running time (uptime) and calculating custom production periods.

## 📌 Features
* Evaluates active task intervals to calculate precision `LTIME` uptime.
* Converts running time to a custom **YYPP** string format based on dynamic period definitions.
* Safe boundary limits to prevent string overflow.
* Real-Time Clock (RTC) synchronization for machine startup logging.

## 🛠️ Usage
1. Import `ZamanKontrolFB.st` into your CODESYS V3.5 project.
2. Call the FB in a cyclic task.
3. Assign persistent variables to `MakineCalismaSureLog` and `MakinaBaslamaTarihLog` to retain data across power cycles.

---
*Maintained by ONX Control - Official CODESYS System Partner in Turkey.*
