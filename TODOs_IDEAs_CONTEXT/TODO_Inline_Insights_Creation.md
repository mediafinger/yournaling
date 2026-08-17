# Inline Insights Creation

Insights creation and inline Insights creation should work the same. Creating a valid insight can not take any shortcuts and should be solved once.

The code for inline Insights creation - when creating or updating a Memory or Chronicle - turned out to be rather brittle. Many errors can occur, the UX feels bad.

## The idea

When creating or updating a new Memory or Chronicle, and not selecting an existing Insight, the creation process for a new Insight should be triggered and it should no longer be inline.

This means, we might be creating insights, that end up being orphaned as the actual Memory or Chronicle is never being created or the update fails. That is ok, we can always create a cleanup-job later.

## UX

* UX should be smooth as this is a very central feature.
* I would prefer to avoid modal pop-ups.
* The best idea I have at the moment is a modal pop-up that opens for Insight creation and afterwards, when the Insight is created, it closes and the is back on the Insight form.
* I am very open for suggestions how to avoid the pop-up and work with redirects or other ways.
* Chronicle form should not show all the possible insights, but a dropdown "Add Insight" and when selected, it opens the form for the specific selected Insight type.
* After adding one Insight, there should be a another "Add Insight" button and so on.
* The same logic should be used for Memory as well - but limited to the maximum available Memory Insights.
* Users should never lose any form data, even when an error is triggered. This is should also work for uploaded pictures.
* Errors on Insight creation should only affect this one Insight, not the whole form.
* Errors on Insight creation should be fixable by the user, before continuing.
* Users can cancel the Insight creation at any time. When they do, all the data for this Insight should be discarded.
* Every created Insight should be associated with the Chronicle or Memory (when it's limits allow).

## UI

Feel free to style the form with CSS as you feel it is appropriate. You can use the existing styling as a baseline. The focus is on a clean, modern and user-friendly interface that makes creating and managing insights a breeze. Yournaling uses Pico.CSS therefore follow it's design principles. Reuse the templates for single insight creation and "inline" creation as much as possible to have a consistent experience and little code duplication.

## The plan

Start by examining the creation and update forms of all the Insights:

- [x] Location
    - [x] we check that address_or_coordinates_or_url_given is given, therefore the UX/UI should probably ask the user which of these three information they want to provide, instead of offering all three input fields
- [x] Picture
- [x] Thought
- [x] Weblink

Make them consistent in style and behaviour.

Only then rework the:

- [x] Memory form
- [x] Chronicle form

to incorporate the new Insight creation UX/UI. The goal is to make the Memory and Chronicle forms less cluttered and more user-friendly and the whole process more stable and reliable.

