# Yournaling ToDos aka RanTanLog

Yournaling should become a travel journal, where we can:

* journal our (daily) experiences
* display our route and stops on a (google) map
* upload photos to the map and days
* enter locations with coordinates/address, photos, infos and dates
* combine chronicles with map and photos and locations to experiences
* combine experiences to journeys
* support markdown text entry with easyMDE editor https://easy-markdown-editor.tk/ 
* render as github-flavored markdown to html with redcarpet and rouge or others
* quickly upload a shared photo link or a google maps location or some note to use them later
* provide a draft - release - update - deactivate workflow
* support tagging
* support media snippet preview thinggy
* support versioning
* allow user login with different roles (admin, editor, support, reader)
* allow users to join the same team to manage content together
* have profile pages for the users and the vans
* allow oauth sign-up-and-sign-in to comment (first time commentators need clearing)
* allow users to report comments or commentators
* use dropbox api to mirror photos to user's personal dropbox folders
* also backup geojson files and all written posts to user's personal dropbox folders
* use geocoder gem with geoapify or mapbox-permanent api
* use free google maps embed api to display maps
* while allowing full backup, add to license that photos could be uploaded and stored on own servers
* add to t&c that backed-up geojson data is only for personal use
* add 3 example journals, e.g.:
  * foodie with memories of each course
    * experiences which describes the whole meal
    * journey that describes the whole vactions with all food experiences
    * add other (unwrapped) experiences and memories to this journey
  * vanlifer
    * with memories of nice locations and moments
    * experiences which include multiple days in a region
    * journeys that contain multi-week trips
    * add other (wrapped) experiences like installing solar on the van or a hike to this journey
  * a classic mental health journal


## Types of content

### Metadata

#### Metadata not explicitly mentioned, used for all content types (but not for Includes):

* date (optional on Includes to overwrite a date set in the included content, optional on Insights)
* tags (not used on Includes or Insights)
* team_yid (owned_by)
* timestamps (created_at, updated_at)
* user_yid (created_by)
* visibility (draft, internal, public, unpublished, blocked, deleted - not used on Includes or Insights) 

#### An visibility_changed_log will contain additional metadata:

* content_id
* content_type (memory, chronicle, experience, journey)
* team_yid (owned_by)
* user_yid (visiblity_changed_by)
* visiblity_changed_at (timestamp)
* visiblity_changed_from (draft, internal, public, unpublished, blocked, deleted)
* visiblity_changed_to (draft, internal, public, unpublished, blocked, deleted)

> When a moderator blocks or deletes content, Pictures and Links could be included in other content and need extra treatment.

### Insights (only published as part of a memory or chronicle)

#### Pictures

* must contain name / short description
* must contain image file

#### Locations

* must contain name / short description
* must contain at least one of:
  * (Google) Maps URL
  * geo-information (lat & lng)
  * address

#### Website Links

* must contain a name or description
* must contain a URL to a website (not pointing to a geolocation)

#### Video-Links

> Will be displayed in a video frame with controls and link to platform
> For paid users only

* must contain a name or description
* must contain a URL to a video (YouTube, Vimeo, DropBox, ...)

### Memories

* must contain short note / memo 
* must contain exactly one insight of:
  * picture
  * (geo) location
  * website link

### Chronicles

* must contain headline
* must contain (longer) notes
* can contain multiple insights of:
  * pictures
  * (geo) locations
  * website links

### Experiences

* combine memories and chronicles to a whole experience
* headline
* introduction
* resumee
* meta data
  * goal (examples: run 10km, do yoga 5 times a week, lose 10kg, build a camper van, get a job in...)
  * progress unit (optional)
  * progress start value (optional)
  * progress end value (optional)
  * completed status
 
### Journeys

* combine memories, chronicles and experiences to your journey
* contains all the fields experiences contain

### Special Content Types

> Only for paid users, specially suited for #VanLife blogs
> Treated like Chronicles
> Offering structured data fields for better documentation and display

#### Stage of a trip

> Record every evening when parking

* km driven 
* Location
  * address
  * GPS coordinates
  * Altitude in m
  * short description
* Orientation of parking
  * to detect a pattern on which side the sun usually is
* Date
* Temperature and Weather
* fotograph
  * location with van
  * location without van
  * view from location

#### Refueling

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

