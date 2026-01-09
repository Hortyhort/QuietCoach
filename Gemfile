# QuietCoach Gemfile
# Ruby dependencies for Fastlane

source "https://rubygems.org"

# Fastlane for CI/CD automation
gem "fastlane", "~> 2.219"

# Code coverage reporting
gem "xcov", "~> 1.8"

# Plugins
plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
