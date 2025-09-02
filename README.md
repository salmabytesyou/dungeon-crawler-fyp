# Just a Girl's Dungeon Quest

**Final Year Project - BSc Computer Science**  
*Royal Holloway, University of London*

## Overview

A story-driven dungeon crawler combining procedural generation with narrative elements, built using **Godot Engine 4** and **GDScript**. This project demonstrates advanced game development techniques including procedural generation, turn-based combat, and integrated narrative systems.

## Key Features

### Procedural Dungeon Generation
- **Random Walk Algorithm**: Creates organic, interconnected dungeon layouts
- **Dynamic Difficulty Scaling**: Dungeon size and complexity increase with each floor
- **Progressive Challenge**: Enemy count and hazard frequency scale based on current floor
- **Guaranteed Connectivity**: Algorithm ensures all dungeon areas remain accessible

### Turn-Based Combat System
- **Strategic Depth**: Multiple player abilities unlocked through character progression
- **Enemy Variety**: Different enemy types with unique move sets and behaviours
- **Boss Encounters**: Special boss enemy on floor 5 with unique abilities
- **Visual Feedback**: Animated combat effects and clear turn indicators

### Character Progression
- **Experience Points**: Gain XP from defeating enemies and progressing through floors
- **Level-up System**: Increased stats and new abilities unlocked at higher levels
- **Ability Progression**: New combat moves like Firebolt and Earthquake earned through play
- **Health and Stats**: Growing maximum HP, attack, and defence values

### Narrative Integration
- **Story-Driven Experience**: Princess protagonist defying expectations to prove herself
- **Dialogue System**: Rich character interactions with typing effects
- **Character Development**: Journey from sheltered princess to capable adventurer
- **Hub Areas**: Castle and town scenes providing narrative context between dungeon runs

### Save/Load System
- **Multiple Save Slots**: Three save slots with detailed save information
- **Persistent Progress**: Character stats, level, and abilities saved between sessions
- **Robust Error Handling**: Data integrity checks and corruption prevention
- **User-Friendly Interface**: Clear save/load menus with timestamps and character details

## Technical Implementation

### **Engine & Language**
- **Godot Engine 4.x**: Modern, open-source game engine with node-based architecture
- **GDScript**: Primary scripting language for game logic and systems
- **Scene-Based Architecture**: Modular approach utilising Godot's scene system

### **Core Algorithms**
- **Random Walk Algorithm**: Procedural dungeon generation creating organic layouts
- **Grid-Based Movement**: Precise cell-to-cell navigation with collision detection
- **Turn-Based State Machine**: Combat system managing player and enemy turns
- **Save Data Serialisation**: JSON-based persistence system

### **Architecture Highlights**
- **Design Patterns**: Factory, State, Observer, and Command patterns throughout codebase
- **Modular Systems**: Independent game systems communicating through signals
- **Scalable Difficulty**: Algorithm-driven challenge progression across dungeon floors
- **Clean Code Principles**: Well-documented, maintainable codebase with clear separation of concerns

## Learning Outcomes

This project demonstrates proficiency in:

- **Procedural Content Generation**: Implementation of random walk algorithms for dungeon creation
- **Game Systems Design**: Turn-based combat, character progression, and save/load functionality  
- **Software Architecture**: Application of design patterns and modular system design
- **User Experience Design**: Accessible controls and clear visual feedback
- **Project Management**: Iterative development with regular testing and refinement
- **Technical Problem-Solving**: Debugging complex systems and optimising performance

## Getting Started

### Prerequisites
- Godot Engine 4.x
- Windows, Linux, or web browser for gameplay

### Installation Options

**Option 1: Direct Download (Recommended)**
1. Visit the itch.io page: https://naylith.itch.io/just-a-girls-dungeon-quest
2. Enter password: salma-fyp
3. Download the appropriate version for your platform
4. Extract and run the executable

**Option 2: Web Version**
1. Visit the same itch.io page
2. Enter password: salma-fyp  
3. Press "Run Game" and click fullscreen for best experience

**Option 3: Source Code**
1. Clone this repository
2. Run the executable from the release folder

### Controls
- **Arrow Keys**: Navigate menus and move character in dungeon
- **Spacebar/Enter**: Select options, advance dialogue, interact with objects
- **Mouse**: Required for save/load menu navigation

## Screenshots

*Screenshots showing procedural dungeon generation, turn-based combat interface, and character progression would be displayed here*

## Future Enhancements

Several areas identified for continued development:

- **Enhanced Procedural Generation**: Implementation of additional algorithms like Binary Space Partitioning
- **Extended Narrative**: More dialogue branches and character development opportunities
- **Advanced Enemy AI**: More sophisticated behaviours and group coordination
- **Accessibility Features**: Colour-blind modes, configurable controls, and screen reader support
- **Mobile Adaptation**: Touch controls and UI scaling for mobile platforms
- **Multiplayer Functionality**: Cooperative gameplay options

## Technical Challenges Overcome

- **Movement System**: Grid-based movement with smooth animations and collision detection
- **State Management**: Clean transitions between exploration and combat modes
- **Data Persistence**: Robust save/load system with error handling and data integrity checks
- **Difficulty Scaling**: Algorithm-driven progression that maintains player engagement
- **Performance Optimisation**: Efficient procedural generation suitable for real-time gameplay

## Development Notes

This project was completed over approximately 27 weeks as part of a Computer Science degree, with development following an iterative approach. Key milestones included core dungeon generation, combat system implementation, narrative integration, and final polish phases.

The codebase emphasises maintainability and extensibility, with clear separation between game systems and extensive use of design patterns. All code is thoroughly documented and structured for potential future expansion.

## Contributing

This project was developed as a final year academic project and serves primarily as a portfolio demonstration. The code is available for educational purposes and to showcase game development techniques and design patterns.

## Acknowledgments

- **Supervisor**: Julien Lange, Department of Computer Science, Royal Holloway
- **Foundation Tutorial**: Heartbeast's Godot dungeon crawler tutorial provided initial guidance
- **Base Framework**: Piotr's DungeonCrawler GitHub repository for basic mechanics
- **Asset Sources**: Various Creative Commons and placeholder assets used during development (see disclaimers in user manual)

## License

This project is for educational and portfolio purposes. It demonstrates academic work completed as part of a Computer Science degree programme.

---

*Developed as part of BSc Computer Science Final Year Project at Royal Holloway, University of London*
