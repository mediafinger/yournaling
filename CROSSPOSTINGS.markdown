# Post your Yournaling content on social media

People want to share their stuff on social media, so we should make it easy - and good looking!

## Crosspostings

Instead of only posting on one platform, why not ~~spam~~ do crosspostings on other platforms as well:

* Bluesky
  * https://github.com/ShreyanJain9/bskyrb
* Mastodon
  * https://github.com/mastodon/mastodon-api
* X (fka Twitter)
  * https://github.com/sferik/x-ruby
* LinkedIn (unclear if any are maintained)
  * https://github.com/hexgnu/linkedin
  * https://github.com/decioferreira/omniauth-linkedin-oauth2
* Instagram
* Facebook
* WhatsApp
* Signal  

## Or re-posting

e.g. every Bluesky account provides an RSS feed. So enable to read from this RSS feed and post to the other platforms:

* Only original posts, no replies, no quotes, no retweets, if possible.
* Make this conditional by expecting some hashtag, e.g. `#repost`, `#+`, or `#x` at the end of the post.

---

## General Implementation Checklist

Steps required to prepare, format, and dispatch high-quality posts (text snippet + 1 picture + link to yournaling.com) across social platforms:

### 1. Rich Link Previews & OpenGraph Tags (Make links look great)
- [ ] **1.1. Dynamic Meta Tags**: Add OpenGraph & Twitter Card meta tags to public journal entry layouts:
  - `<meta property="og:title" content="...">`
  - `<meta property="og:description" content="...">`
  - `<meta property="og:image" content="...">` (optimized 1200×630 landscape image)
  - `<meta property="og:url" content="...">` (canonical entry URL)
  - `<meta name="twitter:card" content="summary_large_image">`
- [ ] **1.2. Fallback Social Card Generator**: Provide a default branded social share card if a journal entry has no photos attached.

### 2. Content & Text Snippet Generation
- [ ] **2.1. Markdown to Clean Plain Text**: Strip markdown headings, raw HTML, links, and code blocks to produce clean plain text for social feeds.
- [ ] **2.2. Smart Character Budget & Truncation**:
  - Truncate text cleanly at word boundaries to fit character limits (e.g. ~240–280 chars).
  - Automatically reserve character space for the link, hashtags, and `"… read more on yournaling.com"`.
- [ ] **2.3. Hashtags & Location Context**:
  - Automatically append relevant hashtags from entry tags and location/country names (e.g. `#Spain #TravelJournal`).

### 3. Media & Image Processing (1 Picture)
- [ ] **3.1. Primary Photo Selection**:
  - Select hero/featured photo from the entry (or allow user to pick 1 photo in the UI).
- [ ] **3.2. Image Optimization & Resizing Pipeline**:
  - Resize/crop photo to standard feed dimensions (1200×630 for landscape or 1080×1080 for square) using `ruby-vips` / ActiveStorage variants.
  - Compress image payload (JPEG/PNG) to stay within upload limits (e.g. < 5MB).
- [ ] **3.3. Accessible Alt Text**:
  - Carry over photo caption/description as image alt text for accessibility and platform compliance.

### 4. Canonical Links & Attribution
- [ ] **4.1. Permalink Generation**:
  - Generate full, clean canonical URLs pointing to the public entry.
- [ ] **4.2. Campaign / UTM Tracking Parameters**:
  - Append lightweight UTM tags (e.g. `?utm_source=crosspost&utm_medium=social`) to track incoming readers.

### 5. UI & Publishing Workflow
- [ ] **5.1. Crossposting UI / Modal**:
  - Add a "Share / Crosspost" action on entry release or edit.
  - Show a preview modal allowing the user to review the generated text snippet, swap the photo, check character count, and select target platforms.
- [ ] **5.2. Publication Status & History**:
  - Store crosspost records on the journal entry (timestamp, target network, status, and published post URL).

### 6. Background Processing & Reliability
- [ ] **6.1. Asynchronous Job Dispatch**:
  - Enqueue crosspost actions via ActiveJob / SolidQueue to keep user interactions snappy.
- [ ] **6.2. Retries & Rate Limit Backoff**:
  - Implement retry handling with exponential backoff for network timeouts or temporary platform rate limits.
- [ ] **6.3. Failure Alerts & Feedback**:
  - Notify the user if a crosspost fails with clear error messages.

---

## Platform-Specific Integration Details

