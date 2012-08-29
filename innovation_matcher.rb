require 'sinatra'
require 'json'
require 'mysql'
require 'time'

set :show_exceptions, false

def db
  @db ||= Mysql.connect(ENV["MYSQL_HOST"], ENV["MYSQL_USER"], ENV["MYSQL_PASSWORD"], ENV["MYSQL_DATABASE"])
end

def find_match dob
  # { "id" => 11, "innovation" => "motion picture projector", "innovator" => "Fred H. Meyer",
  #   "date" => Time.parse("1972-09-04"), "patent_number" => "US3642357",
  #   "link_to_patent" => "http://www.google.com/patents/US3642357",
  #   "notes" => "This motion picture viewer projected movies onto a screen by cycling the film forward or backward at a set speed."
  # }
  db.query("SELECT * FROM innovations LIMIT 3")
end

def save_match user_data, innovations
  innovations
  # {"id" => 123}.merge("innovation" => innovation, "user_data" => user_data)
end

def retrieve_match id
  db.query("SELECT * FROM matches WHERE match_id=#{id.to_i}")
end

def pretty_json obj
  obj.to_json + "\n"
end


before do
  content_type "application/json"
end

post "/matches" do
  begin
    user_data = JSON.parse(request.body.read)
  rescue JSON::ParserError => e
    return 400
  end
  
  return 400 unless user_data.is_a?(Hash) && user_data["dob"]
  
  pretty_json(save_match(user_data, find_match(user_data)))
end

get "/matches/:id" do
  pretty_json(retrieve_match(request.params[:id]))
end

error 400 do
  pretty_json({:status => "error", :code => 400, :message => "The POST body must contain a valid JSON hash containing the key 'dob'"})
end

error 404 do
  pretty_json({:status => "error", :code => 404, :message => "No such route"})
end

error 500 do
  pretty_json({:status => "error", :code => 500, :message => "Server error"})
end

error do
  pretty_json({:status => "error", :message => "Unknown error"})
end

