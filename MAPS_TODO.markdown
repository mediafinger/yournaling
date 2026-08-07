# Maps Implementation Plan (MAPS_TODO)

Based on Fabian's guide for self-hosting vector maps and third-party map providers (Geoapify & Google Maps), here is the breakdown of implementation options, costs, limitations, and architectural steps.

---

## Architecture Overview

```
 ┌─────────────────────────────────────────────────────────────┐
 │                         Frontend                            │
 │  MapLibre GL JS + Stimulus Controller (map_controller.js)   │
 └──────────────┬───────────────────────────────┬──────────────┘
                │ (Vector Tile Requests)        │ (GeoJSON Overlay Data)
                ▼                               ▼
 ┌──────────────────────────────┐ ┌─────────────────────────────┐
 │         Tile Source          │ │   Locations / Journeys      │
 │  • Local: Rails /tiles       │ │     (Lat / Lng models)      │
 │  • Cloud: Geoapify Vector API│ └─────────────┬───────────────┘
 └──────────────┬───────────────┘               │ (ActiveRecord JSON)
                ▼                               ▼
 ┌──────────────────────────────┐ ┌─────────────────────────────┐
 │    Local Storage on Disk     │ │       PostgreSQL DB         │
 │ (storage/maps/*.pmtiles)     │ │  (locations, memories, etc) │
 └──────────────────────────────┘ └─────────────────────────────┘
```

---

## Option 1: Self-Hosted Vector Maps (Protomaps + MapLibre GL) [Recommended]

### Phase 1: Frontend Map Engine (MapLibre GL + PMTiles)
- [ ] **1.1. Pin MapLibre GL & PMTiles via Importmaps**
  - Add to `config/importmap.rb`:
    ```ruby
    pin "maplibre-gl", to: "https://ga.jspm.io/npm:maplibre-gl@4.7.1/dist/maplibre-gl.js"
    pin "pmtiles", to: "https://ga.jspm.io/npm:pmtiles@3.0.7/dist/index.js"
    ```
  - Include MapLibre GL CSS in `app/assets/stylesheets/application.scss` or layout:
    ```html
    <link href="https://unpkg.com/maplibre-gl@4.7.1/dist/maplibre-gl.css" rel="stylesheet" />
    ```

- [ ] **1.2. Implement Stimulus `map_controller.js`**
  - Register PMTiles protocol (`pmtiles.Protocol.add()`).
  - Initialize `maplibregl.Map(...)` pointing to the local `/tiles` endpoint.
  - Add navigation controls (zoom, compass, fullscreen).
  - Parse GeoJSON data attributes to render markers and connecting route lines.

- [ ] **1.3. Base Map Style**
  - Use ready-to-use Protomaps vector style (e.g. Protomaps Light / OpenStreetMap base style).

### Phase 2: Self-Hosting Vector Tiles in Rails
- [ ] **2.1. Prepare Local `.pmtiles` Storage**
  - Store `.pmtiles` archive in `storage/maps/`.
  - Add `storage/maps/*.pmtiles` to `.gitignore`.

- [ ] **2.2. Implement `TilesController` with HTTP Range Request Support**
  - Stream byte ranges with `ActionController::Live` (`206 Partial Content`):
    ```ruby
    class TilesController < ApplicationController
      include ActionController::Live

      MAX_RANGE_SIZE = 10.megabytes

      def show
        file_path = Rails.root.join("storage/maps", "#{params[:file]}.pmtiles")

        unless File.exist?(file_path)
          render plain: "Tile archive not found", status: :not_found
          return
        end

        file_size = File.size(file_path)
        range_header = request.headers["Range"]

        unless range_header
          render plain: "Range header is required", status: :bad_request
          return
        end

        match = range_header.match(/bytes=(\d+)-(\d*)/)
        if match
          start = match[1].to_i
          finish = match[2].present? ? [match[2].to_i, start + MAX_RANGE_SIZE - 1].min : (start + MAX_RANGE_SIZE - 1)
          length = finish - start + 1

          response.header["Content-Range"] = "bytes #{start}-#{finish}/#{file_size}"
          response.header["Content-Length"] = length.to_s
          response.header["Accept-Ranges"] = "bytes"
          response.header["Content-Type"] = "application/vnd.pmtiles"
          response.status = :partial_content

          send_data IO.binread(file_path, length, start), type: "application/vnd.pmtiles", disposition: "inline"
        else
          render plain: "Invalid range request", status: :range_not_satisfiable
        end
      end
    end
    ```
