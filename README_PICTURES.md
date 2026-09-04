# Pictures — upload, conversion, metadata

> We should really improve picture display - they should take in more space in the cards, propably full width.
> When opening a card pictures should be shown even larger.
> And we should use the coordinates to either generate a Location from it, or to show the pictures on a map.

How Yournaling ingests, stores and describes uploaded images.

## Pipeline overview

```
ActionDispatch::Http::UploadedFile (any allowed format)
        │
        ▼  Picture#assign_uploaded_file(file, name:, date:)
        │
  ┌─────┴─────────────────────────────┐
  │ 1. Images::MetadataExtractor.call │  reads the ORIGINAL bytes:
  │    (libvips geometry + exifr EXIF)│  geometry, orientation, GPS,
  │                                   │  capture time, camera
  └─────┬─────────────────────────────┘
        │  → stored on Picture columns (taken_at, latitude, longitude,
        │    altitude, camera_make/model, image_width/height,
        │    original_byte_size, original_content_type)
        ▼
  ┌───────────────────────────────────┐
  │ 2. ImageUploadConversionService   │  transforms the pixels:
  │    (ImageProcessing::Vips)        │  auto-rotate → downscale →
  │                                   │  WebP q90 → strip EXIF/GPS/ICC
  └─────┬─────────────────────────────┘
        │  → ActiveStorage::Blob (image/webp), attached as Picture#file
        ▼
  3. active_storage_validations run against the stored WebP
     (byte size, content type, pixel dimensions)
        ▼
  4. Picture.create_with_event  → persisted + RecordEvent + PgSearch index
```

The original upload is **never stored**. Coordinates and timestamps survive
only in the database columns; the file a visitor can download is stripped.

## Configuration (`AppConf`, overridable via ENV)

| Setting                  | ENV                      | Default (prod) | Default (test) |
|--------------------------|--------------------------|----------------|----------------|
| `picture_max_byte_size`  | `PICTURE_MAX_BYTE_SIZE`  | 6 MB           | 6 MB           |
| `picture_min_byte_size`  | `PICTURE_MIN_BYTE_SIZE`  | 150 KB         | 5 KB           |
| `picture_max_pixels`     | `PICTURE_MAX_PIXELS`     | 4000           | 4000           |
| `picture_min_pixels`     | `PICTURE_MIN_PIXELS`     | 400            | 120            |
| `picture_webp_quality`   | `PICTURE_WEBP_QUALITY`   | 90             | 90             |
| `picture_strip_metadata` | `PICTURE_STRIP_METADATA` | true           | true           |

`Picture::MAX_BYTE_SIZE`, `MIN_PIXEL_WIDTH`, … are derived from these at load
time. The test environment lowers the minimums so fixtures stay tiny.

## Step 1 — metadata extraction (`Images::MetadataExtractor`)

Returns an immutable `Images::Metadata` (`Data`). **Never raises** — an
unreadable file or a format without EXIF just yields `nil` fields, so upload
code can call it unconditionally.

| Field                               | Source     | Notes                                                          |
|-------------------------------------|------------|----------------------------------------------------------------|
| `width`, `height`                   | libvips    | **display** dimensions — EXIF Orientation applied              |
| `orientation`                       | derived    | `:landscape` / `:portrait` / `:square` / `nil`                 |
| `rotated`                           | libvips    | `true` when EXIF Orientation is 5–8 (stored pixels turned 90°) |
| `content_type`                      | Marcel     | sniffed from bytes, not the declared type                      |
| `byte_size`                         | filesystem | size of the file the user selected (pre-conversion)            |
| `taken_at`                          | exifr      | `DateTimeOriginal`, falls back to `DateTime`                   |
| `latitude`, `longitude`, `altitude` | exifr      | WGS84 / metres, from EXIF GPS IFD                              |
| `camera_make`, `camera_model`       | exifr      | e.g. `"Google"`, `"Pixel 4a"`                                  |

