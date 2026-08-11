# Yournaling Roadmap

## Tooling

- [x] setup CI (GitHub Actions and rake task)
- [x] setup semantic CSS (picoCSS)
- [x] setup activejob backend ~~(Resque on Redis)~~ (GoodJob on Postgres)
- [x] setup error handling

## Users & Teams

- [x] setup users
- [x] setup teams
- [x] setup login / authentication
- [x] setup roles
- [ ] check roles / authorization

## Insights

### Pictures

- [x] resize Pictures before uploading
- [x] create Picture variants
- [ ] delete unused Pictures and variants
- [x] upload Pictures locally
- [ ] upload Pictures to S3

### Geo-Locations

- [ ] create Geo-Location via GPS coordinates
- [ ] create Geo-Location via Google Maps Link
- [ ] create Geo-Location via address
- [ ] geo-code given data to location
- [ ] reverse geo-code given data to location
- [ ] display Geo-Location on an embedded Google Map

### Thoughts

- [ ] use in Memories

### Website-Links

- [ ] create Links via URL and description
- [ ] cache social snippets' data
- [ ] style different snippet types

### Video-Links

> for paid users only

- [ ] must contain a name or description
- [ ] must contain a URL to a video (YouTube, Vimeo, DropBox, ...)
- [ ] cache social snippets' data
- [ ] display in a video frame with controls and link to the source

## Content Types

### Memories

- [x] setup memory creation by linking an insight with a note
- [ ] accept nested attributes to create insights on the fly

### Chronicles

- [ ] setup chronicle creation by linking multiple insights with a note and a headline

### Experiences

- [ ] setup experience creation wrapping multiple memories and chronicles
- [ ] enrich with experience content
- [ ] enrich with experience metadata

### Journeys

- [ ] setup experience creation wrapping multiple memories and chronicles and experiences
- [ ] enrich with journey content
- [ ] enrich with journey metadata
- [ ] setup overview page for all journeys of a team
- [ ] setup download of all content of a team (a massive JSON in a streamed ZIP with all images?)

## Special Content Types

> Only for paid users, specially suited for #VanLife blogs
> Treated like Chronicles
> Offering structured data fields for better documentation and display

### Stage of a trip

> Record every evening when parking

* km driven 
* Location
  * address
  * GPS coordinates
  * Altitude 
  * short description
* Orientation of parking
  * to detect a pattern on which side the sun usually is
* Date
* Temperature and Weather
* fotograph
  * location with van
  * location without van
  * view from location

### Refueling

> Document the fuel consumption

* Unit (e.g. liters of Diesel / gallons of gazoline / kWh)
* Amount
* Price per unit
* Price total
* km since last refuel 
* Consumption per 100km
* fotograph
  * invoice
  * fuel station
  * fuel station with van

### Stuff

> Document every (cool) item you own, ideally when buying it

* date
* price
* exact name
* short description
* shop bought from
* fotograph
  * invoice
  * item

## Metadata and Visibility Log

- [ ] add (the same?) metadata columns to all content type tables
- [ ] add a subset of the metadata columns to the insights tables
- [ ] write a log entry any time the visibility of content changes

## Includes and Including Log

- [ ] link insights and content to wrapping content in an includes table
- [ ] enrich with a description
- [ ] add a subset of the metadata columns to the includes tables
- [ ] write a log entry any time content or an insight is included in wrapping content

## Reports

- [ ] enable users to report content
- [ ] enable users to view their reports
- [ ] enable platform moderation to handle reports

## Platform Moderation

- [ ] setup roles
- [ ] setup workflow to handle reports
- [ ] setup content blocking
- [ ] setup content unblocking
- [ ] setup content soft-deletion
- [ ] setup team blocking
- [ ] setup team deletion

## Platform Insights

- [ ] new user accounts
- [ ] daily active users
- [ ] newly created or updated content
- [ ] page views (details in Cache, counter in Postgres?)
- [ ] reports of suspicious or offensive content

## Notification Emails

- [ ] new reports

## Hosting

- [ ] S3 alternative for backups and file uploads (not self-hosted!) (e.g. https://www.scaleway.com/en/pricing)
- [ ] Ionos vServer as cheapest option (6 CPU cores + 8 GB RAM + 160 GB Disk => 20€)
  - or Dedicated Server XL6 with 16GB RAM for 28€ https://www.ionos.de/server/value-dedicated-server
  - or some other VPS server
  - or https://www.scaleway.com/en/pricing/
- [ ] Setup Ubuntu Server https://github.com/jasonheecs/ubuntu-server-setup
- [ ] GitHub Actions as Deploy pipeline (and for Docker Images and as code repo)
- [ ] Dockerize everything? :-/
- [ ] Self-hosted Ruby app with all dependencies (2.5GB RAM)
- [ ] Self-hosted Postgresql (2GB RAM) - with rsync backups to S3
~~- [ ] Self-hosted Redis (0.5GB RAM) - (do queued jobs need backup?) - or use good_job and queue jobs with Postgres~~
- [ ] Self-hosted RabbitMQ (maybe 1.5GB RAM) - (do persisted jobs need backup?) - or don't for the start
- [ ] Self-hosted anycable-go (0.5GB RAM) https://github.com/anycable/anycable-rails to save RAM vs ActionCable default
- [ ] Self-hosted Sentry error tracking (1+GB RAM): https://develop.sentry.dev/self-hosted/
- [ ] Self-hosted Plausible analytics (1+GB RAM): https://plausible.io/docs/self-hosting
- [ ] reverse-proxy server / load balancer necessary?
- [ ] Let's Encrpyt SSL certificate
- [ ] external Log monitoring with e.g. Datadog or AppSignal or just logging to DB?!
