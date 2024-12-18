require 'sinatra'
require 'net/http'
require 'uri'
require 'json'
require 'dotenv/load' 

API_KEY = ENV['TRELLO_API_KEY']
TOKEN = ENV['TRELLO_TOKEN']

LIST_ID = '67615173d736d1b76a1103d2' 

def create_trello_card(card_name, card_desc)
  uri = URI.parse("https://api.trello.com/1/cards")

  params = {
    key: API_KEY,
    token: TOKEN,
    idList: LIST_ID,
    name: card_name,
    desc: card_desc
  }

  uri.query = URI.encode_www_form(params)
  response = Net::HTTP.post_form(uri, {})

  if response.code == "200" || response.code == "201"
    
    # redirect 'http://localhost:4000'
    return "Card created successfully: #{card_name}"

  else
    return "Error creating card: #{response.body}"
  end
end

def create_trello_board(name)
  uri=URI.parse("https://api.trello.com/1/boards/")
  params={
    name: name,
    key: API_KEY,
    token: TOKEN
  }
  uri.query= URI.encode_www_form(params)

  response = Net::HTTP.post(uri,{})
  if response.code=='200' || response.code == '201'
      board_data = JSON.parse(response.body)
      LIST_ID= board_data['id']
      puts "list_id #{LIST_ID}"
      return "Board created Successfully Board Name: #{board_data['name']} Board Id: #{board_data['id']}"
  else
    return "Error creating board: #{response.body}"

  end
end
post '/create_board' do
  board_name = params[:board_name]
  create_trello_board(board_name)
end
# Serve the HTML form
get '/' do
  <<-HTML
  <!DOCTYPE html>
  <html>
  <head>
    <title>Create Trello Card</title>
  </head>
  <body>
    <h1>Create a Trello Card</h1>
    <form action="/create_card" method="POST">
      <input type="text" name="title" placeholder="Title" required><br>
      <textarea name="description" placeholder="Description" required></textarea><br>
      <input type="submit" value="Create Card">
    </form>
  </body>
  </html>
  HTML
end

# Handle form submission
post '/create_card' do
  title = params[:title]
  description = params[:description]

  # Call the Trello card creation function
  result = create_trello_card(title, description)
  "#{result}"
  # redirect 'http://localhost:4000'
end


