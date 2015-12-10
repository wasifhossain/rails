require 'generators/plugin_test_helper'

class TestRunnerInEngineTest < ActiveSupport::TestCase
  include PluginTestHelper

  def setup
    @destination_root = Dir.mktmpdir('bukkits')
    Dir.chdir(@destination_root) { `bundle exec rails plugin new bukkits --full --skip-bundle` }
    plugin_file 'test/dummy/db/schema.rb', ''
  end

  def teardown
    FileUtils.rm_rf(@destination_root)
  end

  def test_rerun_snippet_is_relative_path
    create_test_file 'post', pass: false

    output = run_test_command('test/post_test.rb')
    assert_match %r{Running:\n\nPostTest\nF\n\nwups!\n\nbin/rails test test/post_test.rb:6}, output
  end

  private
    def run_test_command(arguments)
      Dir.chdir(plugin_path) { `bin/rails test #{arguments}` }
    end
end
