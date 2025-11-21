[Card Clash.md](https://github.com/user-attachments/files/23673445/Card.Clash.md)
# 🎴 Card Clash - Documentation

## 📖 Table of Contents
- [Introduction](#-introduction)
- [Features](#-features)
- [Installation](#-installation)
- [Gameplay](#-gameplay)
- [File Structure](#-file-structure)
- [Controls](#-controls)
- [Deck Creation](#-deck-creation)
- [Troubleshooting](#-troubleshooting)
- [Support](#-support)

## 🎮 Introduction

**Card Clash** is an exciting card battle game where strategy meets luck! Collect cards, build decks, and challenge the AI in epic battles. Choose your stats wisely - sometimes lower is better!

### ✨ What's Included
- **Card Clash EXE** - Main game executable
- **Deck System** - .ini based card management
- **Auto-Save Engine** - Never lose your progress
- **Stats & Game Tools** - Comprehensive statistics and settings

**Target Audience**: Perfect for fans of strategic card games, number crunching, or anyone who enjoys friendly AI competition!

## 🚀 Features

- 🃏 **Multiple Decks** - Create and manage custom card decks
- 🤖 **Smart AI** - Challenging computer opponent
- 💾 **Auto-Save** - Automatic progress saving
- 🎨 **Image Support** - Custom card images
- 🔊 **Sound Effects** - Immersive audio experience
- 📊 **Statistics** - Track your performance
- ⚡ **Fast Gameplay** - Quick matches and smooth performance

## 💻 Installation

### System Requirements
- **OS**: Windows 10/11
- **Storage**: ~50MB free space
- **Permissions**: Administrator rights recommended

### 📦 Installation Steps

1. **Run the installer** you downloaded
2. **Follow the setup wizard**:
   - Click "Next" through the screens
   - Choose installation folder (default: `C:\CardClash\`)
   - Check "Create Desktop Shortcut" for easy access
   - Click "Finish" to complete installation

### ⚙️ First Launch
- Run the game from desktop shortcut
- If Windows shows security warning: Click "More info" → "Run anyway"
- Game automatically creates necessary folders

## 🎯 Gameplay

### Main Screen Layout

🃏 Card Clash 1.0
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Player Card: [IMAGE] AI Card: [IMAGE]

📊 Available Statistics:

Horsepower

Speed

Length

Weight
...

[Space] Next round
[Enter] New game / Restart
[ESC] Exit


### 🎮 How to Play

1. **Deck Selection**
   - Choose from available decks in dropdown menu
   - Decks are loaded from `.ini` files in `Decks\` folder

2. **Card Dealing**
   - Cards are randomly distributed to player and AI

3. **Stat Selection**
   - Press 1-9 to choose which stat to compare
   - **Normal stats**: Higher value wins
   - **!Stats**: Lower value wins (marked with exclamation mark)

4. **Comparison**
   - Game compares selected stats and determines winner

5. **Winner Takes All**
   - Winner collects both cards
   - Continue until one player runs out of cards

6. **Next Round**
   - Press SPACE to continue to next round

## ⌨️ Controls

| Key | Action |
|-----|--------|
| `SPACE` | Next round |
| `ENTER` | New game / Restart |
| `ESC` | Exit (with confirmation) |
| `1-9` | Select statistic |
| `Ctrl + S` | Quick save |
| `Ctrl + L` | Quick load |

## 📁 File Structure
C:\CardClash
├── Decks\ # Deck configuration files (.ini)
├── Cards\ # Card images (jpg/png)
└── Data
├── Save.dat # Game saves
├── Config.ini # Settings
└── Sounds\ # Audio files


## 🛠️ Deck Creation

### Creating Custom Decks

1. Navigate to `C:\CardClash\Decks\`
2. Create a new `.ini` file
3. Use the following format:

```ini
[Car1]
Name=Ferrari Testarossa
Image=ferrari.jpg
Horsepower=390
Speed=290
Weight=1500
Length=4.5
!Reliability=85

[Car2]
Name=Porsche 911
Image=porsche.jpg
Horsepower=370
Speed=280
Weight=1450
Length=4.3
!Reliability=90

📝 Deck Format Guidelines
Section headers: [CardName]

Name: Display name of the card

Image: Filename from Cards\ folder

Normal stats: Higher value wins

!Stats: Lower value wins (prefix with !)

⚡ Game Mechanics
Stat Types
Higher Wins: Most statistics (Horsepower, Speed, etc.)

Lower Wins: Prefixed with ! (!Weight, !Reliability, etc.)

AI Behavior
The AI selects stats strategically

No cheating - fair gameplay guaranteed!

Challenging but beatable opponent

Scoring System
Winner collects both cards

Game continues until deck is exhausted

Final score determines overall winner

🛠️ Troubleshooting
Common Issues & Solutions
🔴 Game Won't Start
Run as Administrator: Right-click → "Run as administrator"

Antivirus: Check if antivirus is blocking the executable

Windows SmartScreen: Click "More info" → "Run anyway"

🔴 Game Crashes or Freezes
Task Manager: Close via Ctrl+Shift+Esc

Deck Issues: Check deck files for errors

Reinstall: Perform clean reinstallation

🔴 Images Not Displaying
File Location: Ensure images are in Cards\ folder

File Names: Verify .ini references correct filenames

Formats: Supported formats: JPG, PNG

🔴 Save Issues
Permissions: Run as Administrator

Disk Space: Ensure adequate free space

File Corruption: Delete corrupted save files

🔄 Clean Reinstallation
Uninstall via Control Panel

Delete C:\CardClash\ folder

Reinstall from original installer

Run as Administrator

❓ Frequently Asked Questions
❓ The game doesn't save my progress!
Solution: Run the game as Administrator to ensure proper file permissions.

❓ Can I create my own decks?
Yes! Create .ini files in the Decks\ folder using the provided format.

❓ What are "Lower wins" statistics?
Stats prefixed with ! (e.g., !Weight) - the player with the lower value wins the round.

❓ Where are my game saves stored?
Saves are located in C:\CardClash\Data\Save.dat

❓ The AI seems too difficult!
The AI plays fair but strategically. Try different decks and learn which stats work best against different cards.

📞 Support
Contact Information
Email: maxiths1984@gmail.com

Bug Reports
When reporting issues, please include:

What you were doing when the problem occurred

What you expected to happen

What actually happened

Any error messages received

Updates
Check periodically for new versions

Updates may include new features and bug fixes

🎉 Tips & Strategies
Know Your Deck: Understand which stats are your strengths

Watch for !Stats: These can turn the tables unexpectedly

Balance Your Deck: Mix high and low value stats

Learn AI Patterns: The AI has predictable behavior patterns

Version: 1.0.0
Last Updated: 2025

Good luck, have fun, and may the cards be ever in your favor! 🃏✨
