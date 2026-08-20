# UI

Yournaling is currently undesigned and under-styled. It is time to come up with a concept and a design philosophy. The following are my initial ideas.

## Design Philosophy

Yournaling uses Pico CSS for semantic styling. It aims for a clean, modern, and minimalist aesthetic that focuses on content and user experience. The design emphasizes readability, ease of navigation, and a visually pleasing interface that enhances the travel journaling experience.

Using Pico means doing the opposite of TailwindCSS. We don't use lots of utility classes. Instead we use semantic HTML and rely on Pico CSS to style the elements.

Obviously we can also create customized classes. But then we create the classes in the our style sheets and we don't use inline styling. We also try to keep the numbers of classes low (at least for now).

* https://picocss.com/
* https://picocss.com/docs

## Colors

The three sections or areas or modes are:

* **browse mode** - view any published content
  * uses the pico.amber.css
* **manage mode** - create content and manage the content of your current team
  * uses the pico.green.css
* **admin mode** - only for super-admins
  * uses the pico.blue.css

## Layout

* One top nav bar 
* One large content area
* everything should be responsive and look good on mobile devices as well
* while on mobile a single-column layout will make most sense, on wider screens two or three columns could be placed side-by-side

## Nav Bar

* currently the buttons and links are rather unsorted and placed rather wildly
* every mode has their own nav bar
  * the admin area is currently missing the logout button (which should be at the same place as in the other modes)
  * the buttons should be sorted in a somewhat logical way
  * the ordering of the buttons should be consistent in all modes (at least in browse and manage mode)
  * the admin area is special and can follow its own rules
* it should be optically separated from the content area
* it should be sticky
* the browse mode is missing a "home" link to show the timeline again

### Nav Bar Button Ordering & Grouping by Mode

Each navigation bar is divided into three semantic zones (**Left**: Brand/Home, **Center**: Core Domain Links & Search, **Right**: Mode Switching, Team Switcher & Session):

#### 1. Browse Mode Nav Bar (`pico.amber.css`)
* **Left Group (Brand / Home)**:
  1. `🌐 Yournaling` $\rightarrow$ `/` (timeline feed)
  2. *If logged in & has team*: `⚙️ Manage [Team Name]` (link to `/current_team`)
* **Center Group (Content & Discovery)**:
  1. `@Teams` $\rightarrow$ `/teams` 
  2. `@@Members` $\rightarrow$ `/teams/members`
  3. `🔍 Search` $\rightarrow$ `/new_search`
* **Right Group (Context, Mode Switch & Session)**:
  1. *If super-admin*: `🛡️ Admin Area` (link to `/admin`)
  2. *If logged in*: `Switch Team` (link to `/switch_current_teams`)
  3. *If logged in*: `👤 [User Name]` (opens `Logins` page)
  4.  *If logged in*: `Logout` / *If guest*: `Login`

---

#### 2. Manage Mode Nav Bar (`pico.green.css`)
* **Left Group (Browse / Team Home)**:
  1. `🌐 Yournaling` (link to `/`)
  2. `[Team Name] Timeline` $\rightarrow$ `/current_team` (team timeline)
* **Center Group (Domain Items & Actions)**:
  1. **Posts Group**:
     - `Chronicles` $\rightarrow$ `/current_team/chronicles`
     - `Memories` $\rightarrow$ `/current_team/memories`
  2. **Insights Group** (compact dropdown):
     - `Pictures` $\rightarrow$ `/current_team/pictures`
     - `Thoughts` $\rightarrow$ `/current_team/thoughts`
     - `Locations` $\rightarrow$ `/current_team/locations`
     - `Weblinks` $\rightarrow$ `/current_team/weblinks`
  3. **Team Group**:
     - `Members` $\rightarrow$ `/current_team/members`
  4. `🔍 Search` $\rightarrow$ `/current_team/new_search`
* **Right Group (Mode Switch & Session)**:
  1. *If super-admin*: `🛡️ Admin Area` (link to `/admin`)
  2. `Switch Team` (link to `/switch_current_teams`)
  3. `👤 [User Name]` (opens `Logins` page)
  4. `Logout`

---

#### 3. Admin Mode Nav Bar (`pico.blue.css`)
* **Left Group (Admin & Exit)**:
  1. `🛡️ Admin Area` $\rightarrow$ `/admin`
  2. `⬅ Exit Admin` (link to `/`)
