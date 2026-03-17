# Digigoci 🐱

Digigoci is a lightweight, native macOS menu bar application written purely in Swift. It lives entirely in your Mac's status bar (with no dock icon!) and gives you a virtual pixel-art cat companion that ages, reacts to your care, and needs feeding, play, and sleep — just like a classic Tamagotchi.

## Features

* **Pixel Art ASCII Cat** — Your pet is rendered in monospaced ASCII art on a dark retro screen (`#1a1a2e` background), with 7 expressive face states.
* **Three Life Stages** — Baby, Child, and Adult; your cat grows as the days pass and unlocks a larger animated sprite.
* **Animated Walking Legs** — Child and Adult cats cycle through a 4-frame walking animation every 0.6 seconds.
* **Three Stats** — Hunger, Happiness, and Energy each decay over time and are displayed as colour-coded progress bars (green → orange → red).
* **Seven Moods** — `happy`, `content`, `hungry`, `sad`, `tired`, `sleeping`, and `dead`, each with a unique face and body colour.
* **Care Actions** — Feed (+25 hunger), Play (+20 happiness, −10 energy), and Sleep (recovers energy to 90).
* **Offline Decay** — Stats decay in real-time; your pet needs regular attention to stay happy.
* **Revive** — When your pet dies, a single button brings it back at 50/50/50 stats.
* **Rename** — Give your cat any name from the Settings view.
* **Danger Zone Reset** — Start fresh with a brand-new pet (confirmation required).
* **Persistent State** — Pet stats, name, birth date, and care history saved locally in `~/Library/Application Support/Digigoci/`.
* **Theme Support** — System, Light, or Dark mode.
* **No Xcode Required** — Builds entirely from the terminal using a custom shell script.

## Requirements

* macOS 13.0 (Ventura) or later
* Swift 5.7+ (included with Xcode Command Line Tools)

## Preview

![Digigoci preview](preview.png)

### Baby stage
```
  /\_/\
 ( ^_^ )
  > ^ <
```

### Child stage — animated
```
 /\_/\       /\_/\
( ^_^ )     ( ^_^ )
/|   |\     /|   |\
\L_/ \_/   /_\ \_\
```

### Adult stage — animated
```
  /\_____/\
 (  ^_^  )
/|       |\
/\   /\
  \_/  \_/
```

## Installation & Setup

You can build and run Digigoci directly from your terminal without opening Xcode.

1. **Clone the repository:**
   ```bash
   git clone https://github.com/BogdanAlinTudorache/Digigoci.git
   cd Digigoci
   ```

2. **Make the build script executable (first time only):**
   ```bash
   chmod +x build.sh
   ```

3. **Build the app:**
   ```bash
   ./build.sh
   ```

4. **Run it directly:**
   ```bash
   open build/Digigoci.app
   ```

5. **(Optional) Install to your Applications folder:**
   ```bash
   cp -r build/Digigoci.app /Applications/
   ```

## Customization

Click the **cat emoji** in your menu bar, then click the **gear icon** to open Settings.

* **Rename** — type a new name and tap Rename
* **Theme** — System / Light / Dark
* **Reset** — create a brand-new pet (your current pet will be lost)

> **Tip:** Keep your cat alive for 10+ days to unlock the Adult stage with a larger sprite!
