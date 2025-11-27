# iOS Simulator - Fixed Time for Screenshots

## Set Fixed Date/Time

To make the simulator always show the same time for consistent screenshots:

### Method 1: Using Simulator Menu (Easiest & Most Reliable) ⭐

1. Open iOS Simulator
2. Go to **Device → Set Custom Date...**
3. Choose a date and time (e.g., November 27, 2025 at 10:30 AM)
4. Click **Set**

**Recommended time for screenshots:** 10:30 AM or 2:15 PM

### Method 2: Using Command Line (Works!)

Use this command in Terminal:

```bash
# Set time to 10:30 AM with full battery and signals
xcrun simctl status_bar booted override --time "10:30" --batteryState charged --batteryLevel 100 --wifiBars 3 --cellularBars 4
```

**Simple time format:** Just use "HH:MM" (e.g., "10:30", "14:15", "9:41")

## Reset to Current Time

To reset back to the current system time:

```bash
xcrun simctl status_bar booted clear
```

Or use the Simulator menu:
- **Device → Set Date Automatically**

## Quick Setup for Screenshots

### Step-by-Step:

1. **Open Terminal** (on your Mac)

2. **Run this command:**
   ```bash
   xcrun simctl status_bar booted override --time "10:30" --batteryState charged --batteryLevel 100 --wifiBars 3 --cellularBars 4
   ```

3. **Take all your screenshots** - The time will stay at 10:30 AM

4. **Reset when done:**
   ```bash
   xcrun simctl status_bar booted clear
   ```

### Other Time Options:

```bash
# Morning (9:41 AM - Apple's classic time)
xcrun simctl status_bar booted override --time "9:41" --batteryState charged --batteryLevel 100 --wifiBars 3 --cellularBars 4

# Afternoon (2:15 PM)
xcrun simctl status_bar booted override --time "14:15" --batteryState charged --batteryLevel 100 --wifiBars 3 --cellularBars 4
```

## Additional Status Bar Customizations

You can also customize other status bar elements:

```bash
# Set battery level
xcrun simctl status_bar booted override --batteryLevel 100

# Set battery state (charging, unplugged, etc.)
xcrun simctl status_bar booted override --batteryState charged

# Set cellular signal
xcrun simctl status_bar booted override --cellularBars 4

# Set WiFi signal
xcrun simctl status_bar booted override --wifiBars 3

# Clear all overrides
xcrun simctl status_bar booted clear
```

## Example: Complete Setup for Screenshots

```bash
# Set time to 10:30 AM
xcrun simctl status_bar booted override --time "10:30:00"

# Set full battery
xcrun simctl status_bar booted override --batteryLevel 100 --batteryState charged

# Set full cellular signal
xcrun simctl status_bar booted override --cellularBars 4

# Set full WiFi signal
xcrun simctl status_bar booted override --wifiBars 3
```

## Notes

- The time override persists until you clear it or restart the simulator
- Use a consistent time across all screenshots for App Store
- Common choices: 10:30 AM or 2:15 PM (looks professional)
- Remember to reset after taking screenshots

