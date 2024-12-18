class Trello
  def self.creator(idList)
    bundle_install
    github
    includes
    layouts
    css
    
    Dir.mkdir("_plugins") unless Dir.exist?("_plugins")
    content = <<~RUBY
      require 'dotenv/load'
      require 'trello'
      # require 'pry'
      module Jekyll
        class ContentCreatorGenerator < Generator
          safe true
          ACCEPTED_COLOR = "green"

          def setup
            @trello_api_key = ENV['TRELLO_API_KEY']
            @trello_token = ENV['TRELLO_TOKEN']

            Trello.configure do |config|
              config.developer_public_key = @trello_api_key
              config.member_token = @trello_token
            end
          end

          def generate(site)
            setup
            existing_posts = Dir.glob("./_posts/*").map { |f| File.basename(f) }

            cards = Trello::List.find("#{idList}").cards
            cards.each do |card|
              labels = card.labels.map { |label| label.color }
              next unless labels.include?(ACCEPTED_COLOR)
              due_on = card.due&.to_date.to_s 
              slug = card.name.split.join("-").downcase
              created_on = DateTime.strptime(card.id[0..7].to_i(16).to_s, '%s').to_date.to_s
              article_date = due_on.empty? ? created_on : due_on
              content = """---
      layout: post
      title: \#{card.name}
      date: \#{article_date}
      permalink: \#{slug}
      ---

              \#{card.desc}
              """
              file_path = "./_posts/\#{article_date}-\#{slug}.md" 
              if !File.exist?(file_path) || File.read(file_path) != content
                File.open(file_path, "w+") { |f| f.write(content) }
              end  
              existing_posts.delete("\#{article_date}-\#{slug}.md")
            end

            existing_posts.each do |stale_post|
              file_path = "./_posts/\#{stale_post}"
              File.delete(file_path) if File.exist?(file_path)
            end
          end
        end
      end
    RUBY

    file_path = "_plugins/creator.rb"
    File.write(file_path, content)
    puts "File '#{file_path}' has been created successfully!"

    post_trello(idList)
  end

  def self.post_trello(idList)
    content= <<~'RUBY'
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
        return "Card created successfully: #{card_name}"
      else
        return "Error creating card: #{response.body}"
      end
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
    end

    
    RUBY
    
    file_path= "_plugins/post_to_trello.rb"
    File.write(file_path,content)
    puts "File '#{file_path}' has been created successfully!"

  end

  def self.github
    ruby_version
    scripts
    env_gitignore
    content= <<~'RUBY'
name: Build blogs from Trello Card

on:
  push:
    branches:
      - gh-pages
  schedule:
    - cron: '0 0 * * *'
  workflow_dispatch:

jobs:
  build-and-deploy:
    name: Build and commit on same branch
    runs-on: ubuntu-latest
    steps:
      - name: Checkout source code
        uses: actions/checkout@v2
      
      - name: create .env file
        run: echo "${{ secrets.DOT_ENV }}" > .env
      
      - name: Setup ruby 
        run: echo "::set-output name=RUBY_VERSION::$(cat .ruby-version)"
        id: rbenv
      
      - name: Use Ruby ${{ steps.rbenv.outputs.RUBY_VERSION }}
        uses: ruby/setup-ruby@v1
      
      - name: Use cache gems
        uses: actions/cache@v1
        with:
          path: vendor/bundle
          key: ${{ runner.os }}-gem-${{ hashFiles('**/Gemfile.lock') }}
          restore-keys: |
            ${{ runner.os }}-gem-

      - name: bundle install
        run: |
          gem install bundler -v 2.4.22
          bundle install --jobs 4 --retry 3 --path vendor/bundle
      
      - name: rm posts
        run: |
          cp ./scripts/rmposts.sh _posts/rmposts.sh
          chmod +x _posts/rmposts.sh
          cd _posts
          sh rmposts.sh
          rm rmposts.sh
          cd ..
      - name: Build posts
        run: |
          bundle exec jekyll build
          
      - uses: EndBug/add-and-commit@v7
        with:
          add: '*.md'
          author_name: Habi Pyatha
          branch: gh-pages
          message: 'auto commit'
    RUBY
    Dir.mkdir(".github") unless Dir.exist?(".github")
    Dir.mkdir(".github/workflows") unless Dir.exist?(".github/workflows")
    file_path = ".github/workflows/build-block.yml"
    File.write(file_path, content)
    puts "File '#{file_path}' has been created successfully!"

  end

  def self.ruby_version
    file_path = ".ruby-version"
    File.write(file_path, "3.3.4")
    puts "File '#{file_path}' has been created successfully!"
  end

  def self.scripts
    content= <<~'RUBY'
