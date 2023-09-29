# README

> **_Journal your journey_**  
> _... on [yournaling.com](https://yournaling.com)_

## YID - Yournaling ID

YID are **sortable** **unique** IDs which contain:

* the object klass (unique nickname)
* the created_at timestamp at UTC in ISO8601 form with microsecond precision
* a short UUID in a url safe form

YID are:

* stored in the database field `yid` as primary key
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

Any YID can be fed to the search / an endpoint / a disolver service which will return the actual object (or an error e.g. 403, 404, ...).

YID are used in URLs, but as they are long and probably funny-looking, you might consider using slugs. The slug should be created by some fast symmetric encoding / decoding encryption algorithm that backends and frontends can use.