#### Stuff

> Document every (cool) item you own, ideally when buying it

* date
* price
* exact name
* short description
* shop bought from
* fotograph
  * invoice
  * item

### Includes

* a memory, chronicle or experience that is included into an experience or journey
* description (optional)
* the visibility of the Include is irrelevant, the visibility of the wrapper counts (unless blocked or deleted)
* meta data
  * day / days (1, 2, ...)
  * progress (examples: 550 Km, 86 Kg, 5 days sober, 20 %,...)
  * display: spotlight or unwrapped

#### An inclusion_log will contain additional metadata:

* content_type_included (memory, chronicle, experience)
* content_type_wrapper (experience, journey)
* included_at (timestamp)
* included_id
* team_yid (owner)
* user_yid (included_by)
* visiblity_status_included (draft, internal, public, unpublished)
* visiblity_status_wrapper (draft, internal, public, unpublished)
* wrapper_id


## Content presentation

* each team has an overview page for its journal
* it lists all current members
  * member profiles have space for a description
  * link their current location (precise or string)
  * mention their whereabout
  * offer contact links
  * invitation and "ask to be invited" functionality
* it offers space for a short description
* it displays a sorted list of journeys, experiences, chronicles
* display memories either in this list or in a separate section 
  * memories with a photo present this big
  * memories with no photo but a location present this big
  * allow to quickly browse through memories
* allow to filter by tags (and types?)
* highlight the latest 2 + 2 user selected + 1 random
* chronicles that are not part of an experience or trip are like single blog posts
* chronicles that are part of an experience or trip allow to navigate over the day
* chronicles that are part of an experience or trip allow to display the progress in an overview enriched with photos, locations and tags
* allow to quickly browse back and forth through experiences or journeys
* allow to unwrap experiences inside journeys, using them as labels while showing everything in chronological order


## Attributes of a chronicle

* date (2022-12-16, Friday)
  * set to current date, allow to edit
* headline
  * needed for index pages
* notes
  * enable markdown and emojis
* tags 
  * also allow to tag @users (after adding a short nickname to them)?
* pictures
  * linked beforehand or during editing
* (geo) locations
  * linked beforehand or during editing
* website link 

> Only date, notes and headline are mandatory.


## Visibility of content

* draft
  * visible to: team member with owner, manager, editor or publisher role and the creator themselves
  * default state for all new content
* internal
  * now also visible to team members with the reader role
  * this should clearly be a paid feature
* public
  * visible to everyone on the platform
  * visible to everyone in the whole wide world
* unpublished
  * like draft, but has been published before
* blocked
  * when content violates the rules, a platform-moderator can block the content
  * it will be treated like unplished, but visiblity can not be changed anymore
  * only after a change and a review a platform-moderator can unblock the content again
  * maybe automatic blocking after multiple user-reports
* only team members with the publisher role can publish content to people outside their team
* owners, managers and publishers can unpublish content

## Content discovery

* users will see an overview page with the latest published content
  * updated experiences and journeys should be pushed
  * updated means to add least add a day or include a new part
* additionally popular and featured content will be displayed
* the overview page will be filterable by tags, teams and users
* later a search functionality could be added
* users will be able to follow teams and users

## Communication between users

* no public comments
  * comments might go to a team board
  * comments can be linked to any content type or generally the team
  * any team member should be able to react (emojy) to a comment
  * any team member should be able to answer a comment (thread on the board, direct message for the user)
  * both sides can close a comment-thread
  * team owners and managers can block all or individual users from writing comments
  * team owners and managers can allow or prohibit comments for each content type
  * limit number of comments users can write by number of unanswered in the last 30 days
* direct messages
  * always allowed between team members 
  * when a user contacts a user for the first time, the other side has to give permission first
  * users can block all or any users from contacting them
  * no attachments in messages
  * links are allowed, but no preview rendered (and maybe a warning added)
  * messages support markdown and emojis

## Vanity metrics

* number of views
* number of ratings
* average rating
* reactions
* comments
* links
* shares
* maybe none at all - or only against extra payment?

For clarification: all this functionality might be built and the users should have access to their own lists of those, and the teams should get informed about every(?) interaction (or not?), but maybe none of those will be displayed with the content. And even if they would be, the team owners and managers should be able to hide or display each metric for each content type.

