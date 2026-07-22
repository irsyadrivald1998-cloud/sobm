---
name: Industrial Futurist BMS
colors:
  surface: '#1e0f0e'
  surface-dim: '#1e0f0e'
  surface-bright: '#473533'
  surface-container-lowest: '#180a09'
  surface-container-low: '#271816'
  surface-container: '#2c1b1a'
  surface-container-high: '#372624'
  surface-container-highest: '#43302e'
  on-surface: '#f9dcd9'
  on-surface-variant: '#e4beba'
  inverse-surface: '#f9dcd9'
  inverse-on-surface: '#3e2c2a'
  outline: '#ab8985'
  outline-variant: '#5b403d'
  surface-tint: '#ffb3ac'
  primary: '#ffb3ac'
  on-primary: '#680008'
  primary-container: '#d32f2f'
  on-primary-container: '#fff2f0'
  inverse-primary: '#ba1a20'
  secondary: '#c8c6c5'
  on-secondary: '#303030'
  secondary-container: '#474746'
  on-secondary-container: '#b7b5b4'
  tertiary: '#7bd1f8'
  on-tertiary: '#003546'
  tertiary-container: '#00799c'
  on-tertiary-container: '#e9f7ff'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffdad6'
  primary-fixed-dim: '#ffb3ac'
  on-primary-fixed: '#410003'
  on-primary-fixed-variant: '#930010'
  secondary-fixed: '#e5e2e1'
  secondary-fixed-dim: '#c8c6c5'
  on-secondary-fixed: '#1b1b1c'
  on-secondary-fixed-variant: '#474746'
  tertiary-fixed: '#bee9ff'
  tertiary-fixed-dim: '#7bd1f8'
  on-tertiary-fixed: '#001f2a'
  on-tertiary-fixed-variant: '#004d65'
  background: '#1e0f0e'
  on-background: '#f9dcd9'
  surface-variant: '#43302e'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  title-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.05em
  label-sm:
    fontFamily: Inter
    fontSize: 10px
    fontWeight: '600'
    lineHeight: 12px
    letterSpacing: 0.05em
  display-lg-mobile:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  gutter: 16px
  margin-mobile: 16px
  margin-tablet: 24px
---

## Brand & Style
The design system is engineered for high-stakes building management, evoking a sense of **Reliability, Efficiency, and Power**. The aesthetic follows an **Industrial Futurist** direction, blending the high-utility of enterprise tools with the premium finish of luxury automotive interfaces.

The UI is rooted in **Minimalism** with a **Corporate Modern** structure. It prioritizes data density and immediate legibility under various lighting conditions (mechanical rooms to bright offices). By using a monochromatic dark foundation punctuated by aggressive, high-chroma red accents, the system creates a focused environment where critical status changes are impossible to ignore.

## Colors
The palette is dominated by deep blacks and charcoals to reduce eye strain during long monitoring shifts and to provide a premium "command center" feel.

- **Foundational Layers**: Use `#0F0F0F` for the canvas. `#121212` and `#1E1E1E` are used for structural grouping, creating a hierarchy of depth without relying on light-colored borders.
- **Accent System**: `#D32F2F` (Primary Red) is reserved for primary actions and brand identifiers. 
- **Alert Tiers**: Use `#F44336` (Bright Red) exclusively for "Critical Alarms." This color should occupy no more than 5% of the total screen real estate to maintain its psychological impact.
- **Functional States**: Status colors follow industry standards but are calibrated for high contrast against dark surfaces.

## Typography
**Inter** is the sole typeface, chosen for its exceptional legibility in technical contexts and wide range of weights.

- **Data Readability**: For numerical data (temperatures, pressure levels), use Medium or SemiBold weights to ensure "glanceability."
- **Hierarchy**: Use `label-md` and `label-sm` with uppercase transformation for non-interactive metadata and section headers to create an architectural, blueprint-like feel.
- **Contrast**: Maintain a minimum contrast ratio of 7:1 for all body text against the dark backgrounds. Use `Pure White (#FFFFFF)` for primary text and `70% Opacity White` for secondary text.

## Layout & Spacing
This design system utilizes a strict **8px Grid System**. All components, icons, and layout structures must be multiples of 8 to ensure visual mathematical harmony.

- **Mobile Layout**: A 4-column fluid grid with 16px side margins. 
- **Content Density**: In "Monitoring" views, vertical spacing can be compressed to 4px or 8px (sm) to display more data points. In "Configuration" or "Settings" views, use 16px (md) or 24px (lg) to provide a more relaxed, premium feel.
- **Safe Areas**: Ensure all interactive elements (buttons, toggles) are within the center columns, respecting the bottom home indicator safe area of mobile devices.

## Elevation & Depth
Elevation in this system is achieved through **Tonal Layering** rather than traditional drop shadows. This creates a "machined" look where elements appear as if they are precisely cut into or placed upon the surface.

- **Level 0 (Background)**: `#0F0F0F` - The base canvas.
- **Level 1 (Cards/Containers)**: `#1E1E1E` - Standard surface for grouping content.
- **Level 2 (Dialogs/Popovers)**: `#252525` - Elevated surfaces. These receive a subtle `0.5px` border of `White (10% Opacity)` to define the edge against the dark background.
- **Shadows**: Use only for Level 2 elements. Shadows should be ultra-diffused: `0px 8px 24px rgba(0, 0, 0, 0.5)`.

## Shapes
The shape language balances industrial precision with modern ergonomics.

- **Standard Elements**: All cards, input fields, and buttons use a **16px (rounded-lg)** radius. This softens the "harshness" of the dark industrial theme, making the app feel approachable and modern.
- **Small Elements**: Chips, tags, and small status indicators use an **8px (rounded-md)** radius.
- **Icons**: Use a consistent corner radius for custom iconography to match the UI's roundedness.

## Components
Consistent implementation of components ensures the system feels like a singular high-performance tool.

- **Buttons**:
  - **Primary**: Solid `#D32F2F` background with white text. No shadow; use a subtle inner glow (top border) for a tactile feel.
  - **Secondary**: Outlined with `White (20% Opacity)` and white text.
- **Status Chips**: Small, pill-shaped indicators. Use a subtle background (20% opacity of the status color) with high-intensity text/icon of the same color (e.g., Green text on dark-green bg).
- **Cards**: Use `#1E1E1E` background with a 16px corner radius. No border unless the card is "Active/Selected," in which case use a 2px `#D32F2F` stroke.
- **Input Fields**: Filled style using `#252525`. Bottom-heavy focus state using a 2px Primary Red line.
- **Gauges & Charts**: Use thin stroke weights (1px to 2px) for data visualizations. Avoid solid fills in charts; use gradients that fade into the background to maintain the "Glassmorphism Lite" feel.
- **Critical Alarms**: A specialized full-width banner component with a pulse animation using the Primary Red, intended to grab immediate attention.