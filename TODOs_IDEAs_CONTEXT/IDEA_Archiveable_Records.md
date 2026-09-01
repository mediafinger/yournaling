# Archive records

The new `Archivable` concern handles AR models with a `archived_at` column and adds the following functionality:

* a `default_scope` that filters out archived records ⬅️ 
* a `with_archived` scope that returns all records
* a `only_archived` scope that returns only archived records
* a `archived?` method that returns true if the record has been archived
* a `present?` method that returns false for archived records  ⬅️ 
* a `archive` method that sets the `archived_at` column to the current time
* a `archive_all` method that triggers `archive` for all records of a relation
* a `before_validation` hook is added to `make_changes_invalid_on_archived_records`

This concern does **NOT overwrite** the `destroy` and `delete` methods of ActiveRecord - we can discuss if we would rather want to do that - so with the current implementation `.delete` and `.destroy` will still work as for all other AR models _and really delete the records._  ⬅️ 

## Cleaning up archived records

The job `Recurring::CleanupSoftDeletedRecordsJob` should run every night,  
  * detect all models that include the Archivable concern  
  * and call the `cleanup_archived_records` method on each of them.
  * The method _really deletes_ archived records, but only when they are older than the **retention period**.
  * When `self.archived_retention_period` is not set on the including class, the archived records will never be really archived.

## Archivable models with associations

I've prepared methods to destroy associated records as well. As we don't have the use case yet, it's not really testable. Once we have this use case, we have to decide, how to handle associated records:

* option 1: try to archive associated records - raise error if they don't have the archived_at column
* option 2: try to archive associated records - delete them properly if they don't have the archived_at column
* option 3: configure it for every model individually
* option 4: ?

So for completeness, those are the extra methods:

* a `archive_associated` method that triggers archive for all associated records (untested, no current case)
* a `archive_associated!` method that triggers archive_associated but raises if nothing is done (untested, no current case)
* a `archive_associated_all` method that triggers archive_associated for all records of a relation (untested, no current case)
