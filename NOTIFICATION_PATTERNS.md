# PyRPG Qt Notification/Toast Patterns Documentation

## Executive Summary

The PyRPG Qt codebase uses a **primarily modal dialog-based notification system** with a new **non-intrusive combat log (LogDisplay)** component for passive messaging. The recommended pattern for lore discovery notifications is the **LogDisplay combat log**, which is already integrated and provides non-blocking, theme-consistent feedback.

---

## Existing Notification Patterns

### 1. Quest Completion Notifications

**Pattern Type:** Modal Dialog (Intrusive)

**Files:**
- `/Users/matt.taylor/codeprojects/pyrpg/take2/cpp-qt-rpg/src/components/QuestCompletionDialog.h`
- `/Users/matt.taylor/codeprojects/pyrpg/take2/cpp-qt-rpg/src/components/QuestCompletionDialog.cpp`

**Implementation Details:**
- Uses `QDialog` with `setModal(true)` - blocks player interaction
- Shows celebratory header: "🎉 QUEST COMPLETE! 🎉"
- Displays rewards: Experience, Gold, Items
- Styled with Theme color constants:
  - Background: `Theme::CARD` (dark)
  - Border: 2px solid `Theme::BORDER`
  - Title text: `Theme::PRIMARY` (blue)
  - Button: `Theme::ACCENT` (crimson red)

**Code Example:**
```cpp
// File: QuestCompletionDialog.cpp, lines 37-44
QLabel *celebrationLabel = new QLabel("🎉 QUEST COMPLETE! 🎉");
celebrationLabel->setAlignment(Qt::AlignCenter);
celebrationLabel->setStyleSheet(QString(
    "font-size: %1px; font-weight: %2; color: %3; margin: 10px 0px;"
).arg(Theme::FONT_SIZE_XL)
 .arg(Theme::FONT_WEIGHT_BOLD)
 .arg(Theme::ACCENT.name()));
```

**Non-Intrusive Level:** ⭐⭐ (Medium - Blocks gameplay until dismissed)

---

### 2. Combat Result & Level-Up Notifications

**Pattern Type:** Modal Dialog with Conditional Content

**Files:**
- `/Users/matt.taylor/codeprojects/pyrpg/take2/cpp-qt-rpg/src/components/CombatResultDialog.h`
- `/Users/matt.taylor/codeprojects/pyrpg/take2/cpp-qt-rpg/src/components/CombatResultDialog.cpp`

**Implementation Details:**
- Modal dialog appears after combat ends
- Victory vs. Defeat variants (title changes, rewards only on victory)
- **Level-up notification** embedded within victory dialog (lines 39-51):
  - Conditional display: Only shows if `leveledUp == true`
  - Label: "⭐ LEVEL UP! ⭐" (20pt bold)
  - Styled with blue background and contrasting foreground
  - Positioned above rewards section

**Code Example (Level-Up):**
```cpp
// File: CombatResultDialog.cpp, lines 39-51
if (leveledUp) {
    QLabel *levelUpLabel = new QLabel("⭐ LEVEL UP! ⭐");
    QFont levelUpFont;
    levelUpFont.setPointSize(20);
    levelUpFont.setBold(true);
    levelUpLabel->setFont(levelUpFont);
    levelUpLabel->setAlignment(Qt::AlignCenter);
    levelUpLabel->setStyleSheet(QString("color: %1; background-color: %2; "
                                        "padding: 15px; border-radius: 8px; margin: 10px;")
                                   .arg(Theme::PRIMARY_FOREGROUND.name())
                                   .arg(Theme::PRIMARY.name()));
    mainLayout->addWidget(levelUpLabel);
}
```

**Non-Intrusive Level:** ⭐⭐ (Low - Expected integral part of combat result)

---

### 3. Combat Log Messages (LogDisplay)

**Pattern Type:** Non-Intrusive Scrollable Log Widget

**Files:**
- `/Users/matt.taylor/codeprojects/pyrpg/take2/cpp-qt-rpg/src/components/LogDisplay.h` (lines 1-52)
- `/Users/matt.taylor/codeprojects/pyrpg/take2/cpp-qt-rpg/src/components/LogDisplay.cpp` (full implementation)

