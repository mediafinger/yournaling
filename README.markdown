# Yournaling - Your Journey Journal 📔

> **_Capture and Share Your Adventures_**  
> Explore the world on [yournaling.com](https://yournaling.com) 🌟

Yournaling is your all-in-one platform to:

* 📝 Journal daily experiences
* 🗺️ Map locations with photos, coordinates, and dates
* 🚗 Track your routes and stops
* 📷 Upload and link photos to your journal
* 🌐 Combine experiences into journeys and create full journals
* ✍️ Use an easyMDE editor for markdown text
* 📜 Render markdown as HTML (GitHub-style)
* 📤 Quickly upload shared links, Google Maps locations, and notes
* 🏷️ Organize with tags
* 🎬 Preview media snippets
* 👥 Manage content with user roles (admin, editor, support, reader)
* 🤝 Collaborate with teams
* 👤 Create user and van profiles
* 🔐 Allow OAuth sign-up/sign-in for comments
* 🚨 Report comments or users
* 🌍 Use geocoder gem with Geoapify or Mapbox-permanent API
* 🗺️ Embed Google Maps
* 💾 Enable full backups

**Yournaling Features:**

- 🍽️ Foodie Journal: Document every course of your meals
- 🚐 Vanlifer Journal: Capture locations and moments
- 🛠️ Hobbyist Journal: Record your crafting journey
- 🧠 Mental Health Journal: A classic for self-reflection

## Technical Concepts 🧩

### Dependencies 🧰

* Ruby - [Version Link](https://raw.githubusercontent.com/mediafinger/yournaling/main/.ruby-version) 🐦
* Postgres v15 🐘
* Redis 🚀
* Image manipulation with libvips 🖼️
* Many Ruby gems - [Gemfile.lock](https://raw.githubusercontent.com/mediafinger/yournaling/main/Gemfile.lock) 💎

### Installation 🚀

* Clone the repo: `git clone git@github.com:mediafinger/yournaling.git` 🧑‍💻
* Install dependencies: `bundle install` 🚀
* Create and seed the database: `bin/rails db:create && db:migrate && db:seed` 🏗️
* Run the test suite (also on CI): `bundle exec rake ci` 🧪
* Open a console: `bin/rails c` 💬
* Start the server: `bin/rails s` 🚀

### Deployment 🚢

Deployment plans are pending. Likely to be set up with Kamal on a VM or dedicated server. 🛠️

### Contribution 👥

Contributions are welcome! Please contact @mediafinger before opening significant PRs or addressing open issues. 🤝

### YID - Yournaling ID 🆔

YIDs are unique and sortable IDs that contain object information:

* Object klass (short unique label) 🏷️
* Created_at timestamp in ISO8601 with microsecond precision ⏰
* Short UUID in hex format 🔢

YIDs are used extensively:

* As primary keys in the database 🔑
* In serializers to the frontend 📤
* In associations to other objects ↔️
* As foreign keys in Rails associations ↔️
* Ideally created on the Postgres level (currently not implemented) 🗃️
* For now, created by a Rails hook before object persistence 🔄
* Stable and never change 🧱

YIDs look like this:

* `photo_2023-02-26T09:20:20.075800Z_6511ee876a86` 📸
* `object.klass::YID_CODE_object.created_at.utc.iso8601(6)_SecureRandom.hex(6)` 🌐

YIDs are advantageous for debugging and direct object identification. They can be fed into a search, determining the object type before returning the correct object. 🚀

Instead of using YIDs in URLs, they are converted to Base64 for URL safety. The controllers decode them automatically. 🔐
