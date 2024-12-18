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

      cards = Trello::List.find("67615173d736d1b76a1103d2").cards
      cards.each do |card|
        labels = card.labels.map { |label| label.color }
        next unless labels.include?(ACCEPTED_COLOR)
        due_on = card.due&.to_date.to_s 
        slug = card.name.split.join("-").downcase
        created_on = DateTime.strptime(card.id[0..7].to_i(16).to_s, '%s').to_date.to_s
        article_date = due_on.empty? ? created_on : due_on
        content = """---
layout: post
title: #{card.name}
date: #{article_date}
permalink: #{slug}
---

        #{card.desc}
        """
        file_path = "./_posts/#{article_date}-#{slug}.md" 
        if !File.exist?(file_path) || File.read(file_path) != content
          File.open(file_path, "w+") { |f| f.write(content) }
        end  
        existing_posts.delete("#{article_date}-#{slug}.md")
      end

      existing_posts.each do |stale_post|
        file_path = "./_posts/#{stale_post}"
        File.delete(file_path) if File.exist?(file_path)
      end
    end
  end
end
