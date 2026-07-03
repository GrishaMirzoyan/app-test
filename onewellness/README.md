# OneWellness — Los Angeles

A single-page marketing site for OneWellness, a beauty & health medspa in Los Angeles focused on IV therapy, peptide programs, and physical therapy, plus the **TimeLess** anti-aging membership program.

## Design

- **Wood & green identity** — deep pine and moss greens with walnut/oak wood accents, warm linen ground, and subtle wood-grain/noise textures.
- **Typography** — Fraunces (display serif) + Figtree (body), both embedded as data-URI web fonts, so the page has **zero external dependencies** and works offline or on any static host.
- **Animations** — staggered hero entrance, drifting ambient light, an IV-droplet motif, scroll-triggered reveals, animated stat counters, an LA-neighborhood marquee, and hover micro-interactions. All motion respects `prefers-reduced-motion`.
- **One page** — services, the TimeLess program, and the full price list live on a single page with a sticky category chip bar that scroll-spies as you browse the menu.
- **Booking** — a 60-second request form (name, phone, service, day, time of day) with a confirmation state, plus a floating "Book a visit" pill that follows the visitor. Also light/dark theme aware.

## Running it

It's one self-contained file — no build step:

```
open onewellness/index.html
```

or serve it statically (`npx serve onewellness`).

## Hooking up real bookings

The form is front-end only: it validates, then shows a confirmation. To take real bookings, wire the `submit` handler in the inline `<script>` to your scheduler of choice (Calendly/Acuity embed, or a POST to your backend/SMS provider). Placeholder contact details (phone, address, email, socials) are marked in the footer and booking section — replace before launch.
