Gem::Specification.new do |s|
  s.name        = 'trello'
  s.version     = '0.1.8'
  s.executables = ["trello"]

  s.description     = "This is will help you setup your jekyll website in github and take data from trello automatically once a day if label is set to green.
  .....put your github repo name inside baseurl:'/your_repo_name' in _config.yml......put secret in secrets and vairable in github like this
  name=DOT_ENV........Secret='TRELLO_API_KEY=66afksdlf994d36591bd41a9f82c4b927
TRELLO_TOKEN=ATTA63d96531e13dc90ca874c17efasdfdsfbd9fb7700e4699816FCFEBA51
'
and you have to set.........workflow permissions to read and write permission.........inside action>general......you can use this gem like this...'jekyll_terllo --897lfkdjsjfklsdj'........idList of your card of trello........Extract the trello cards details and show it in your trello website also automatically runs daily if hosted on github

  "
  s.summary = "Extract the trello cards details and show it in your trello website also automatically runs daily if hosted on github"
  s.authors     = ["Habi Coder"]
  s.email       = 'unionhab@gmail.com'
  s.files       = ["lib/trello.rb","bin/trello"]
  s.homepage    = "https://github.com/Habi-Pyatha"
  s.metadata    = { "source_code_uri" => "https://github.com/Habi-Pyatha/jekyll_trello" }
end