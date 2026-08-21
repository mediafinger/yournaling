# https://github.com/crmne/archspec

# use `rails_strict` when the suppression works
architecture :rails

# Call with: "bundle exec archspec check --update-todo"
# to write violations to the TODO file
#
todo "TODOs_IDEAs_CONTEXT/TODO_ArchSpec.yml"

# Exceptions / Suppressions / ignore these violations:

# archspec:disable-next-line dependencies.no_cycles -- we are aware and ok with it
# ::ApplicationRecordYidEnabled
