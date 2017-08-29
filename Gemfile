source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# general Ruby/Rails gems
# gives us Settings to manage configs on different instances
gem 'config'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# use postgres as the database
gem 'pg'
# useful for debugging, even in prod
gem 'pry-byebug' # Adds step-by-step debugging and stack navigation capabilities to pry using byebug
gem 'pry-rails' # use pry as the rails console shell instead of IRB
# Use Puma as the app server
gem 'puma', '~> 3.7'
gem 'rails', '~> 5.1.3'

# Stanford/Samvera gems
# work with Moab Objects
gem 'moab-versioning'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri]
  # Call 'binding.pry' anywhere in the code to stop execution and get a pry console
  gem 'rspec-rails', '~> 3.6'
  gem 'rails-controller-testing'
  gem 'coveralls'
  # Ruby static code analyzer http://rubocop.readthedocs.io/en/latest/
  gem 'rubocop', '~> 0.49.1', require: false # avoid code churn due to rubocop changes
  gem 'rubocop-rspec'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  # gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  gem 'shoulda-matchers', git: 'https://github.com/thoughtbot/shoulda-matchers.git', branch: 'rails-5'
end

group :deploy do
  gem 'capistrano-rails'
  gem 'capistrano-passenger'
  gem 'dlss-capistrano'
end
