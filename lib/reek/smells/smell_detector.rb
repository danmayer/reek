require 'reek/configuration'

module Reek
  module Smells

    module ExcludeInitialize
      def self.default_config
        super.adopt(EXCLUDE_KEY => ['initialize'])
      end
      def initialize(config = self.class.default_config)
        super
      end
    end

    class SmellDetector

      # The name of the config field that lists the names of code contexts
      # that should not be checked. Add this field to the config for each
      # smell that should ignore this code element.
      EXCLUDE_KEY = 'exclude'

      # The default value for the +EXCLUDE_KEY+ if it isn't specified
      # in any configuration file.
      DEFAULT_EXCLUDE_SET = []

      class << self
        def contexts      # :nodoc:
          [:defn, :defs]
        end

        def default_config
          {
            SmellConfiguration::ENABLED_KEY => true,
            EXCLUDE_KEY => DEFAULT_EXCLUDE_SET
          }
        end
      end

      def initialize(config = self.class.default_config)
        @config = SmellConfiguration.new(config)
        @smells_found = Set.new
        @masked = false
      end

      def listen_to(hooks)
        self.class.contexts.each { |ctx| hooks[ctx] << self }
      end

      # SMELL: Getter (only used in 1 test)
      def enabled?
        @config.enabled?
      end

      def configure(config)
        my_part = config[self.class.name.split(/::/)[-1]]
        return unless my_part
        configure_with(my_part)
      end

      def configure_with(config)
        @config.adopt!(config)
      end

      def copy
        self.class.new(@config.deep_copy)
      end

      def supersede_with(config)
        clone = self.copy
        @masked = true
        clone.configure_with(config)
        clone
      end

      def examine(context)
        examine_context(context) if @config.enabled? and !exception?(context)
      end

      def examine_context(context)
      end

      def exception?(context)
        context.matches?(value(EXCLUDE_KEY, context, DEFAULT_EXCLUDE_SET))
      end

      def found(context, message)
        smell = SmellWarning.new(self, context.full_name, context.exp.line, message, @masked)
        @smells_found << smell
        smell
      end

      def has_smell?(patterns)
        return false if @masked
        @smells_found.each { |warning| return true if warning.contains_all?(patterns) }
        false
      end

      def smell_type
        self.class.name.split(/::/)[-1]
      end

      def report_on(report)
        @smells_found.each { |smell| smell.report_on(report) }
      end

      def num_smells
        @masked ? 0 : @smells_found.length
      end

      def smelly?
        (not @masked) and (@smells_found.length > 0)
      end

      def value(key, ctx, fall_back)
        @config.value(key, ctx, fall_back)
      end
    end
  end
end
