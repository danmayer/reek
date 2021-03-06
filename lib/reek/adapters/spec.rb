require 'reek/sniffer'
require 'reek/adapters/core_extras'
require 'reek/adapters/report'

module Reek

  #
  # Provides matchers for Rspec, making it easy to check code quality.
  #
  # If you require this module somewhere within your spec (or in your spec_helper),
  # Reek will arrange to update Spec::Runner's config so that it knows about the
  # matchers defined here.
  #
  # === Examples
  #
  # Here's a spec that ensures there are no smell warnings in the current project:
  #
  #  describe 'source code quality' do
  #    Dir['lib/**/*.rb'].each do |path|
  #      it "reports no smells in #{path}" do
  #        File.new(path).should_not reek
  #      end
  #    end
  #  end
  #
  # And here's an even simpler way to do the same:
  #
  #  it 'has no code smells' do
  #    Dir['lib/**/*.rb'].should_not reek
  #  end
  #
  # Here's a simple check of a code fragment:
  #
  #  'def equals(other) other.thing == self.thing end'.should_not reek
  #
  # And a more complex example, making use of one of the factory methods for
  # +Source+ so that the code is parsed and analysed only once:
  # 
  #   ruby = 'def double_thing() @other.thing.foo + @other.thing.foo end'.sniff
  #   ruby.should reek_of(:Duplication, /@other.thing[^\.]/)
  #   ruby.should reek_of(:Duplication, /@other.thing.foo/)
  #   ruby.should_not reek_of(:FeatureEnvy)
  #
  module Spec
    module ReekMatcher
      def create_reporter(sniffers)
        QuietReport.new(sniffers, false)
      end
      def report
        create_reporter(@sniffer.sniffers).report
      end

      module_function :create_reporter
    end

    class ShouldReek        # :nodoc:
      include ReekMatcher

      def matches?(actual)
        @sniffer = actual.sniff
        @sniffer.smelly?
      end
      def failure_message_for_should
        "Expected #{@sniffer.desc} to reek, but it didn't"
      end
      def failure_message_for_should_not
        "Expected no smells, but got:\n#{report}"
      end
    end

    class ShouldReekOf        # :nodoc:
      include ReekMatcher

      def initialize(klass, patterns)
        @klass = klass
        @patterns = patterns
      end
      def matches?(actual)
        @sniffer = actual.sniff
        @sniffer.has_smell?(@klass, @patterns)
      end
      def failure_message_for_should
        "Expected #{@sniffer.desc} to reek of #{@klass}, but it didn't"
      end
      def failure_message_for_should_not
        "Expected #{@sniffer.desc} not to reek of #{@klass}, but got:\n#{report}"
      end
    end

    class ShouldReekOnlyOf < ShouldReekOf        # :nodoc:
      def matches?(actual)
        @sniffer = actual.sniff
        @sniffer.num_smells == 1 and @sniffer.has_smell?(@klass, @patterns)
      end
      def failure_message_for_should
        "Expected #{@sniffer.desc} to reek only of #{@klass}, but got:\n#{report}"
      end
      def failure_message_for_should_not
        "Expected #{@sniffer.desc} not to reek only of #{@klass}, but it did"
      end
    end

    #
    # Returns +true+ if and only if the target source code contains smells.
    #
    def reek
      ShouldReek.new
    end

    #
    # Checks the target source code for instances of +smell_class+,
    # and returns +true+ only if one of them has a report string matching
    # all of the +patterns+.
    #
    def reek_of(smell_class, *patterns)
      ShouldReekOf.new(smell_class, patterns)
    end

    #
    # As for reek_of, but the matched smell warning must be the only warning of
    # any kind in the target source code's Reek report.
    #
    def reek_only_of(smell_class, *patterns)
      ShouldReekOnlyOf.new(smell_class, patterns)
    end
  end
end

if Object.const_defined?(:Spec)
  Spec::Runner.configure do |config|
    config.include(Reek::Spec)
  end
end