**Implementation Details:**
- Custom QWidget inheriting from parent
- Scrollable area with configurable max entries (default: 20)
- Uses QScrollArea with custom styling
- Color-coded message types with left border indicators
- Auto-scrolls to newest entries
- Theme-integrated styling

**Message Types and Colors:**
```cpp
// File: LogDisplay.cpp, lines 17-25
QColor LogEntry::getBorderColor() const
{
    if (messageType == "info") return Theme::MUTED_FOREGROUND;
    if (messageType == "success") return QColor("#28a745");      // Green
    if (messageType == "warning") return QColor("#ffc107");      // Yellow
    if (messageType == "error") return Theme::DESTRUCTIVE;       // Red
    if (messageType == "combat") return Theme::PRIMARY;          // Blue
    return Theme::MUTED_FOREGROUND;
}
```

**Visual Styling:**
- Left border: 3px thick, color-coded
- Padding-left: 8px
- Background: Transparent
- Container: `Theme::CARD` background with border
- Text: `Theme::FOREGROUND` color

**Usage Pattern:**
```cpp
// File: CombatPage.h, line 24
void addLogEntry(const QString &message, const QString &type = "");

// Example usage in MainWindow.cpp, line 756
m_combatPage->addLogEntry(QString("New Codex Entry: %1").arg(title), "lore");
```

**Non-Intrusive Level:** ⭐⭐⭐⭐⭐ (Very High - Passive log, no interaction required)

---

### 4. Lore Discovery Notifications (CURRENT)

**Pattern Type:** Combat Log Entry (Non-Intrusive)

**Files:**
- `/Users/matt.taylor/codeprojects/pyrpg/take2/cpp-qt-rpg/src/game/CodexManager.h` (lines 32-33)
- `/Users/matt.taylor/codeprojects/pyrpg/take2/cpp-qt-rpg/src/game/CodexManager.cpp` (lines 39-52)
- `/Users/matt.taylor/codeprojects/pyrpg/take2/cpp-qt-rpg/src/MainWindow.cpp` (lines 753-757)

**Signal Flow:**
```
CodexManager::unlockEntry()
    ↓
Emits: CodexManager::loreUnlocked(entryId, title)
    ↓
MainWindow::handleLoreUnlocked()
    ↓
m_combatPage->addLogEntry("New Codex Entry: ...", "lore")
```

**Implementation:**
```cpp
// File: MainWindow.cpp, lines 753-757
void MainWindow::handleLoreUnlocked(const QString &entryId, const QString &title)
{
    // Show notification in combat log
    m_combatPage->addLogEntry(QString("New Codex Entry: %1").arg(title), "lore");
}
```

**Current Status:** 
- ✅ Non-blocking
- ✅ Theme-consistent
- ✅ Appears in chronological log
- ⚠️ "lore" message type not visually distinct (uses default color)

**Non-Intrusive Level:** ⭐⭐⭐⭐⭐ (Very High - Optimal for lore discovery)

---

### 5. Victory Screen (Game Completion)

**Pattern Type:** Full-Screen Modal Dialog

**Files:**
- `/Users/matt.taylor/codeprojects/pyrpg/take2/cpp-qt-rpg/src/views/VictoryScreen.h`
- `/Users/matt.taylor/codeprojects/pyrpg/take2/cpp-qt-rpg/src/views/VictoryScreen.cpp`

**Implementation Details:**
- Large modal showing game completion statistics
- Grid layout: 2 columns × 3 rows of statistics cards
- Statistics: Level, Playtime, Kills, Deaths, Gold, Quests
- Header: "🏆 VICTORY! 🏆" with gradient and glow effect
- Two action buttons: Continue Playing, Return to Main Menu
- Minimum size: 800×600
- Keyboard shortcuts: Space/Enter=Continue, Esc=Menu

**Non-Intrusive Level:** ⭐⭐ (Low - Expected, full-screen, requires dismissal)

---

### 6. Menu Overlay (Animated Modal Overlay)

**Pattern Type:** Semi-Transparent Animated Overlay