counts= `ls -1 *.md 2>/dev/null | wc-1`
if [ $count != 0]
then 
echo true
echo "Removing all md files"
rm *.md
fi
    RUBY
    Dir.mkdir("scripts") unless Dir.exist?("scripts")
    file_path = "scripts/rmposts.sh"
    File.write(file_path, content)
    puts "File '#{file_path}' has been created successfully!"

  end

  def self.bundle_install
    gemfile_path = "Gemfile"

    unless File.exist?(gemfile_path)
      gemfile_content=<<~GEMFILE
      source 'https://rubygems.org'

      gem 'ruby-trello'
      gem 'dotenv'
      gem "json"
      gem "sinatra"
      gem 'net-http'
      gem 'uri'
      GEMFILE
      File.write(gemfile_path, gemfile_content)
    else
      gemfile_content = File.read(gemfile_path)

      unless gemfile_content.include?("dotenv")
        gemfile_content +="\ngem 'dotenv' \n"
      end
      unless gemfile_content.include?("ruby-trello")
        gemfile_content +="\ngem 'ruby-trello' \n"
      end
      unless gemfile_content.include?("json")
        gemfile_content +="\ngem 'json' \n"
      end
      unless gemfile_content.include?("sinatra")
        gemfile_content +="\ngem 'sinatra' \n"
      end
      unless gemfile_content.include?("uri")
        gemfile_content +="\ngem 'uri' \n"
      end
      unless gemfile_content.include?("net-http")
        gemfile_content +="\ngem 'net-http' \n"
      end

      File.write(gemfile_path,gemfile_content)
      puts "Gems 'ruby-trello' ,'dotenv', 'json', 'sinatra' added to Gemfile."

    end
    system("bundle install")
    puts "Gems installed successfully!"
  end

  def self.env_gitignore
    gitignore_path= ".gitignore"

    if File.exist?(gitignore_path)
      gitignore_content = File.read(gitignore_path)

      unless gitignore_content.include?(".env")
        File.open(gitignore_path, "a") do |file|
          file.puts(".env")  
        end
        puts ".env has been added to .gitignore"
      else
        puts ".env is already in .gitignore"
      end
    else
      puts "No .gitignore file found. Please create one first."
    end

  end

  def self.css
    Dir.mkdir("assets") unless Dir.exist?("assets")
    Dir.mkdir("assets/css") unless Dir.exist?("assets/css")
    file_path = "assets/css/style.css"
    content = <<~'CSS'     
    /* @import "minima/skins/{{ site.minima.skin | default: 'classic' }}";
    @import "minima/initialize";  */
    *{
        /* background-color: black;
        color: white; */
        text-decoration: none;
        margin: 0;   
    }
    body{
        background-color: rgba(37, 36, 36,0.5);
        color: white;
    }
    .navi{
        display: flex;
        background-color: pink;
        align-items: center;
        padding:4px;
    }
    .navi>h1{
        margin-left: 5%;
    }
    .navi>span{
        margin-left: auto;
        margin-right: 5%;
        
    }
    .flex{
        display: flex;
    }
    .center{
        text-align: center;
        font-weight: 200;
        text-shadow:1px 1px 1px black ;
    }
    .wrapper{
        width: 90%;
        margin: auto;
        text-align: justify;
        margin-top:4%;
    }
    .form{
        width: 90%;
        /* align-content: center; */
        /* background-color: blue; */
        margin:5% auto;
        display: flex;
        flex-direction: column;
        align-items: center;
        /* border: 2px solid red ; */
        box-shadow: 12px 5px 54px 11px rgba(0, 0, 0, 0.2);



        
    }
    .tit,.desc{
        width: 90%;
        height:30px;
        margin-top: 5px;
        /* background-color: pink; */
        border-radius: 10px;
        text-align: center;
        box-sizing: border-box;
        padding: 6px;
    }
    .desc{
        height: 100px;
    }
    input[type="submit"]{
        margin-top: 10px;
        padding: 8px 16px;
        border-radius: 10px;
    }
    CSS
    File.write(file_path, content)
    puts "File '#{file_path}' has been created successfully!"
  end

  def self.layouts
    Dir.mkdir("_layouts") unless Dir.exist?("_layouts")
    file_path = '_layouts/home.html'
    content = <<~'HOME'
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Large</title>
        <link rel="stylesheet" href="{{site.baseurl}}/assets/css/style.css">

        
    </head>
    <body>
        {%include nav.html%}
        <div class="wrapper">
            {{content}}
        </div>
        <script src="{{site.baseurl}}/assets/js/script.js"></script>
    </body>
    </html>
    HOME
    File.write(file_path,content)
    puts "File '#{file_path}' has been created successfully!"
    file_path = '_layouts/post.html'
    content = <<~'POST'
