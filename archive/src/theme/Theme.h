#ifndef THEME_H
#define THEME_H

#include <QColor>
#include <QString>

namespace Theme {
    // Color Palette (from OKLCH in globals.css, converted to HEX)
    const QColor BACKGROUND = QColor("#1a1826");
    const QColor FOREGROUND = QColor("#f1f0f2");
    const QColor CARD = QColor("#221e30");
    const QColor CARD_FOREGROUND = QColor("#f1f0f2");

    const QColor PRIMARY = QColor("#dc3545");  // Crimson Red
    const QColor PRIMARY_FOREGROUND = QColor("#f9f8fa");

    const QColor SECONDARY = QColor("#352e4d");
    const QColor SECONDARY_FOREGROUND = QColor("#f1f0f2");

    const QColor MUTED = QColor("#2d283d");
    const QColor MUTED_FOREGROUND = QColor("#9a96a5");

    const QColor ACCENT = QColor("#8c52ff");
    const QColor ACCENT_FOREGROUND = QColor("#f1f0f2");

    const QColor DESTRUCTIVE = QColor("#d23a1a");
    const QColor DESTRUCTIVE_FOREGROUND = QColor("#f1f0f2");

    const QColor BORDER = QColor("#3e3754");
    const QColor INPUT = QColor("#3e3754");
    const QColor RING = QColor("#dc3545");

    // Standard Spacing Values (in pixels)
    constexpr int SPACING_XS = 4;      // Extra small spacing
    constexpr int SPACING_SM = 8;      // Small spacing (small buttons, tight spacing)
    constexpr int SPACING_MD = 15;     // Medium spacing (default content margins)
    constexpr int SPACING_LG = 20;     // Large spacing (standard container margins)
    constexpr int SPACING_XL = 30;     // Extra large spacing

    // Border and Radius Standards
    constexpr int BORDER_RADIUS_SM = 4;      // Small border radius (buttons, inputs)
    constexpr int BORDER_RADIUS_MD = 6;      // Medium border radius (cards, dialogs)
    constexpr int BORDER_RADIUS_LG = 8;      // Large border radius (panels, windows)
    constexpr int BORDER_RADIUS_XL = 12;     // Extra large border radius (overlays)

    constexpr int BORDER_WIDTH_THIN = 1;         // Thin borders
    constexpr int BORDER_WIDTH_MEDIUM = 2;       // Medium borders (cards, focus)
    constexpr int BORDER_WIDTH_THICK = 3;        // Thick borders (accents, selections)

    constexpr int SCROLLBAR_WIDTH = 12;      // Standard scrollbar width

    // Fonts and Typography
    const QString FONT_FAMILY = "Inter, Segoe UI, sans-serif";
    constexpr int FONT_SIZE_XS = 10;         // Extra small (labels, badges)
    constexpr int FONT_SIZE_SM = 12;         // Small (secondary text)
    constexpr int FONT_SIZE_MD = 14;         // Medium (body text, buttons)
    constexpr int FONT_SIZE_LG = 16;         // Large (headers, important buttons)
    constexpr int FONT_SIZE_XL = 18;         // Extra large (titles)
    constexpr int FONT_SIZE_XXL = 24;        // Double extra large (main titles)
    constexpr int FONT_SIZE_XXXL = 36;       // Triple extra large (hero titles)

    constexpr int FONT_WEIGHT_NORMAL = 400;    // Normal weight
    constexpr int FONT_WEIGHT_MEDIUM = 500;    // Medium weight (buttons, emphasis)
    constexpr int FONT_WEIGHT_SEMIBOLD = 600;  // Semibold (headers)
    constexpr int FONT_WEIGHT_BOLD = 700;      // Bold (strong emphasis)
}

#endif // THEME_H