The "vanity board" with detailed statistics could be a paid feature. The alternative maybe a weekly summary?

## Settings / individualization

* team members should be able to influence the presentation of their journal
  * how to display memories (separate list or chronologically mixed in) 
  * if alumni should be displayed
  * if experiences are unwrapped in journeys
  * which template is used to display the journal (e.g. other colors and fonts) as a paid feature
* content creators and editors should have control which of their information is linked or displayed with the content
* users
  * should be able to give and hide as much profile information as they like 
  * should be able to limit others from contacting them
  * should be able to pick an alternative high-contrast template (or just a neutral one) (maybe a paid feature)
  * should be able to (un)wrap experiences in journeys
  * should be able to sort and filter the journals, memories, chronicles, experiences and journeys
* some of the above individualization options might become paid features 

## Photos

* ~~only linking to Google Photos and Apple Photos?~~
* ~~mirroring them to a team owners personal Dropbox?~~
* or just upload them to Amazon S3?
  * as this is not for free, this might have to be limited
  * image quality dependent on paid account or not?
  * upload up to 10 (?) MByte pictures
  * max 4000x3000 image generated
  * generate preview to 400x300
  * display all images in 3:2 widescreen on page
  * apart from square profile pictures with 400x400 (probably rounded)
* no pornography (sorry, its the payment providers' fault)
* cut down on the nudity of published photos
* as long as photos are in draft state, no one but the team members can see them

## Locations

* a (Google Maps?) link to a place
* if an address or coordinates exist, (reverse) geocode the information and store it all
  * APIs do not offer this for free, so this has to be limited, higher limit for paid accounts
* a name or description
* the name or description is mandatory and either a maps-link or geocoding information have to exist as well

## Website Links

* a URL to a website (not pointing to a geolocation)
* a name or description
* the name or description is mandatory and the link as well

## User roles

* guest
  * anyone that browses the service without being logged in
* free user
  * anyone that browses the service while being logged in, but not paying for the service
* paying user 
  * anyone that browses the service while being logged in and having a paid individual user account
  * anyone that browses the service while being logged in and being a team owner of a paid team
  * anyone that browses the service while being logged in and granted these rights through the beta phase
  * anyone that browses the service while being logged in and granted these rights through family & friends
  * anyone that browses the service while being logged in and granted these rights through a promotion
* team member
  * owner
    * owns the team, can invite/remove other users to/from the team, can manage everything team related
    * are the only ones that can disown themselves from a team
    * benefit from the same status as paying users, if they are owner of a paid team (max 2 per team)
  * manager
    * can manage all team related objects, change member roles (except owner) and invite readers
  * editor
    * can create and update all team related objects, but not delete any
  * publisher
    * can change the visibility of existing team related objects
  * creator
    * can create memories with note, photo, location and link but not update or delete those or any else
    * only available for paid teams
    * future feature
  * reader
    * can read all team wide published objects, but not create or update any
    * only available for paid teams
    * future feature
    * kind of a "premium-subscriber" or an "only-fan"

## Paid features

* teams
  * without a paid team account, teams can have only one free member
  * users with individual paid accounts do not count to the quota
  * paying teams can pay more to have more members
    * members with an individual paid user account do not count to the quota
  * members with creator role are only allowed in paying teams
    * creators with a paid user account do not count to the quota
    * there are special packages available to add more creator-only members
  * members with reader role are only allowed in paying teams
    * readers with a paid user account do not count to the quota
    * there are special packages available to add many reader-only members
    * teams might charge readers for access, then they not count to the quota, we would keep 30% of the quarterly fee
  * publish content team internally (to readers)
  * vanity metric board
  * alternative templates
  * more individualization options (maybe)
  * can link their store and/or affiliate links prominently
  * can link their youtube account prominently and embed videos
  * can link other social media accounts prominently
  * can link their website prominently
  * content will be featured more often than of free teams
  * higher geocoding limits
  * higher photo storage and quality limits (maybe?)
  * no ads displayed besides team content (also not to free users and guests)
* user 
  * no ads displayed besides any content of others
    * ads displayed besides own content, when free users or guests view it
  * can join multiple teams without counting to their quota
  * higher geocoding limits
  * higher photo storage and quality limits (maybe?)
  * more individualization options (maybe)
  * writing unlimited comments
  * special content types for #VanLifers available 
* team owners of paid teams enjoy the same benefits as paying users (max 2 per team)

### Paid packages

* individual user 29€ per quarter or 99€ per year
* mini-team with two members 49€ per quarter or 149€ per year
* midi-team with five members 29€ per month or 119€ per half year
* five extra team members 19€ per month or 79€ per half year 
* twenty extra team members 59€ per month or 239€ per half year
* thirty creator- and reader-only members 49€ per month
* one-hundred creator- and reader-only members 99€ per month
* fifty reader-only team members 29€ per month or 119€ per half year
* two-hundred reader-only team members 39€ per month or 149€ per half year
* need more? contact us!
* pay one-time for a team you are not a member off (1, 3, 6 or 12 months packages for min. number of current members)
* pay one-time for another user (2, 3, 4, 6 or 12 months packages)
* subscribe (monthly, quarterly, half yearly or yearly) as paying-reader to a team
  * fee set by team
  * payment fees are substracted (fixed + %, discourage small recurring payments)
  * we keep 30% of what's left
  * the other 70% go to the team's account (how to handle pay-outs?, delay and aggregation?)

### Ads

* avoid, but if then only display to free users and guests
* avoid, but if then don't display on paying teams' content

## Content rules

* respect the right to privacy and dignity of others
* no hate
* no isms
* no stupidity
* no illegal stuff
* no content you don't own
* no sexual content (sorry, it's the payment providers fault)
* when we don't like it, we'll block your content and allow you to change it
* when you keep violating these rules, we'll kick you out (but give you a backup)

### Content checks

* users can report content violating the rules
  * checkboxes for type of violation
  * text-field for additional information (rate-limit / paying users only?) 
* reports get collected on a platform-moderator dashboard
* reports trigger notification to platform-moderators
* platform-moderator can block the content
  * platform-moderator can soft-delete content (when clearly illegal, sexual, offensive, not-owned)
  * automatic notification to reporter
  * automatic notification to content-creator and the team's owners
* reports can trigger an automatic blocking, when multiple are created for the same content
* platform-moderator decided the content is ok
  * automatic notification to reporter
  * mark content as okay for updated_at timestamp
* platform-moderator reviews changed content and unblocks it
  * automatic notification to content-creator and the team's owners
  * mark content as okay for updated_at timestamp
* paying teams with multiple violations are set under observation
  * their content starts in blocked instead of draft (?)
  * they have to ask for a review to unblock it
  * only do this for 10 days or so
  * keep them under probation for a month or so
* teams with multiple violations or paying teams violating their probation
  * block the team (treat all content of the team as blocked, prohibit new readers, don't charge readers)
  * inform them that this is the last warning
  * unblock them after a week
  * keep them under last warning probation for three months or so
* teams voiding their last chance
  * inform them that their content will be deleted and their team's account closed
  * allow them to download all their content
  * partially refund the team account's cost
  * when they beg and agree to buy at least a 6 months team extension, give them another last chance
* while this is a team focused effort, banning a single user could be sufficient in some cases

## Platform moderation

### Dashboards

* newly created or updated content
* reports of suspicios or offensive content
* content violation history of teams and users
* probation and last-chance status of teams
* payment history and status of teams
* payment history and status of users
* new user accounts
* page views
* vanity metrics to measure activity
* daily active users
* (paying) user support questions
* ad displays
* promotions

### Notification Emails

* new reports
* payment issues
* platform issues

### Roles

* account support
  * help with all payment related issues
  * help with all issues around adding/removing users to/from teams
  * help with team roles questions
  * can trigger refunds and partial refunds
  * inform marketing about issuing a promotion to certain users or teams
* admin
  * access to all dashboards in all details
  * can block teams
  * can block users (disallowing them any action but viewing)
  * can close users and teams and delete all their content 
  * inform account support about refunds for users and teams
* copy writer
  * manage newsletters
  * update welcome message
  * write news for front-page (latest chronicle in the platform's journey?)
* moderator
  * handle reports
  * review content
  * block content
  * soft-delete content (when clearly illegal, sexual, offensive, not-owned)
  * unblock content 
  * inform admin about users and teams to close
* promoter
  * manage ad display settings
  * manage promotions
* stakeholder
  * only read access to dashboards  