---
layout: home
---

{{content}}
    POST
    File.write(file_path,content)
    puts "File '#{file_path}' has been created successfully!"

    file_path = '_layouts/write.html'
    content = <<~'WRITE'
---
layout: home
---
    <div class="center">
        {{content}}
    </div>

    <form action="http://localhost:4000/create_board" class="form" id="boardForm">

        <input type="text" name="board_name" placeholder="board name" class="tit" id="boardName">
        <br>       
        
        <input type="Submit" value="Submit">
    </form>

    <form action="http://localhost:4567/create_card" method="POST" class="form">


        <input type="text" name="title" placeholder="title" class="tit">
        <br>       
        <!-- <input type="textarea" name="description" placeholder="description" class="desc"> -->
        <textarea name="description" placeholder="description" class="desc"></textarea>
        <input type="Submit" value="Submit">
    </form>
    WRITE
    File.write(file_path,content)
    puts "File '#{file_path}' has been created successfully!"
  end

  def self.includes
    Dir.mkdir("_includes") unless Dir.exist?("_includes")
    file_path = "_includes/nav.html"
    content = <<~'NAV'
    {%if site.title%}
    <div class="navi">
      <h1 class="page-heading"><a href="/"> {{site.title}} </a></h1>
      <span class="write">
          <a href="/write">
            <span><svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
                <path stroke-linecap="round" stroke-linejoin="round" d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L10.582 16.07a4.5 4.5 0 0 1-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 0 1 1.13-1.897l8.932-8.931Zm0 0L19.5 7.125M18 14v4.75A2.25 2.25 0 0 1 15.75 21H5.25A2.25 2.25 0 0 1 3 18.75V8.25A2.25 2.25 0 0 1 5.25 6H10" />
              </svg></span>
            <span>Write</span>
        </a>
    </span>
    </div>
    {% endif %}
    NAV
    File.write(file_path,content)
    puts "File '#{file_path}' has been created successfully!"

  end
  


end

# idList = "67615173d736d1b76a1103d2"
# JekyllTrello.creator(idList)
# JekyllTrello.github
# JekyllTrello.ruby_version
# JekyllTrello.scripts
# JekyllTrello.bundle_install
# JekyllTrello.env_gitignore
