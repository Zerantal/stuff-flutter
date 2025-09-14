# Notes for the stuff_flutter project


---

## 1. Spruce up UI & theming

* **Color scheme & typography**
  Use `ColorScheme.fromSeed` with a brand-like accent. Tweak `textTheme` for headings (so your “Name”/“Description” labels in view mode pop).
* **Consistent padding & spacing**
  Consider a design tokens file with constants for spacing, corner radius, elevation, etc.
* **Custom widgets**

    * `LabeledValue(label, value)` for view-only mode.
    * Consistent `EntityCard` styles (Location, Room, Container, Item).
* **Animation polish**
  You’re already using `AnimatedSwitcher`. Try `PageTransitionSwitcher` (from the `animations` package) for shared-axis transitions (nice for “view → edit”).

---

## 2. Plan next feature additions

Think of these in layers:

**Core extensions**

* 🔍 **Search & filter** across items/locations.
* 📸 **Image enhancements** — mark a “primary image” for an item, zoomable viewer.
* 🗃️ **Tags or categories** to group items beyond physical location.
* 📑 **Export/import** data (CSV/JSON).

**Quality of life**

* 🔔 Reminders/alerts (e.g. warranty expiry, consumables running low).
* 📥 Quick-add flows (e.g. scan barcode or voice entry → new item).
* 🗂️ Bulk operations (multi-select → delete/move).

**Platform features**

* 🖥️ Desktop optimisations (wider grid layouts, keyboard shortcuts).
* 📱 Mobile camera integration for faster item entry.
* ☁️ Sync (later: cloud backend, sharing between household members).

---

## 3. Roadmap suggestion

1. **Polish UI** (theme, typography, cards, animations).
2. **Add search/filter + tagging** → biggest usability win.
3. **Bulk editing & quick add** → improves day-to-day use.
4. **Data portability** (export/import).
5. **Optional sync/sharing** (longer-term).

---

👉 Would you like me to sketch a **short visual style guide** (colors, typography scale, padding system) so you have a foundation for the UI spruce-up?