**Files:**
- `/Users/matt.taylor/codeprojects/pyrpg/take2/cpp-qt-rpg/src/components/MenuOverlay.h`
- `/Users/matt.taylor/codeprojects/pyrpg/take2/cpp-qt-rpg/src/components/MenuOverlay.cpp`

**Implementation Details:**
- QWidget with `WA_TranslucentBackground` attribute
- Opacity animation: 200ms fade in/out using QPropertyAnimation
- Semi-transparent black background (70% opacity when fully visible)
- Content widget styled as card with accent border
- Tab-based interface: Inventory, Stats, Shop, Save/Load
- Dismissible: ESC key or click outside content
- Restores focus to previous widget on close

**Visual Properties:**
```cpp
// File: MenuOverlay.cpp, line 34
m_animation = new QPropertyAnimation(this, "opacity");
m_animation->setDuration(200);

// File: MenuOverlay.cpp, lines 323-325
QColor overlayColor = QColor(0, 0, 0);
overlayColor.setAlphaF(0.7 * m_opacity);
painter.fillRect(rect(), overlayColor);
```

**Non-Intrusive Level:** ⭐⭐⭐ (Medium - Overlay with semi-transparent background)

---

## Qt Notification Patterns Used

### QMessageBox
**Status:** ❌ Not used in codebase
- App uses custom dialogs instead for consistency

### Custom QDialog Subclasses
**Status:** ✅ Primary notification method

All major notifications inherit from `QDialog`:
- `QuestCompletionDialog` - Quest completion
- `CombatResultDialog` - Combat results with embedded level-up
- `StoryEventDialog` - Narrative events
- `DialogueView` - NPC dialogue
- `VictoryScreen` - Game completion

All use `Theme::` constants for consistent styling.

### Custom QWidget Overlays
**Status:** ✅ Secondary pattern for non-modal overlays

- `MenuOverlay` - Animated semi-transparent overlay
- `ItemSelectionOverlay` - Modal dialog-based item selection
- Uses `QPropertyAnimation` for smooth transitions

### StatusBar
**Status:** ❌ Not used
- Application uses full QStackedWidget page-based navigation
- No application-level status bar

### LogDisplay Widget
**Status:** ✅ New pattern for passive logging

- Custom QWidget for scrollable message log
- Supports multiple message types with color coding
- Theme-integrated styling
- Non-blocking message display

---

## Recommended Pattern for Lore Discovery

### Primary Recommendation: LogDisplay Combat Log

**Why This Pattern:**
1. **Non-Intrusive** - Doesn't block gameplay or require interaction
2. **Already Integrated** - Signal-to-slot connection already exists in MainWindow
3. **Theme-Consistent** - Uses existing color and styling system
4. **Discoverable** - Appears chronologically in log for player review
5. **Context-Appropriate** - Players naturally check combat log during exploration
6. **Scalable** - Can handle many lore discoveries without UI congestion
7. **Immersive** - Doesn't break narrative flow with modal interruption

**Current Implementation Status:**
```cpp
// File: MainWindow.cpp, line 756
m_combatPage->addLogEntry(QString("New Codex Entry: %1").arg(title), "lore");
```

✅ Works as-is, but could be enhanced:

**Enhancement: Add Dedicated "Lore" Color**

Current issue: "lore" message type not handled in `getBorderColor()`, falls back to default

**Implementation:**
```cpp
// File: LogDisplay.cpp, lines 17-25
QColor LogEntry::getBorderColor() const
{
    if (messageType == "info") return Theme::MUTED_FOREGROUND;
    if (messageType == "success") return QColor("#28a745");
    if (messageType == "warning") return QColor("#ffc107");
    if (messageType == "error") return Theme::DESTRUCTIVE;
    if (messageType == "combat") return Theme::PRIMARY;
    if (messageType == "lore") return QColor("#9d4edd");  // Purple for lore
    return Theme::MUTED_FOREGROUND;
}
```

**Enhanced Usage:**
```cpp
// Option 1: Emoji prefix for visual distinction
m_combatPage->addLogEntry(
    QString("📖 New Codex Entry: %1").arg(title), 
    "lore"
);

// Option 2: Richer description
m_combatPage->addLogEntry(
    QString("Discovered: %1").arg(title), 
    "lore"
);
```

