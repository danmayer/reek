require 'ruby_parser'

module Reek
  class Name
    include Comparable

    def self.resolve(exp, context)
      unless Array === exp
        return resolve_string(exp.to_s, context)
      end
      name = exp[1]
      case exp[0]
      when :colon2
        return [resolve(name, context)[0], new(exp[2])]
      when :const
        return [ModuleContext.create(context, exp), new(name)]
      when :colon3
        return [StopContext.new, new(name)]
      else
        return [context, new(name)]
      end
    end

    def self.resolve_string(str, context)
      return [context, new(str)] unless str =~ /::/
      resolve(RubyParser.new.parse(str), context)
    end

    def initialize(sym)
      @name = sym.to_s
    end

    def hash  # :nodoc:
      @name.hash
    end

    def eql?(other)
      self == other
    end

    def <=>(other)  # :nodoc:
      @name <=> other.to_s
    end

    def effective_name
      @name.gsub(/^@*/, '')
    end

    def inspect
      @name.inspect
    end

    def to_s
      @name
    end
  end
end
