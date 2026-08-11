# README

> **_Journal your journey_**  
> _... on [yournaling.com](https://yournaling.com)_

The Yournaling app will become a place where single people, couples or teams can:

* journal (daily) experiences
* maintain a blog with separated streams for multiple topics
* present pictures, with descriptions, dates and locations
* show locations on maps
* keep a travel journal, displaying the route taken on a map
* ...



---

> **The points below explain technical concepts of the yournaling app.**

## Dependencies

* Ruby - for exact version see: https://raw.githubusercontent.com/mediafinger/yournaling/main/.ruby-version
* Postgres v15+
* libvips library for image manipulation
* many Ruby gems: https://raw.githubusercontent.com/mediafinger/yournaling/main/Gemfile.lock

## Installation

When you have the dependencies installed:

* clone the repo to your machine: `git clone git@github.com:mediafinger/yournaling.git`
* in the new directory, using the correct ruby version: `bundle install`
* create the database: `bin/rails db:create && db:migrate && db:seed`
* run the test suite (same is run on CI): `bundle exec rake ci`
* open a console: `bin/rails c`
* start the server: `bin/rails s`

## Deployment

Did not happen yet. Will most likely be setup with Kamal to a VM or dedicated server.

## Contribution

Is welcome. Please get in touch with @mediafinger before opening a PR that would add or change larger parts. This should also be done when picking an open issue, to discuss possible solutions.

## YID - Yournaling ID

YID are **sortable** **unique** IDs which contain:

* the object klass (short unique label)
* the created_at timestamp at UTC in ISO8601 form with microsecond precision
* a short UUID in hex format

YID are:

* stored in the database field `id` as primary key
* used in serializers to the frontend
* used in associations to other objects (with DB foreign_key)
* used as foreign_keys in Rails associations
* ideally be created on Postgres level (currently not done)
* for now created by in a Rails hook before persisting a new object
* stable, they never change

YID are constructed like this:

* `photo_2023-02-26T09:20:20.075800Z_6511ee876a86`
* `object.klass::YID_CODE_object.created_at.utc.iso8601(6)_SecureRandom.hex(6)`
* _Be aware that the "random" UUID part (everything after the 2nd `_`) is rather short and like this not good enough to be used as standalone UUID._

> YID creation is slow compared to integer IDs or UUIDs, they are long and comparing them is more costly than comparing UUIDs. Their benefits are that they directly reveal the type of object (which is a massive bonus when debugging or sharing object identifiers) and that they are sortable at every moment, without additional database queries (which can speed up the app a lot).

Any YID can be fed to a search, which will determine the object type before returning the correct object. This is mostly useful for debugging and therefore might only be implemented as an internal endpoint or disolver service which will return the actual object (or a 403 or 404 error).

Instead of using the YIDs in URLs directly, we convert them to their Base64 representation to be URL-safe. The controllers use a custom finder method to decode them back to the plain text YID format automatically. Probably other symmetric encoding / decoding encryption algorithms are faster than Base64 and we update the implementation.

---

## Analytics & SQL Dashboard (Blazer)

Yournaling uses **Blazer** alongside **Ahoy** to provide self-hosted product analytics and database insights without third-party tracking.

### Accessing Blazer

1. **Sign In**: Log in with an account having the `admin` role (in development: `andy@example.com` / `foobar1234`).
2. **Open Dashboard**:
   * Click **Analytics** in the top navigation of the Admin Area (`/admin`), or
   * Navigate directly to [`/admin/blazer`](http://localhost:3000/admin/blazer).

> **Access Control**: Blazer is mounted under the `/admin` namespace. Requests from unauthenticated guests or non-admin users return `404 Not Found`.

### Common Queries

* **Recent Visits (`ahoy_visits`)**:
  ```sql
  SELECT started_at, user_id, browser, os, device_type, landing_page
  FROM ahoy_visits
  ORDER BY started_at DESC
  LIMIT 50;
  ```
* **Event Stream (`record_events`)**:
  ```sql
  SELECT created_at, name, record_type, record_id, user_id, properties
  FROM record_events
  ORDER BY created_at DESC
  LIMIT 50;
  ```

### TODO (Production Hardening)

* **Create a Read-Only Database Role**
  * When deploying to production with Kamal, configure a read-only PostgreSQL user for Blazer in config/blazer.yml to prevent accidental UPDATE/DELETE queries from the UI.
* **Scheduled SQL Checks & Slack Alerts**
  * Blazer can automatically run background checks (e.g. alerts when error rates spike or daily signups drop) using rake blazer:run_checks.