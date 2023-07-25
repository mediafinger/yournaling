# README

> **_Journal your journey_**  
> _... on [yournaling.com](https://yournaling.com)_

## YID - Yournaling ID

YID are **sortable** **unique** IDs which contain:

* the object klass (unique nickname)
* the created_at timestamp at UTC in ISO8601 form with microsecond precision
* a UUID in a url_safe form

YID are:

* stored in the database field `yid` 
* used in serializers to the frontend
* used in associations to other objects (with DB foreign_key)
* primary_keys to be compatible with Rails' associations
* ideally be created on Postgres level
* for now created by in a Rails hook before persisting a new object
* stable, they never change

YID are constructed like this:

* `photo_2023-02-26T09:20:20.075800Z_TN1ol4FTGH3MV7utQ3laPQ`
* `object.klass_object.created_at.utc.iso8601(6)_object.uuid.urlsafe_base64`
* _Be aware that the "random" UUID part (everything after the 2nd `_`) can contain **any** character._

> YID creation is slow compared to integer IDs or UUIDs, they are long and comparing them is more costly than comparing UUIDs. Their benefits are that they directly reveal the type of object (which is a massive bonus when debugging or sharing object identifiers) and that they are sortable at every moment, without additional database queries (which can speed up the app a lot).

Any YID can be fed to the search / an endpoint / a disolver service which will return the actual object (or an error e.g. 403, 404, ...).

YID are used in URLs, but as they are long and probably funny-looking, whenever possible a slug should be used. The slug:
