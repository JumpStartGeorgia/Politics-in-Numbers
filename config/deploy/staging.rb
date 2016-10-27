set :domain, 'alpha.jumpstart.ge'
set :user, 'pin-staging'
set :application, 'Politics-In-Numbers-Staging'
# easier to use https; if you use ssh then you have to create key on server
set :repository, 'https://github.com/JumpStartGeorgia/Politics-in-Numbers.git'
set :branch, 'embed'
set :web_url, 'dev-pin.jumpstart.ge'
set :visible_to_robots, false
set :use_ssl, true
