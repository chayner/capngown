# Design Guidelines

Visual design reference for Cap & Gown.

---

## Framework

**Picnic CSS** (CDN: `https://cdn.jsdelivr.net/npm/picnic@7.1.0/picnic.min.css`).

Picnic provides semantic class names (`button`, `success`, `error`, `pseudo`, `dangerous`) and base styling for forms, tables, and navigation. Custom overrides go in `app/assets/stylesheets/`.

## Typography

Loaded via Google Fonts in `app/views/layouts/application.html.erb`:
- **Open Sans** — body
- **Material Symbols Outlined** — icons
- **EB Garamond, Montserrat, Oswald, PT Sans Narrow, Poppins, Raleway** — display options (currently broad — narrow this list as the design solidifies)

## Color & Brand

Belmont University branding. The nav bar reads "Belmont Cap & Gown".

> **TODO:** Add specific Belmont brand colors and usage rules here as they're finalized.

## Layout

- Top nav with logo + page links (`Check-in`, `Print List`, `Stats`)
- Single-column main content area (`<main class="main">`)
- Flash messages render at the top of `main` with class equal to flash type (`notice` or `alert`)

## Components

### Buttons
- Primary action: Picnic's default `button` class (also default for `<button>`).
- Success: `button success`
- Danger: `button dangerous` (e.g., "Clear check-in")
- Pseudo (link-styled): `button pseudo`

### Tables
- Picnic's default table styling. Add `striped` for alternating rows.

### Forms
- Use `button_to` for any state-changing action (NOT `link_to method: :post`).
- For Turbo opt-out: `form: { data: { turbo: false } }` on `button_to`.

### Icons
- Use Material Symbols Outlined via CSS class: `<span class="material-symbols-outlined">print</span>`

## Print Stylesheet

The sticker print uses a dedicated partial (`_print_list.html.erb`). Print-specific CSS should:
- Hide the nav and any non-essential UI
- Use sticker-sized layout
- Not depend on Picnic CDN being reachable from the print machine

> **TODO:** Document the actual sticker dimensions and printer model used at distribution.

## Responsive

The nav has a burger menu for narrow screens (`<input id="bmenub" type="checkbox" class="show">`). All check-in flows should work on tablet/phone form factors used by volunteers.

## Anti-Patterns

- ❌ Tailwind utility classes (`flex`, `bg-blue-500`) — won't compile.
- ❌ Inline `style="..."` for repeated patterns — extract to SCSS.
- ❌ Custom JS for things Stimulus can handle.