Helpers: `#landscape?/#portrait?/#square?`, `#gps?`, `#coordinates`,
`#camera`, `#to_location_attributes` (`{lat:, long:}`), `#to_picture_attributes`.

### EXIF support by format

| Format   | Geometry | Orientation tag | EXIF timestamp / GPS / camera                                    |
|----------|----------|-----------------|------------------------------------------------------------------|
| **JPEG** | ✅        | ✅               | ✅ (via `EXIFR::JPEG`)                                            |
| **TIFF** | ✅        | ✅               | ✅ (via `EXIFR::TIFF`)                                            |
| PNG      | ✅        | —               | ❌ — PNG has no standard EXIF GPS; fields stay `nil`              |
| WebP     | ✅        | ✅ (libvips)     | ❌ — not read; rare in practice, and uploads are converted anyway |
| GIF      | ✅        | —               | ❌                                                                |

Only JPEG and TIFF carry GPS in the wild, so EXIF is read for those two only.

### Timestamps & time zones

`exifr` returns a `Time`. If the photo has `OffsetTimeOriginal` (modern phones)
the zone is correct; otherwise the `Time` carries no real offset and
`taken_at` is stored as-if-UTC. `Picture#suggested_date` (and the `date`
fallback on upload) take `.to_date`, so a few hours' zone error rarely changes
the day. A traveller crossing a border mid-trip is **not** handled — the
photo's own offset is trusted as-is.

## Step 2 — conversion (`ImageUploadConversionService`)

`ImageProcessing::Vips` pipeline on the original tempfile:

1. **Minimum-size guard** — reads display dimensions first; raises
   `ImageUploadConversionService::ImageTooSmall` if either edge is below
   `Picture::MIN_PIXEL_*`. Controllers turn this into `422`.
2. **`resize_to_limit(MAX_PIXEL_WIDTH, MAX_PIXEL_HEIGHT)`** — libvips'
   `thumbnail` op: honours EXIF Orientation (bakes the rotation into the
   pixels, drops the tag), only ever downscales, keeps aspect ratio.
3. **`convert("webp")`** at `Picture.webp_quality` (90). WebP encode is lossy
   for every source format. PNG/GIF alpha is preserved; GIF animation is not.
4. **`saver(strip: true)`** when `picture_strip_metadata` — removes EXIF, GPS,
   XMP and ICC from the stored file.

Output: an `ActiveStorage::Blob`, `image/webp`, filename
`<name.parameterize>.webp`.

## Step 3 — validations (`Picture`, active_storage_validations)

Run against the **converted WebP**:

| Validation               | Rule                                                                 |
|--------------------------|----------------------------------------------------------------------|
| `attached`               | a file is present                                                    |
| `size`                   | `MIN_BYTE_SIZE..MAX_BYTE_SIZE` — message reports the **actual** size |
| `content_type`           | `image/{gif,jpeg,png,tiff,webp}` (post-conversion it is always webp) |
| `dimension`              | width & height each within `MIN_PIXEL..MAX_PIXEL`                    |
| `latitude` / `longitude` | numeric, within ±90 / ±180 when present                              |
| `exif_stripped`          | boolean, not null                                                    |

Messages come from `config/locales/active_storage_validations.en.yml`. That
file's `file_size_*` keys were realigned to the gem's current interpolation
vars (`%{min}`, `%{max}`, `%{file_size}`) — before, a hardcoded model message
always printed *"current size is 0 Bytes"*.

## `Picture` API for the new data

```ruby
picture.orientation      # :landscape | :portrait | :square | nil
picture.landscape?       # etc.
picture.aspect_ratio     # 1.4425 (width / height, 4 dp)
picture.dimensions       # [w, h] from columns, falling back to blob analysis

picture.geotagged?       # latitude & longitude present
picture.coordinates      # [lat, long] or nil
picture.altitude         # metres or nil
picture.camera           # "Google Pixel 4a" or nil
picture.taken_at         # Time or nil
picture.suggested_date   # taken_at.to_date or nil
picture.location_attributes_from_exif  # { lat:, long: } — seed a Location

picture.original_size    # "2.38 MB" — humanised pre-conversion size
picture.exif_stripped?   # is the stored file anonymous
```

