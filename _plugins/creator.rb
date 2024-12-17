require 'dotenv/load'
require 'trello'
# require 'pry'
module Jekyll
  class ContentCreatorGenerator < Generator
    safe true
    # ACCEPTED_COLOR = "green"

    def setup
      @trello_api_key = ENV['TRELLO_API_KEY']
      @trello_token = ENV['TRELLO_TOKEN']

      
      Trello.configure do |config|
        config.developer_public_key = @trello_api_key
        config.member_token = @trello_token
      end
    end
    # def board(site)
    #   setup

    # end
    def generate(site)
      setup
      
      cards = Trello::List.find("67615173d736d1b76a1103d2").cards
      cards.each do |card|
        # binding.pry
        # labels = card.labels.map { |label| label.color}
        # next unless labels.include?("green")
        due_on = card.due&.to_date.to_s 
        slug = card.name.split.join("-").downcase
        created_on = DateTime.strptime(card.id[0..7].to_i(16).to_s, '%s').to_date.to_s
        article_date = due_on.empty? ? created_on : due_on
        content = """---
layout: card
title: #{card.name}
date: #{article_date}
category: #{card.labels[0].name}
---

#{card.desc}
        """
        file_path= "./_posts/#{article_date}-#{slug}.md"
        if !File.exist?(file_path) || File.read(file_path) != content
          file = File.open(file_path, "w+") {|f| f.write(content) }
        end
        # binding.pry
#         unless File.exist?("./#{card.labels[0].name}.md")
#           content_cat = """---
# layout: card
# permalink: /#{card.labels[0].name}/
# ---
# {%include flashcards.html%}
# """
#           file=File.open("./#{card.labels[0].name}.md","w+"){|f| f.write(content_cat)}
#         end
      end
    end
  end
end


