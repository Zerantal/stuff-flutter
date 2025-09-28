## 1. Spruce up UI & theming

* **Theming**: develop theme
    * Use `ColorScheme.fromSeed` with a brand-like accent. Tweak `textTheme` for headings (so your “Name”/“Description” labels in view mode pop).
* Develop design tokens file
* Replace hard coded paddings/styles with tokens
    *  Consider a design tokens file with constants for spacing, corner radius, elevation, etc.
* **Custom widgets**
    * `LabeledValue(label, value)` for view-only mode.
    * Consistent `EntityCard` styles (Location, Room, Container, Item).
  
* **Animation polish**
  You’re already using `AnimatedSwitcher`. Try `PageTransitionSwitcher` (from the `animations` package) for shared-axis transitions (nice for “view → edit”).