- [ ] **2.3. Add Route in `config/routes.rb`**
  ```ruby
  get "tiles/:file", to: "tiles#show", format: false
  ```

---

## Option 2: Geoapify Hosted Maps API (https://www.geoapify.com/)

Your application already integrates `AppConf.geoapify_api_key` in `config/initializers/geocoder.rb`. Geoapify can also serve as a fully managed map tile and static map provider without hosting `.pmtiles` files locally.

### Pricing, Free Tier & Limits
- **Free Tier Allowance**: **3,000 credits/requests per DAY** (~**90,000 requests per month for $0**).
- **Credit Card Required**: **No** (free tier never automatically charges or overdrafts).
- **Rate Limit**: **5 requests per second (5 QPS)** on the free tier.
- **Credit Consumption**:
  - `1 Static Map image` = 1 credit.
  - `1 Geocoding lookup` = 1 credit.
  - `1 Routing / Turn-by-Turn request` = 1–2 credits.
  - `1 Vector Map load` = ~1–5 credits (browser caching reduces repeated tile downloads).
- **Paid Tier**: If exceeding 3,000 credits/day, paid plans start around €49/month.

### Features & Implementation
1. **Dynamic Vector Maps (via MapLibre GL)**:
   - Point MapLibre directly to Geoapify's hosted vector styles (`osm-bright`, `osm-liberty`, `positron`, `dark-matter`):
     ```javascript
     const map = new maplibregl.Map({
       container: 'map',
       style: `https://maps.geoapify.com/v1/styles/osm-bright/style.json?apiKey=${geoapifyApiKey}`,
       center: [longitude, latitude],
       zoom: 12
     });
     ```
2. **Static Maps API (Image Previews with Custom Markers & Routes)**:
   - Request pre-rendered PNG/JPEG images with multiple custom colored pins and route polylines:
     ```ruby
     def geoapify_static_map_url(lat:, lng:, width: 600, height: 350, zoom: 13)
       "https://maps.geoapify.com/v1/staticmap?style=osm-bright&width=#{width}&height=#{height}&center=lonlat:#{lng},#{lat}&zoom=#{zoom}&marker=lonlat:#{lng},#{lat};color:%23e63946;size:medium&apiKey=#{AppConf.geoapify_api_key}"
     end
     ```
3. **Limitations**:
   - **Daily Reset**: 3,000 request limit resets daily at midnight UTC (requests cannot be pooled across days).
   - **Attribution**: Must display `Powered by Geoapify | © OpenStreetMap contributors`.

---

## Option 3: Google Maps Options & Free Tier Analysis

### 1. Direct Link to Google Maps (100% Free & No API Key Needed)
- **Cost**: **$0.00**, completely free, no API key, no quotas or limits.
- **Behavior**: Opens Google Maps in a new tab or native mobile app.
- **URL Format**:
  ```ruby
  # Single Location Search Pin:
  "https://www.google.com/maps/search/?api=1&query=#{latitude},#{longitude}"

  # Multi-Stop Directions Route:
  "https://www.google.com/maps/dir/?api=1&origin=#{origin}&destination=#{destination}&waypoints=#{waypoints.join('|')}"
  ```
- **Recommended use**: A *"Navigate with Google Maps"* button on location and journey show pages.

### 2. Google Maps Embed API (100% Free & Unlimited)
- **Cost**: **$0.00**, **Unlimited free usage** (Google explicitly does not charge for embed mode, though an API key is required).
- **Implementation**:
  ```html
  <iframe
    width="100%"
    height="400"
    style="border:0"
    loading="lazy"
    allowfullscreen
    src="https://www.google.com/maps/embed/v1/place?key=<%= ENV['GOOGLE_MAPS_API_KEY'] %>&q=<%= location.latitude %>,<%= location.longitude %>">
  </iframe>
  ```
- **Limitations**:
  - Only supports **single location pins** or standard directions between points.
  - **No multi-marker custom layers**: You cannot render 15 custom journal stops or custom photo pins on a single free embed iframe.

### 3. Google Static Maps API (Static Image with Multiple Markers)
- **Cost & Free Tier**:
  - Google Cloud provides a **$200 monthly recurring credit** across all Maps products.
  - Static Maps cost **$2.00 per 1,000 requests** ($0.002/image).
  - **Free Tier Capacity**: Up to **100,000 static map images per month** within the $200 credit.
- **Marker & Route Limitations**:
  - **URL Length Cap**: The entire image URL is strictly limited to **8,192 characters** (roughly **20–50 markers** per image).
  - **Resolution Limit**: Max resolution is 640×640 px (or 1280×1280 px with `scale=2`).
  - **Interactivity**: Returns a flat PNG/JPEG image (non-interactive).

### 4. Google Maps JavaScript API (Full Dynamic Map)
- **Cost & Free Tier**:
  - Dynamic maps cost **$7.00 per 1,000 map loads**.
  - **Free Tier Capacity**: Up to **~28,500 dynamic map loads per month** within the $200 monthly credit.
  - **Rate limits**: 30,000 requests per minute by default.
- **Risk / Limitations**:
  - Requires a Google Cloud billing account with a credit card attached.
  - Risk of surprise billing if traffic spikes beyond 28,500 monthly loads unless hard budget quotas are set in Google Cloud Console.

---

## Comparison Matrix

| Feature | Self-Hosted Protomaps / MapLibre | Geoapify Hosted API | Google Direct Link | Google Embed API | Google Static Maps API | Google Dynamic JS API |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Monthly Cost** | **$0 (Zero API fees)** | **$0 (up to 3k/day)** | **$0 (Zero fees)** | **$0 (Unlimited Free)** | **Free up to 100k req/mo** | **Free up to 28.5k loads/mo** |
| **Credit Card Required** | No | **No** | No | Yes (Google Cloud) | Yes (Google Cloud) | Yes (Google Cloud) |
| **Daily / Monthly Limit** | **Unlimited** | 3,000 req/day (5 QPS) | **Unlimited** | **Unlimited** | 100k/mo ($200 credit) | 28.5k/mo ($200 credit) |
| **Multi-Marker Support** | **Unlimited** | **Unlimited** | Single search | No (1 place pin) | 20–50 (URL limit) | **Unlimited** |
| **Interactivity** | Full (pan, zoom, popups) | Full (pan, zoom, popups) | External App | Interactive iframe | None (flat PNG/JPG) | Full (pan, zoom, popups) |
| **Route Polylines** | Yes (GeoJSON) | Yes (GeoJSON / Static) | Yes (Directions) | Yes (Directions) | Yes (encoded polyline) | Yes |
| **Server Storage Needed** | Yes (`.pmtiles` file) | **No** | **No** | **No** | **No** | **No** |

---

## Phase 3: Location Data & GeoJSON Serialization

- [ ] **3.1. Verify Latitude & Longitude on Location Models**
  - Ensure `locations` table has `latitude: :decimal` and `longitude: :decimal` columns with appropriate precision/scale (`precision: 10, scale: 6`).
  - Add index on `[:latitude, :longitude]` for fast retrieval.

- [ ] **3.2. GeoJSON Feature Collection Builder**
  - Add helper or method on `Location` / `Journey` / `Memory` to serialize records into standard GeoJSON:
    ```ruby
    def to_geojson_feature
      {
        type: "Feature",
        geometry: {
          type: "Point",
          coordinates: [longitude.to_f, latitude.to_f]
        },
        properties: {
          id: id,
          title: name,
          url: Rails.application.routes.url_helpers.location_path(self)
        }
      }
    end
    ```

---

## Phase 4: Travel Journal Map UI & Features

- [ ] **4.1. Map View Component or Partial**
  - Build reusable `MapComponent` (or partial `_map.html.slim`) rendering the map container with Stimulus data attributes:
    ```slim
    div data-controller="map" data-map-geojson-value=geojson_data.to_json class="map-container"
    ```

- [ ] **4.2. Location Markers & Interactive Popups**
  - Clickable markers on the map showing location title, photo thumbnail, and link to journal entry.

- [ ] **4.3. Route / Journey Polyline Rendering**
  - Draw connected lines across sequential journal stops for journeys/trips.

---

## Phase 5: Verification & Tests

- [ ] **5.1. Controller & Request Specs**
  - Write request specs for `TilesController`:
    - Tests 206 Partial Content response with valid `Range` headers.
    - Tests 400 Bad Request when `Range` header is missing.
    - Tests 404 when archive does not exist.
- [ ] **5.2. System / View Specs**
  - Verify map container renders with proper data attributes on location and journey pages.
