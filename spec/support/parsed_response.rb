def parsed_response
  JSON.parse(response.body)
end

def parsed_response_data
  JSON.parse(response.body)["data"]
end
