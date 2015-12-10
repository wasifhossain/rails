require "active_support/core_ext/class/attribute"
require "minitest"

module Rails
  class TestUnitReporter < Minitest::StatisticsReporter
    class_attribute :executable
    self.executable = "bin/rails test"

    def record(result)
      super

      if output_inline? && result.failure && (!result.skipped? || options[:verbose])
        io.puts
        io.puts
        io.puts result.failures.map(&:message)
        io.puts
        io.puts format_rerun_snippet(result)
        io.puts
      end

      if fail_fast? && result.failure && !result.error? && !result.skipped?
        raise Interrupt
      end
    end

    def report
      return if output_inline? || filtered_results.empty?
      io.puts
      io.puts "Failed tests:"
      io.puts
      io.puts aggregated_results
    end

    def aggregated_results # :nodoc:
      filtered_results.map { |result| format_rerun_snippet(result) }.join "\n"
    end

    def filtered_results
      if options[:verbose]
        results
      else
        results.reject(&:skipped?)
      end
    end

    def relative_path_for(file)
      file.sub(/^#{app_root}\/?/, '')
    end

    private
      def output_inline?
        options[:output_inline]
      end

      def fail_fast?
        options[:fail_fast]
      end

      def format_rerun_snippet(result)
        # Try to extract path to assertion from backtrace.
        if result.location =~ /\[(.*)\]\z/
          assertion_path = $1
        else
          assertion_path = result.method(result.name).source_location.join(':')
        end

        "#{self.executable} #{relative_path_for(assertion_path)}"
      end

      def app_root
        @app_root ||= defined?(ENGINE_ROOT) ? ENGINE_ROOT : Rails.root
      end
  end
end