```
 ┌─────────────────────────────────────────────────────────────┐
 │                    Yournaling Core                          │
 │  (Text Excerpt + 1 ActiveStorage Photo + Canonical URL)     │
 └──────────────┬──────────────┬──────────────┬────────────────┘
                │              │              │
                ▼              ▼              ▼
 ┌──────────────────────┐ ┌──────────┐ ┌───────────────────────┐
 │       Bluesky        │ │ Mastodon │ │     X (Twitter)       │
 │   (AT Protocol API)  │ │(REST v1) │ │   (Twitter API v2)    │
 └──────────────────────┘ └──────────┘ └───────────────────────┘
```

---

### 1. Bluesky Integration (AT Protocol)

Bluesky operates on the decentralized AT Protocol (`atproto`), posting records to the user's Personal Data Server (PDS).

* **Library**: [`bskyrb`](https://github.com/ShreyanJain9/bskyrb) or direct HTTP requests via `ChimeraHttpClient` to ATProto XRPC endpoints.
* **Authentication & Credentials**:
  - Requires **Handle** (e.g. `yourname.bsky.social`) and an **App Password** (generated under *Settings > App Passwords* in Bluesky).
  - Create authenticated session via `com.atproto.server.createSession` to obtain `accessJwt` and `did`.
* **Character Limit & Text Rules**:
  - Max **300 graphemes** (~300 characters).
  - **Rich Text Facets**: In AT Protocol, URLs, hashtags (`#travel`), and mentions are not plain text markdown—they require explicit `app.bsky.richtext.facet` byte index ranges (`byteStart`, `byteEnd`) so they become clickable.
* **Image Upload Workflow**:
  1. Upload the optimized photo binary to `com.atproto.repo.uploadBlob` with `Content-Type: image/jpeg` (max 1 MB / recommended < 1000 KB).
  2. Receive the blob reference object (`{ "$type": "blob", "ref": { "$link": "cid..." }, "mimeType": "image/jpeg", "size": ... }`).
* **Publishing the Post**:
  - Call `com.atproto.repo.createRecord` for collection `app.bsky.feed.post` with:
    ```json
    {
      "collection": "app.bsky.feed.post",
      "repo": "did:plc:...",
      "record": {
        "$type": "app.bsky.feed.post",
        "text": "Exploring Seville's hidden alleys today! 🇪🇸… read more on yournaling.com/p/123 #travel #spain",
        "facets": [...],
        "embed": {
          "$type": "app.bsky.embed.images",
          "images": [
            {
              "image": blob_ref,
              "alt": "Cobblestone street in Seville with orange trees"
            }
          ]
        },
        "createdAt": "2026-08-07T16:00:00.000Z"
      }
    }
    ```
* **Key Gotchas**:
  - Byte slicing: Facet offsets use UTF-8 byte positions rather than character positions to ensure accurate emoji indexing.

---

### 2. Mastodon Integration (ActivityPub / REST API)

Mastodon uses standard REST endpoints supported by every Fediverse instance.

* **Library**: [`mastodon-api`](https://github.com/mastodon/mastodon-api) or direct REST calls.
* **Authentication & Credentials**:
  - **Instance URL** (e.g. `https://mastodon.social` or user's custom instance).
  - **OAuth Access Token** (Bearer token with scopes `write:statuses` and `write:media`).
* **Character Limit & Text Rules**:
  - Standard default is **500 characters** (configurable up to 1,000+ on some instances).
  - URLs always count as **23 characters** regardless of length.
  - Plain hashtags (`#travel`) and links are automatically parsed by the server without manual facet calculation.
* **Image Upload Workflow**:
  1. Send a multipart `POST /api/v2/media` (or `/api/v1/media`) with the image file and `description` (alt text).
  2. Obtain the returned `id` (e.g. `"1129384756"`).
  3. If video or large image, poll until processing completes; for standard JPEG photos, it is ready immediately.
* **Publishing the Post**:
  - Send `POST /api/v1/statuses` with `Authorization: Bearer <TOKEN>`:
    ```ruby
    params = {
      status: "Exploring Seville's hidden alleys today! 🇪🇸 https://yournaling.com/entries/123 #travel #spain",
      media_ids: [media_id],
      visibility: "public" # public, unlisted, private
    }
    ```
* **Key Gotchas**:
  - Instance rate limits: Most instances limit write actions to 300 requests per 5 minutes per user.
  - Multi-instance support: Store both the user's `mastodon_server_url` and `access_token` since each user may be on a different server.

---

### 3. X / Twitter Integration (API v2)

X uses the Twitter API v2 with media endpoints.

* **Library**: [`x-ruby`](https://github.com/sferik/x-ruby) (maintained modern gem for API v2).
* **Authentication & Credentials**:
  - **OAuth 2.0 User Context** (Authorization Code with PKCE, scopes `tweet.read`, `tweet.write`, `users.read`) OR **OAuth 1.0a User Tokens** (`api_key`, `api_secret`, `access_token`, `access_token_secret`).
* **Character Limit & Text Rules**:
  - Max **280 characters** for standard accounts.
  - Any URL counts as **23 characters** (via Twitter's `t.co` shortener).
  - Emojis count as 2 characters.
* **Image Upload Workflow**:
  1. Media upload currently runs through the upload endpoint `POST https://upload.twitter.com/1.1/media/upload.json` with multipart form data.
  2. Set accessible alt-text metadata via `POST https://upload.twitter.com/1.1/media/metadata/create.json` with `{ media_id: "...", alt_text: { text: "..." } }`.
* **Publishing the Post**:
  - Send `POST https://api.twitter.com/2/tweets` with JSON payload:
    ```json
    {
      "text": "Exploring Seville's hidden alleys today! 🇪🇸 https://yournaling.com/entries/123 #travel #spain",
      "media": {
        "media_ids": ["182193847562819"]
      }
    }
    ```
* **Key Gotchas & Free Tier Limits**:
  - **Free Tier Cap**: X allows up to **1,500 Tweets per month (app-level)** and 1 post every 15 minutes per user for free.
  - Media upload size: Max 5 MB for JPEG/PNG images on mobile/web feeds.

---

### 4. Instagram Integration (Content Publishing API)

Instagram publishing runs through Meta's Graph API for Instagram Professional (Business or Creator) accounts.

* **Library**: Direct HTTP requests via `ChimeraHttpClient` or `koala` gem.
* **Authentication & Credentials**:
  - **Facebook Login OAuth 2.0** with scopes: `instagram_basic`, `instagram_content_publish`, `pages_show_list`, `pages_read_engagement`.
  - User's account must be an **Instagram Business or Creator Account** linked to a Facebook Page.
* **Character Limit & Text Rules**:
  - Caption max **2,200 characters** and up to **30 hashtags**.
  - **No Clickable Links**: URLs in post captions are displayed as plain text (not hyperlinked). Your post text should mention *"Link in bio"* or rely on Instagram Story links.
* **Image Upload Workflow (Container-Based)**:
  1. Image must be hosted at a publicly accessible HTTPS URL (e.g. your ActiveStorage S3 / CDN URL).
  2. Create a media container:
     ```http
     POST https://graph.facebook.com/v20.0/{ig_user_id}/media
       ?image_url=https://yournaling.com/rails/active_storage/blobs/.../photo.jpg
       &caption=Exploring Seville's hidden alleys today! 🇪🇸 #travel #spain
       &access_token={PAGE_ACCESS_TOKEN}
     ```
     Returns `{ "id": "1792837465019" }` (Container ID).
  3. Publish the media container:
     ```http
     POST https://graph.facebook.com/v20.0/{ig_user_id}/media_publish
       ?creation_id=1792837465019
       &access_token={PAGE_ACCESS_TOKEN}
     ```
* **Key Gotchas & Limits**:
  - Aspect ratio requirement: Image aspect ratio must be between **4:5 (portrait)** and **1.91:1 (landscape)**.
  - Publishing limit: Max **25 API-published posts per 24 hours** per account.

---

### 5. Facebook Integration (Graph API)

Facebook publishing allows posting photos and updates to user-managed Facebook Pages or Groups.

* **Library**: `ChimeraHttpClient` or `koala` gem.
* **Authentication & Credentials**:
  - **OAuth 2.0 Page Access Token** with permissions: `pages_manage_posts`, `pages_read_engagement`.
  - Note: Meta deprecated publishing directly to personal Facebook User profiles via API; automated crossposting targets **Facebook Pages**.
* **Character Limit & Text Rules**:
  - Post text up to **63,206 characters**.
  - Hyperlinks in the caption automatically generate rich OpenGraph previews.
* **Image Upload Workflow**:
  - Publish directly with a multipart photo upload:
    ```http
    POST https://graph.facebook.com/v20.0/{page_id}/photos
      Content-Type: multipart/form-data
      
      source: [binary JPEG image data]
      message: "Exploring Seville's hidden alleys today! 🇪🇸 Read more: https://yournaling.com/entries/123 #travel"
      published: true
      access_token: {PAGE_ACCESS_TOKEN}
    ```
* **Key Gotchas**:
  - Page Access Tokens must be periodically refreshed or exchanged for Long-Lived Tokens (valid for 60 days).

---

### 6. WhatsApp Integration

WhatsApp sharing can be implemented either via instant zero-cost **Deep Links** (for one-click user sharing) or through the **WhatsApp Cloud API** (for automated messaging).

* **Approach A: Direct Share Deep Link (100% Free, Zero API Setup) [Recommended]**:
  - Render a *"Share on WhatsApp"* button on the entry:
    ```ruby
    text = "Exploring Seville's hidden alleys today! 🇪🇸 https://yournaling.com/entries/123"
    whatsapp_url = "https://api.whatsapp.com/send?text=#{ERB::Util.url_encode(text)}"
    ```
  - **How it works**: Clicking the link opens WhatsApp Web or mobile app with the pre-filled message. WhatsApp's scraper automatically unfurls the `og:image` and title from Yournaling into a rich card.
* **Approach B: WhatsApp Cloud API (Automated Channel Broadcast)**:
  - Requires **Meta Business Account** and a registered phone number ID.
  - Send media messages via `POST https://graph.facebook.com/v20.0/{phone_number_id}/messages`:
    ```json
    {
      "messaging_product": "whatsapp",
      "recipient_type": "individual",
      "to": "+1234567890",
      "type": "image",
      "image": {
        "link": "https://yournaling.com/rails/active_storage/blobs/.../photo.jpg",
        "caption": "Exploring Seville's hidden alleys today! 🇪🇸 https://yournaling.com/entries/123"
      }
    }
    ```
* **Key Gotchas**:
  - Cloud API conversations outside the 24-hour service window require pre-approved message templates and incur per-conversation Meta fees.

---

### 7. Signal Integration

Signal is focused on end-to-end encrypted private messaging and does not offer an official public cloud SaaS REST API for unverified bots.

* **Approach A: Native Share Intent / Deep Link (100% Free & Zero Server Setup) [Recommended]**:
  - Use the native `sgnl://` URL scheme or Web Share API:
    ```ruby
    text = "Exploring Seville's hidden alleys today! 🇪🇸 https://yournaling.com/entries/123"
    signal_url = "sgnl://send?text=#{ERB::Util.url_encode(text)}"
    ```
  - Or trigger browser Web Share:
    ```javascript
    navigator.share({
      title: "Exploring Seville",
      text: "Exploring Seville's hidden alleys today! 🇪🇸",
      url: "https://yournaling.com/entries/123"
    });
    ```
  - Signal's client fetches the OpenGraph image and displays a secure link preview card in chat.
* **Approach B: Self-Hosted `signal-cli` Gateway (For Automated Bot Dispatch)**:
  - Run a self-hosted daemon such as [`signal-cli-rest-api`](https://github.com/bbernhard/signal-cli-rest-api) in Docker linked to a registered phone number.
  - Dispatch via local HTTP:
    ```http
    POST http://localhost:8080/v2/send
    Content-Type: application/json

    {
      "message": "Exploring Seville's hidden alleys today! 🇪🇸 https://yournaling.com/entries/123",
      "number": "+1234567890",
      "recipients": ["+0987654321"],
      "base64_attachments": ["data:image/jpeg;base64,..."]
    }
    ```
* **Key Gotchas**:
  - Automated bot delivery requires maintaining a persistent daemon and registered phone number; deep-linking / Web Share is the standard lightweight approach.

---

## Comparison Summary

| Platform | Protocol / API | Character Limit | Image Support | Clickable Links in Feed? | API Cost / Quota |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Bluesky** | AT Protocol (XRPC) | **300 graphemes** | Upload Blob (JPEG/PNG < 1MB) | **Yes** (via Facets) | **100% Free** (Unlimited) |
| **Mastodon** | ActivityPub / REST | **500 chars** | Multipart media (`/api/v2/media`) | **Yes** (Auto-parsed) | **100% Free** (Decentralized) |
| **X (Twitter)** | Twitter API v2 | **280 chars** (URLs=23) | Upload endpoint (`/1.1/media/upload`) | **Yes** (t.co shortener) | Free tier: 1,500 posts/mo |
| **Instagram** | Graph API (Business/Creator)| **2,200 chars** | Media Container (Public URL) | **No** (Plain text only) | 25 API posts/day per user |
| **Facebook** | Graph API (Pages/Groups) | **63,206 chars** | Multipart photo upload | **Yes** (Full link previews) | Free for standard Page posting |
| **WhatsApp** | Deep Link / Cloud API | **4,096 chars** | OG Link Card / Media Object | **Yes** (Interactive link preview) | Deep link: **$0**; API: Per conversation |
| **Signal** | Share Intent / `signal-cli` | Uncapped | OG Link Card / Base64 attachment | **Yes** (Secure link preview) | Deep link: **$0**; Daemon: Self-hosted |