On upload, `date` defaults to `taken_at.to_date` unless the form supplied one.
The picture **show** page renders capture time, an OpenStreetMap coordinate
link, altitude and camera when present.

### Map placement (next step, not yet built)

`location_attributes_from_exif` returns what a `Location` needs for
coordinates. A `Location` still requires a `name` and `country_code`, and the
app reverse-geocodes the rest (see `app/models/location.rb`). Wiring "create a
Location from this photo" / "photos near me" clustering is future work; the
data is now in place for it.

## Limitations

- **Original discarded.** No re-processing at a higher quality later; the 4000 px
  WebP is all there is. (A background job that keeps a 4k master and derives
  crops is sketched as an `# IDEA` in the controllers.)
- **No EXIF write-back.** We never re-embed coordinates; stored files stay
  anonymous by design.
- **Spoofed / missing GPS** is taken at face value — no plausibility check
  against other photos in the trip.
- **Animated GIFs** lose their animation (first frame only) on WebP conversion.
- **WebP/GIF EXIF** is not parsed (geometry only).
- **Time zones**: see "Timestamps & time zones" above.
- `db:doctor` runs in the *development* DB, so the `[latitude, longitude]`
  index and friends must exist there too (`bin/rails db:migrate`).

## Test fixtures

`spec/support/images/` — all derived from the one real smartphone photo
`spec/support/macbookair_stickered.jpg` (Google Pixel 4a JPEG, taken
2022-04-12 in Cologne, full GPS EXIF). Regenerate with libvips + ImageMagick:

```bash
S=spec/support/macbookair_stickered.jpg
vips rot   "$S" spec/support/images/portrait_gps.jpg d90          # genuine portrait, EXIF kept
vips crop  "$S" spec/support/images/square_gps.jpg 400 100 1000 1000
magick "$S" -set exif:Orientation 6 -orient RightTop spec/support/images/exif_orientation_6.jpg
vips jpegsave "$S" spec/support/images/no_exif.jpg --keep none    # "anonymous" upload
ruby -rvips -e 'i=Vips::Image.new_from_file(ENV["S"]); i.thumbnail_image(800).write_to_file("spec/support/images/plain.png", keep: :none); i.thumbnail_image(160).write_to_file("spec/support/images/tiny.jpg", Q: 80, keep: :none)'
```

`spec/support/image_fixtures.rb` (`ImageFixtures`) exposes paths, uploads and
the EXIF ground-truth constants.

## Specs

| File                                                    | Covers                                                                 |
|---------------------------------------------------------|------------------------------------------------------------------------|
| `spec/services/images/metadata_extractor_spec.rb`       | geometry, orientation, EXIF, GPS, per-format behaviour, bad input      |
| `spec/services/images/metadata_spec.rb`                 | the `Images::Metadata` value object                                    |
| `spec/services/image_upload_conversion_service_spec.rb` | WebP conversion, metadata strip, EXIF-rotation bake-in, min-size guard |
| `spec/models/picture_spec.rb`                           | `assign_uploaded_file`, orientation/GPS/size helpers, validations      |
| `spec/requests/current_teams/pictures_request_spec.rb`  | EXIF persisted on create, undersized → 422, show page renders metadata |

## Gems / system dependencies

- **libvips** (system) — `ImageProcessing::Vips`, `ruby-vips`. Already required.
- **exifr** (`~> 1.4`) — pure Ruby EXIF reader for JPEG/TIFF. Added for this.
- **ImageMagick** — only for regenerating the `exif_orientation_6` fixture.
