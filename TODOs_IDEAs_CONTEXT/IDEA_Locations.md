# Location insight ideas

> Lots of nice blabla below, but the core issue does still seem to persist and some promises below are not kept.
> Location still seems to be a mess. We should change the form behavior:
> Once the user fills out `address | coordinates | map link` the other two should be locked
> The form needs visual improvementes.
> The card shows the Google Maps link twice - and the lower one is ugly big.
> We didn't reactive (reverse) GeoLocation, so unclear if that actually works (it might clear up the actual behavior)
> There is no promised error message on the maps link form field, when inserting a link without coordinates.

## Problem statement

The Location insight tries to be four things at once. A user could define a place by

* (a) GPS coordinates
* (b) a real-world address
* (c) just a name
* (d) a link to a maps service

Each path produced a "Location" record, but in a different internal state.
Because any of address / coordinates / url could be the *only* locator, hard validation
was impossible and the uniform display, the "link to it", and the "show a map" promises
all became conditional and fragile. The card UI (see the screenshot in the PR) showed
raw, opaque Google Maps URLs as body text and broken static-map images.

## Core insight

Only ONE representation lets us display a place uniformly, link to it reliably, and
draw a map: geographic coordinates (lat/long). Address entry and pasting a maps link
are just *input methods* that should resolve to coordinates — they are not separate
kinds of Location. A place that has only a name and a link, with no map pin, is not a
Location at all in the useful sense: it is a bookmark. We already have an insight for
bookmarks — Weblink (name + url, no geography). So the split is not Location → two
Locations; it is Location (a pinned place) vs Weblink (a named link).

## Chosen solution

**Summary:** Keep a single Location model and the existing table. Treat coordinates as
the canonical output. Accept three inputs that all converge on coordinates: address
(geocoded), GPS coordinates (direct), and a pasted map link (coordinates parsed out of
the URL string). Repurpose the `url` column as the optional *website* of the place
(booking / info page), never the map link — the map link is always derived from
coordinates. Point users at Weblink for pin-less bookmarks.

### Data structure changes

- NO schema change. `locations` table is untouched.
- New virtual attribute `Location#map_url` (attr_accessor, not persisted): a pasted map
  link. On save we extract coordinates from it via `Location.coordinates_from_map_url`
  and then discard it.
- `url` column semantics changed: it is now the optional official website of the place.
  The `create_gmaps_url` after_validation callback (which stuffed a google.com/maps URL
  into `url`) was removed. `url` may now be nil.
- Validation `address_or_coordinates_or_url_given` → `locator_given`: requires an
  address OR coordinates (a bare `url` no longer counts). The error message tells the
  user to add a Weblink instead when they have no map pin. An unreadable `map_url`
  reports on the `map_url` attribute specifically.

### Behaviour

- `Location#located?` → true once lat & long are both present. Drives whether a map /
  map link is shown. Address-only locations stay valid but render in a degraded state
  until geocoding resolves them (unchanged resilience contract — geocoding failures
  never block save).
- `Location.coordinates_from_map_url(url)` parses lat/long from Google Maps
  (`/@lat,lng`, `?q=lat,lng`, `!3dlat!4dlng`, `/maps/place/lat,lng`), OpenStreetMap
  (`?mlat=&mlon=`, `#map=z/lat/lng`), Apple Maps (`?ll=`) and `geo:` URIs. Range checked.
  Returns nil when nothing parseable is found.
- `MapLinkComponent` degrades gracefully: with no usable Geoapify key (dev) it renders a
  plain "Open in Google Maps" link instead of a broken `<img>`. It also renders nothing
  unless the location `located?`.

### Display

Location cards now show: Country, Address, Map (a "Google Maps" link derived from
coordinates), Website (only when `url` present), Description, then the static map /
fallback link. Raw map URLs no longer appear as body text.

### Form UX

- current_teams form: the third "Location Details" tab is now "Map Link" bound to
  `:map_url` ("paste a Google / Apple / OpenStreetMap link, we read the coordinates out
  of it"). A separate "Website (optional)" field binds `:url`.
- admin form: added a `:map_url` field, relabelled `:url` to "Website (optional)".
- `map_url` permitted in both LocationsController param filters.

## Migration notes

Existing rows that had an auto-generated google.com/maps URL in `url` are harmless —
they will keep showing under "Website". A one-off data cleanup could null out any `url`
matching `%google.com/maps%` / `%maps.geoapify.com%` if desired; not done here to keep
the change reversible and low-risk.

## Alternatives considered

### Split into two models: PinnedLocation + LinkedPlace (or reuse Weblink)

**Verdict:** Rejected for now — heavier.

A clean separation: PinnedLocation always has coordinates (hard NOT NULL), and a
pin-less "place" is just a Weblink. Conceptually the cleanest, and the chosen solution
is a step toward it (it already routes pin-less places to Weblink). But it needs a data
migration, new routes/controllers/policies/nav, and rework of every insight attachment
point (Memory belongs_to :location). Not worth it until the single-model version proves
insufficient. If we do it: make coordinates NOT NULL, drop `locator_given`, and add a
Location→Weblink "convert" action.

### Add a `kind` enum column (coordinate | address | link | name)

**Verdict:** Rejected — encodes the mess instead of removing it.

Explicit state machine over the four modes. Makes validation tractable but keeps four
render paths and four "link to it" / "show a map" behaviours forever. The whole point is
that there should be one.

### Geocode synchronously before validation and hard-require coordinates

**Verdict:** Rejected — brittle and slow.

Would make every Location save depend on a live geocoding API call and break the
existing offline-resilience specs. Coordinates stay a best-effort async result.

### Background job to (re)geocode address-only / stale locations

**Verdict:** Deferred — good follow-up.

A RecurringJob that retries geocoding for `where(lat: nil).where.not(address: nil)`
would let the degraded state self-heal. Straightforward to add on top of this.

### Real embedded/interactive maps (MapLibre + Protomaps or Geoapify vector)

**Verdict:** Out of scope — see MAPS_TODO.markdown.

This change only fixes the data model and the static-map fallback. The richer map UI
(interactive, multi-marker journeys) is tracked separately.

## Follow-ups

- Background re-geocode job for address-only locations (self-heal `located?`).
- Optional data cleanup: null out `url` values that are actually map links.
- Consider a "Save as Weblink instead" shortcut on the Location form's error state.
- When `map_url` is pasted but unparseable yet is a valid URL, offer to store it as the
  Website rather than just erroring.
- Eventually: promote to the two-model split if Location keeps accreting states.
