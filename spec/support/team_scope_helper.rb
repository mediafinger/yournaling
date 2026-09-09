#
#
# Capybara "visit page" methods
#
def visit_switch_current_team(team)
  visit switch_current_teams_url

  page.within("#current_user_teams") do
    find(id: team.urlsafe_id).click
  end
end

def visit_go_solo(_team)
  visit switch_current_teams_url

  page.within("#current_user_teams") do
    click_button("Go solo")
  end
end

#
#
# RSpec / Rails System spec "get response" methods
#
def switch_current_team(team)
  post switch_current_teams_path, params: { current_team: { team_id: team.id } }
end

def go_solo(team)
  delete switch_current_team_path(team) # , method: :delete
end
