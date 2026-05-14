require 'rake/testtask'



Rake::TestTask.new do |t|
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  # Attempt to clean up warning spam from ftr_ruby related gems.
  t.warning = false
  puts "Running tests with warnings disabled..."
end


task default: :test

