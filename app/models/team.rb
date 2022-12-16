# Every User can be part of many Teams. A Team can have many Users.
# When creating a new User, create a Team for them.
# A User can invite other Users to join their Team.
# A User can leave any Team, as long as they are not the last User in the Team.
# A Team can only be destroyed if last User decides to destroy the Team
#  while still being part of another team or of the last User decides to destroy their whole Account.

class Team < ApplicationRecord
end
