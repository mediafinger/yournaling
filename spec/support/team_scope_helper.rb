#
#
# Capybara "visit page" methods
#
def visit_switch_current_team(team)
  visit current_teams_url

  page.within("#current_user_teams") do
    find(id: team.urlsafe_id).click
  end
end

def visit_go_solo(_team)
  visit current_teams_url

  page.within("#current_user_teams") do
    click_button("Go solo")
  end
end

#
#
# RSpec / Rails System spec "get response" methods
#
def switch_current_team(team)
  post current_teams_path, params: { current_team: { team_yid: team.yid } }
end

def go_solo(team)
  delete current_team_path(team) # , method: :delete
end
