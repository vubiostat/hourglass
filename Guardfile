guard 'test' do
  watch(%r{^lib/(?:hourglass/)?([^/]+/)*([^/]+)\.rb$}) { |m| "test/unit/#{m[1]}test_#{m[2]}.rb" }
  watch(%r{^test/unit/([^/]+/)*test_.+\.rb$})
  watch(%r{^test/integration/test_.+\.rb$})
  watch('test/helper.rb')  { "test" }
end