---

## Secondary Options

### Toast Notification Widget
**Use Case:** Brief visual feedback for major lore discoveries

**Approach:**
- Floating QWidget positioned at screen edge
- Auto-hide timer (3-5 seconds)
- Animated fade in/out
- Optional sound effect

**Pros:**
- Visual emphasis, attention-grabbing
- Non-blocking with auto-dismiss

**Cons:**
- Can distract during gameplay
- Requires custom implementation

---

### Story Event Dialog
**Use Case:** Major lore discoveries tied to quests/narrative events

**File:**
- `/Users/matt.taylor/codeprojects/pyrpg/take2/cpp-qt-rpg/src/views/StoryEventDialog.h`

**Pros:**
- Full narrative context
- Immersive presentation
- Can include multiple story paragraphs

**Cons:**
- Blocks gameplay
- Not suitable for minor/frequent discoveries

---

## Implementation Checklist

For enhancing lore discovery notifications:

### Phase 1: Add Dedicated Lore Color
- [ ] Modify `LogDisplay.cpp` `getBorderColor()` to handle "lore" type
- [ ] Choose color (suggested: purple `#9d4edd` or custom accent)
- [ ] Update `LogEntry` header comments to document message types

### Phase 2: Testing
- [ ] Trigger lore discovery during gameplay
- [ ] Verify log entry appears with correct color
- [ ] Test multiple rapid discoveries
- [ ] Verify scroll behavior with many entries

### Phase 3: Optional Enhancements
- [ ] Add emoji prefix to lore entries (e.g., "📖")
- [ ] Consider toast notification for rare discoveries
- [ ] Add lore discovery sound effect
- [ ] Track new/unread lore entries for main menu badge

### Phase 4: Documentation
- [ ] Document lore message type in code comments
- [ ] Update CLAUDE.md with LogDisplay usage guide
- [ ] Create lore discovery flow diagram

---

## Code Reference Files

### Core Notification Components
- **LogDisplay** (Non-Intrusive):
  - `/Users/matt.taylor/codeprojects/pyrpg/take2/cpp-qt-rpg/src/components/LogDisplay.h`
  - `/Users/matt.taylor/codeprojects/pyrpg/take2/cpp-qt-rpg/src/components/LogDisplay.cpp`

### Lore System Integration
- **CodexManager Signal**:
  - `/Users/matt.taylor/codeprojects/pyrpg/take2/cpp-qt-rpg/src/game/CodexManager.h` (lines 32-33)
  - `/Users/matt.taylor/codeprojects/pyrpg/take2/cpp-qt-rpg/src/game/CodexManager.cpp` (lines 39-52)

- **MainWindow Handler**:
  - `/Users/matt.taylor/codeprojects/pyrpg/take2/cpp-qt-rpg/src/MainWindow.cpp` (lines 753-757)

### Level-Up Pattern (Reference)
- `/Users/matt.taylor/codeprojects/pyrpg/take2/cpp-qt-rpg/src/components/CombatResultDialog.cpp` (lines 39-51)

### Theme System
- `/Users/matt.taylor/codeprojects/pyrpg/take2/cpp-qt-rpg/src/theme/Theme.h` (color constants)

---

## Summary

| Pattern | Type | Intrusive | Blocking | Theme | Location |
|---------|------|-----------|----------|-------|----------|
| Quest Completion | Modal | ⭐⭐ | Yes | Consistent | QuestCompletionDialog |
| Level Up | Modal | ⭐⭐ | Yes | Consistent | CombatResultDialog |
| Combat Log | Widget | ⭐⭐⭐⭐⭐ | No | Consistent | LogDisplay/CombatPage |
| **Lore Discovery** | **Widget** | **⭐⭐⭐⭐⭐** | **No** | **Consistent** | **LogDisplay** |
| Victory Screen | Modal | ⭐⭐ | Yes | Consistent | VictoryScreen |
| Menu Overlay | Overlay | ⭐⭐⭐ | Semi | Consistent | MenuOverlay |

**Recommendation:** Use the **LogDisplay combat log pattern** for lore discovery notifications. It's already integrated, non-intrusive, and provides the optimal player experience for frequent, contextual discoveries.
