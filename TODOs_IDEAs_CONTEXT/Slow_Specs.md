# Test suite slowing down

We've added 100s of new specs in the last few weeks, and now the test suite is slowing down. The CI build currently takes 2-3 minutes. Ideally the CI would run faster.

We should have a look into the slowest specs and example groups and see if we can speed them up.

## Slowest specs at last measurement

### Top 16 slowest examples

```text
Top 16 slowest examples (21.44 seconds, 19.4% of total time):
  /current_team/chronicles PATCH /update with valid parameters attaches both an existing picture and a newly uploaded picture during create and edit in sequence
    3.59 seconds ./spec/requests/current_teams/chronicles_request_spec.rb:472
  Card Open and Rewrite Links on a lazily-loaded (page 2) card from the turbo-frame-wrapped home feeds
    2.7 seconds ./spec/system/card_open_and_rewrite_links_spec.rb:118
  Picture variant generation creates a thumbnail variant with max dimensions 160x120
    1.5 seconds ./spec/models/picture_spec.rb:78
  ImageUploadConversionService.call with a valid JPEG file converts the image to webp and stores it as an ActiveStorage blob
    1.37 seconds ./spec/services/image_upload_conversion_service_spec.rb:12
  current_teams/pictures/index renders a list of pictures
    1.22 seconds ./spec/views/current_teams/pictures/index.html.erb_spec.rb:15
  User Journey: Sign in, switch team, upload photo, create memory, and view timeline completes the full journey seamlessly
    1.21 seconds ./spec/system/user_journey_spec.rb:10
  Picture variant generation creates a large variant with max dimensions 1200x900 and quality 90
    1.1 seconds ./spec/models/picture_spec.rb:92
  ImageUploadConversionService.call with an oversized image exceeding MAX_PIXEL dimensions downsizes dimensions to fit within MAX_PIXEL_WIDTH and MAX_PIXEL_HEIGHT
    1.08 seconds ./spec/services/image_upload_conversion_service_spec.rb:61
  /current_team/chronicles PATCH /update with valid parameters attaches a second picture to a chronicle already having a picture and displays both on show (regression test)
    1.07 seconds ./spec/requests/current_teams/chronicles_request_spec.rb:363
  current_teams/pictures/show renders attributes in <p>
    1.05 seconds ./spec/views/current_teams/pictures/show.html.erb_spec.rb:7
  Current Team Manage Section Timeline excludes draft artefacts for a publisher
    1.03 seconds ./spec/system/current_team_timeline_spec.rb:66
  /current_team/chronicles GET /show displays all attached pictures when multiple pictures are attached to a chronicle (regression test)
    0.97004 seconds ./spec/requests/current_teams/chronicles_request_spec.rb:115
  teams/:team_id/memories GET /index renders a successful response for published memories
    0.90686 seconds ./spec/requests/teams/memories_request_spec.rb:18
  /teams GET /edit when user team member and owner is successful
    0.90441 seconds ./spec/requests/teams_request_spec.rb:104
  teams/:team_id/memories GET /index omits internal and draft memories from the list
    0.89178 seconds ./spec/requests/teams/memories_request_spec.rb:25
  Content Visibility Modal Dialog renders the modal dialog on insight show view and allows updating visibility
    0.84772 seconds ./spec/system/content_visibility_modal_spec.rb:66
```    

### Top 16 slowest example groups

```text
Top 16 slowest example groups:
  current_teams/pictures/index
    1.22 seconds average (1.22 seconds / 1 example) ./spec/views/current_teams/pictures/index.html.erb_spec.rb:5
  User Journey: Sign in, switch team, upload photo, create memory, and view timeline
    1.21 seconds average (1.21 seconds / 1 example) ./spec/system/user_journey_spec.rb:5
  current_teams/pictures/show
    1.05 seconds average (1.05 seconds / 1 example) ./spec/views/current_teams/pictures/show.html.erb_spec.rb:1
  Current Team Manage Section Timeline
    0.72906 seconds average (2.92 seconds / 4 examples) ./spec/system/current_team_timeline_spec.rb:5
  Chronicle Creation, Multiple Insights & Entry Reordering
    0.69123 seconds average (1.38 seconds / 2 examples) ./spec/system/chronicle_entry_reordering_spec.rb:5
  ImageUploadConversionService
    0.6339 seconds average (3.17 seconds / 5 examples) ./spec/services/image_upload_conversion_service_spec.rb:6
  teams/:team_id/memories
    0.61943 seconds average (2.48 seconds / 4 examples) ./spec/requests/teams/memories_request_spec.rb:5
  Picture
    0.59422 seconds average (10.7 seconds / 18 examples) ./spec/models/picture_spec.rb:5
  Content Visibility Modal Dialog
    0.5049 seconds average (2.02 seconds / 4 examples) ./spec/system/content_visibility_modal_spec.rb:5
  Card Open and Rewrite Links
    0.49811 seconds average (3.49 seconds / 7 examples) ./spec/system/card_open_and_rewrite_links_spec.rb:5
  Insight Destruction with Reference Checking
    0.45734 seconds average (1.37 seconds / 3 examples) ./spec/system/insight_destruction_spec.rb:5
  PictureLightboxComponent
    0.45219 seconds average (1.36 seconds / 3 examples) ./spec/view_components/picture_lightbox_component_spec.rb:5
  Memory Form Picture Upload & Insight Management
    0.39103 seconds average (1.56 seconds / 4 examples) ./spec/system/memory_form_picture_upload_spec.rb:5
  Picture Lightbox Modal
    0.3864 seconds average (0.3864 seconds / 1 example) ./spec/system/picture_lightbox_spec.rb:5
  teams/:team_id/pictures
    0.34067 seconds average (0.68134 seconds / 2 examples) ./spec/requests/teams/pictures_request_spec.rb:5
  /current_team/chronicles
    0.33939 seconds average (12.56 seconds / 37 examples) ./spec/requests/current_teams/chronicles_request_spec.rb:5
```   

### Data for the whole test suite

```
Finished in 1 minute 50.63 seconds (files took 5 seconds to load)
1038 examples, 0 failures, 1 pending

Randomized with seed 30334

real    1m57.071s
user    1m21.230s
sys     0m10.992s
```

> Just for comparison: `time bin/mcp_rake_ci` takes 2m50s (which includes the whole tests suite + multiple linters and quality gates).

## What not do do in this scope

* Don't just delete specs, test cases or regression tests.
* Don't parallelize the test suite (this is a valid strategy, which we will tackle separately).

## Run a new check of the slowest specs

To get updated numbers, open `spec/spec_helper.rb` and set `config.profile_examples = 16` (it is currently set to 0).

Then, run `bin/mcp_rspec` to run the whole test suite and get the slowest specs.