* **Center Group (System & Domain Management)**:
  1. **Users & Teams Group**:
     - `Users` $\rightarrow$ `/admin/users`
     - `Teams` $\rightarrow$ `/admin/teams`
     - `Members` $\rightarrow$ `/admin/members`
  2. **Post Audit Group**:
     - `Pictures`, `Locations`, `Thoughts`, `Weblinks`
  3. **Insight Audit Group** (compact dropdown):
     - `Pictures`, `Locations`, `Thoughts`, `Weblinks`
  4. **Ops & Observability Group**:
     - `Record Events` $\rightarrow$ `/admin/record_events`
     - `Analytics` (Blazer) $\rightarrow$ `/admin/blazer`
     - `Jobs` (SolidQueue) $\rightarrow$ `/admin/jobs`
* **Right Group (Scope & Session)**:
  1. `Scope to Team` (currently without function, only text)
  2. `👤 [Admin Name]` (opens `Logins` page)
  3. `Logout`
  
## Content Area

* displaying content as articles or card makes likely the most sense for us (I am open to suggestions)
* every logical unit, like a team, a member, a memory or a post (= chronicle or memory) should be in its own card
* when e.g. in the manage section, where insights can be shown separately, they should be their own card - unless they are displayed as part of a post
* the manage section currently has a header with date, visibility control and other control buttons - which works well
* the browse section should have similar information (date, link to the post, and optional "edit" link for authorized users) in their header
* both post types should display their name as headline
* both post types should display their text (notice / memo) directly below
* memories display then their (optional) picture and below the picture in small text the (optional) location besides the (optional) weblink - and below that the (optional) thought 
* chronicles display their entries in the order of their position
* the insights and other elements should be styled the same way in both post types
* thoughts should be styled differently e.g. in italics or with a different background color, think of them as quotes
* chronicles are allowed to stand out from memories, maybe by a border or some other design trick
* both post types should have an optically clear beginning and end / or a clear separation from the other cards/articles on the page
  
## Pictures

* Clicking on a picture should not open a the show picture view on a new page, but open a larger variant in a modal
* Clicking on the picture in the modal should open PicturesOnlyController#show in a new tab

## Additional Design Ideas

### 1. Travel Journal & Editorial Aesthetics
* **Vertical Timeline Track for Chronicles**: Style chronicle entries with a subtle left timeline track/connecting line, making a chronicle feel like a continuous travel journey or itinerary chapter.
* **Thoughts as Field Notes / Pull Quotes**: Render thoughts using semantic `<blockquote>` styling with italics, quotation styling, or a subtle warm background tint so they look like handwritten journal reflections.
* **Rich Location Chips with Flag & Pin**: Use a compact badge with pin (`📍`) and country flag derived from `country_code` for locations, linking directly to map views.
* **Weblink Preview Cards**: Format weblinks as clean, compact chips with a link icon (`🔗`) and truncated domain name rather than raw long URLs.
* **Chronicle vs. Memory Distinction**: Give Chronicles a distinct card header with a badge (e.g. `📖 Chronicle · 5 entries`) and a subtle accent border, whereas Memories look like lightweight single-moment snapshots.

### 2. Navigation & Mode Awareness
* **Top Accent Bar for Modes**: A 3px top accent stripe on the sticky navbar reflecting the active mode (Amber = Browse, Green = Manage, Blue = Admin) for instant spatial orientation.
* **Unified Mode Switcher**: A segmented pill control in the navbar (e.g. `[ Browse | Manage ]`) allowing 1-click toggling between viewing published content and managing team content.
* **Consistent Top-Right User Menu**: Keep `[ Team Selector ]` and `[ User / Logout ]` pinned to the right side of the navbar across all three modes.
* **Scroll-to-Top Floating Button**: A subtle, smooth-scrolling floating button appearing after scrolling down long timelines.

### 3. Responsive Card Grids & Layout Density
* **Responsive Multi-Column Timeline**: On desktop screens, display timeline cards in a 2-column or 3-column CSS Grid / Masonry layout (`repeat(auto-fill, minmax(380px, 1fr))`), falling back to a clean single-column feed on mobile devices.
* **Manage Mode Card Actions**: Show action icons (Visibility 👁️, Edit ✏️, Delete 🗑️) cleanly in a compact card header or revealed on hover to keep the card body focused on content.
* **Card Elevation & Depth**: Add subtle hover elevation (`translateY(-2px)` and deeper soft shadow) to interactive cards for tactile feedback.

### 4. Interactive Feedback & Polish
* **Picture Lightbox Component**: Use a Pico CSS semantic `<dialog>` modal with backdrop blur, displaying the high-res image variant, caption/date, and an "Open Original in New Tab ↗" action.
* **Skeleton Loading Placeholders**: Display subtle animated skeleton card outlines while Turbo Frames fetch the next page of older or newer items.
* **Delightful Empty States**: Provide friendly, domain-specific empty states (e.g., *"No memories recorded yet — start by adding your first note, photo, or location!"*) with a prominent call-to-action button.



