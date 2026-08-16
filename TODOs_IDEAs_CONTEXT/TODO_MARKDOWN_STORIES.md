# Story Model with Markdown editor

## Architecture of a new "Story" insight type

* Should follow all the same patterns as the other insight types.
* YID_CODE: "story"
* Should be made available as ChronicleEntry (but not to Memory)
* Attributes
  * name : String (required, used as headline)
  * content : Text (required, the actual story in markdown format)
  * date : Date (required)
  * team_id: String (required)
  * visibility: String (default: :internal)
  * created_at : DateTime (required)
  * updated_at : DateTime (required)
  * id: yid
* Markdown rendering: happens on display
  
## Gems

* Marksmith to provide editor and handling: https://github.com/avo-hq/marksmith
* Commonmarker to render Markdown safely: https://github.com/gjtorikian/commonmarker
* Text Expander (optionally / later): https://github.com/github/text-expander-element

## Story MVP

* new Insight Type: Story 
* Will allow to write long form stories (for now: 16384 characters)
* Will support Markdown
* The Marksmith gem will be used for the markdown editor
* Ideally the preview pane will open side by side with the editor, when writing or editing the story.
* Story content should be stored as Markdown in the database!
* Will start with simple/default Markdown rendering and GFM
  * prevent pictures and links in MVP? Or does Marksmith make it easy to integrate them?

## Improvements after the Story MVP has been merged

* :emoji: support, @team references, @@user references, and #hashtag references in stories, provided by:
  * https://github.com/github/text-expander-element
  * autocomplete for :emoji:, @team, @@user, #hashtag (there is no definition of a Hashtag yet though)
  * investigate if this feature set can be used for the other text fields as well (Thought.text, Memory.memo, Chronicle.notice) without enabling Markdown or a Rich-Text editor in them
* Custom styling for stories will follow later, and will be added as an improvement.
* Picture handling in Markdown via Marksmith (?)
* Link handling in Markdown via Marksmith (?)
* Table rendering (?)
* Mermaid diagram rendering (?)
* Code highlighting (?)
* Customizable code highlighting themes - or just multiple to select from (?)
* Customizable Markdown themes - or just multiple to select from (?)
* Keyboard shortcuts for rich-text formatting (bold, italic, etc.)


## First Recommendation for the Upcoming `Story` Insight - needs refinement!

**Recommendation: Use [Marksmith](https://github.com/avo-hq/marksmith).**

#### Why Marksmith fits Yournaling best:
1. **Gem-based Lifecycle**: Installs cleanly via `Gemfile` (`gem "marksmith"`) with standard gem updates, zero monkey-patching, and clean Importmap pinning (`bin/importmap pin marksmith`).
2. **Fits the Stimulus & ViewComponent Stack**: Marksmith uses standard Stimulus controllers and ViewComponents, matching Yournaling's existing architecture (`PictureSelectController`, `ChronicleEntryComponent`, etc.).
3. **Write / Preview Tabs**: For long-form stories in chronicles, being able to toggle between raw markdown and a formatted preview is a proven, reliable UX. Better would be to display them side by side.
4. **Active Storage Integration**: Seamlessly embeds and attaches pictures to the `Story` insight using the app's existing Active Storage configuration and `ImageUploadConversionService`.

---

### Suggested Implementation Roadmap for `Story`

1. **Add Dependency**:
   ```ruby
   # Gemfile
   gem "marksmith"
   gem "commonmarker" # or use kramdown/redcarpet for fast GFM parsing
   ```
2. **Domain Model (`Story`)**:
   - Model `Story < ApplicationRecordForContentAndPosts` (`YID_CODE = "story"`).
   - Columns: `team_id`, `name`, `body` (`text`), `date`, `visibility`.
   - Add `Story` to `ChronicleEntry::VALID_ENTRY_TYPES` and update `ChronicleInsightAttacher`.
3. **Form Integration**:
   - Use `marksmith :body` in `app/views/current_teams/stories/_form.html.slim` and inside `ChronicleAttachInsightsFormComponent`.
4. **Render Pipeline**:
   - Create a reusable `MarkdownRenderer` helper/service using `Commonmarker` + Rails HTML sanitization (`sanitize`) for safe rendering across `current_teams`, `teams` (browse), and `admins` views.