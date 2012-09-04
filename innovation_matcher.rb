require 'sinatra'
require 'json'
require 'mysql'
require 'time'
require 'yaml'
require 'uuid'

SETTINGS = YAML.load(File.read(File.expand_path('../settings.yml', __FILE__)))

set :show_exceptions, false

def db
  @db ||= Mysql.connect(SETTINGS["mysql"]["host"], SETTINGS["mysql"]["username"], SETTINGS["mysql"]["password"], SETTINGS["mysql"]["database"])
end

def find_match user_data
  dob = user_data["dob"]
  [].tap do |innovations|
    result_set = db.query("SELECT * FROM innovations ORDER BY ABS(innovation_date - DATE(\"#{Mysql.quote(dob)}\")) LIMIT 3")
    innovation = utf8ize(result_set.fetch_hash())
    while innovation
      innovations << innovation
      innovation = utf8ize(result_set.fetch_hash())
    end
  end
end

def utf8ize hash
  return hash unless hash
  hash.keys.each do |key|
    val = hash[key]
    hash[key] = val.force_encoding('utf-8')
  end
  hash
end

def save_match user_data, innovations
  uuid = UUID.generate
  innovations.each do |innovation|
    db.query("INSERT INTO matches (match_id, innovation_id) VALUES (\"#{uuid}\", #{innovation['id']})")
  end
  {
    "match_id"    =>  uuid,
    "innovations" => innovations,
    "user_data"   => user_data
  }
end

def retrieve_match uuid
  result_set = db.query("SELECT i.* FROM matches m, innovations i WHERE m.innovation_id = i.id AND m.match_id = \"#{Mysql.quote(uuid)}\"")
  innovations = []
  innovation = utf8ize(result_set.fetch_hash)
  while innovation
    innovations << innovation
    innovation = utf8ize(result_set.fetch_hash)
  end
  {
    "match_id"    => uuid,
    "innovations" => innovations
  }
end

def pretty_json obj
  
  obj.to_json + "\n"
end


before do
  content_type "application/json"
end

get "/matches" do
  begin
    user_data = JSON.parse(request.body.read)
  rescue JSON::ParserError => e
    return 400
  end
  
  return 400 unless user_data.is_a?(Hash) && user_data["dob"]
  
  pretty_json(find_match(user_data))
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

get "/matches/:uuid" do
  uuid = params["uuid"]
  pretty_json(retrieve_match(uuid))
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
