# Refactor to smaller building blocks?!

## Insights

### Picture

* file
* meta-data (=> automatically extracted)
* name (unique ?)
* date (optional)

### Location

* GPS-coordinates (unique, can be generated out of address)
* Address (can be generated out of GPS-coordinates)
* name
* date (optional)

### Story

* text (markdown formatted, without image tags, without link tags(?))
* headline
* name (== headline)
* date (optional)

### Thought

* text (unformatted, max. 512 characters)
* name (=> generated from start of text)
* date (optional)

### Weblink

* URL (unique)
* name
* description (optional)
* date (optional)

## Memory

Contain at least one of and maximal one of each:

* Thought
* Picture
* Location
* Weblink

Can also contain:

* date

## Chronicle

Must contain:

* Story

Can contain:

* start date (optional)
* end date (optional)

Can contain multiple Insights of each:

* Picture
* Location
* Weblink

Order of entries can be changed.

## Experiences

Must contain

* Story

as headline and introduction.

Can contain:

* start date (optional)
* end date (optional)

Combines insights, memories and chronicles to a whole experience, can contain multiple of:

* Picture
* Location
* Weblink
* Thought
* Story
* Memory
* Chronicle

Order of entries (apart from intro story) can be changed.

Can contain:

* goal (examples: run 10km, do yoga 5 times a week, lose 10kg, build a camper van, get a job in...)
* progress unit (optional)
* status at the start (optional)
* status at the end (optional)

Entries can contain:

* progress value (optional)
 
Will display progress if entries contain progress values.
