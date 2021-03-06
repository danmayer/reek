require 'sexp'
require 'reek/block_context'
require 'reek/class_context'
require 'reek/module_context'
require 'reek/stop_context'
require 'reek/if_context'
require 'reek/method_context'
require 'reek/singleton_method_context'
require 'reek/yield_call_context'

module Reek
  #
  # Traverses a Sexp abstract syntax tree and fires events whenever
  # it encounters specific node types.
  #
  class CodeParser
    def initialize(sniffer, ctx = StopContext.new)
      @sniffer = sniffer
      @element = ctx
    end

    def process(exp)
      meth = "process_#{exp[0]}"
      meth = :process_default unless self.respond_to?(meth)
      self.send(meth, exp)
      @element
    end

    def process_default(exp)
      exp[0..-1].each { |sub| process(sub) if Array === sub }
    end

    def do_module_or_class(exp, context_class)
      scope = context_class.create(@element, exp)
      push(scope) do
        process_default(exp) unless @element.is_struct?
        check_smells(exp[0])
      end
      scope
    end

    def process_module(exp)
      do_module_or_class(exp, ModuleContext)
    end

    def process_class(exp)
      do_module_or_class(exp, ClassContext)
    end

    def process_defn(exp)
      handle_context(MethodContext, exp[0], exp)
    end

    def process_defs(exp)
      handle_context(SingletonMethodContext, exp[0], exp)
    end

    def process_args(exp) end

    def process_attrset(exp)
      @element.record_depends_on_self if /^@/ === exp[1].to_s
    end

    def process_zsuper(exp)
      @element.record_use_of_self
    end

    def process_lit(exp)
      val = exp[1]
      @element.record_depends_on_self if val == :self
    end

    def process_iter(exp)
      process(exp[1])
      scope = BlockContext.new(@element, exp)
      push(scope) do
        process_default(exp[2..-1])
        check_smells(exp[0])
      end
      scope
    end

    def process_block(exp)
      @element.count_statements(CodeParser.count_statements(exp))
      process_default(exp)
    end

    def process_yield(exp)
      handle_context(YieldCallContext, exp[0], exp)
    end

    def process_call(exp)
      @element.record_call_to(exp)
      process_default(exp)
    end

    def process_cfunc(exp)
      @element.record_depends_on_self
    end

    def process_attrasgn(exp)
      process_call(exp)
    end

    def process_op_asgn1(exp)
      process_call(exp)
    end

    def process_if(exp)
      count_clause(exp[2])
      count_clause(exp[3])
      handle_context(IfContext, exp[0], exp)
      @element.count_statements(-1)
    end

    def process_while(exp)
      process_until(exp)
    end

    def process_until(exp)
      count_clause(exp[2])
      process_case(exp)
    end

    def process_for(exp)
      count_clause(exp[3])
      process_case(exp)
    end

    def process_rescue(exp)
      count_clause(exp[1])
      process_case(exp)
    end

    def process_resbody(exp)
      process_when(exp)
    end

    def process_case(exp)
      process_default(exp)
      @element.count_statements(-1)
    end

    def process_when(exp)
      count_clause(exp[2])
      process_default(exp)
    end

    def process_ivar(exp)
      process_iasgn(exp)
    end

    def process_lasgn(exp)
      @element.record_local_variable(exp[1])
      process_default(exp)
    end

    def process_iasgn(exp)
      @element.record_instance_variable(exp[1])
      @element.record_depends_on_self
      process_default(exp)
    end

    def process_self(exp)
      @element.record_use_of_self
    end

    def count_clause(sexp)
      if sexp and !sexp.has_type?(:block)
        @element.count_statements(1)
      end
    end

    def self.count_statements(exp)
      stmts = exp[1..-1]
      ignore = 0
      ignore += 1 if stmts[1] == s(:nil)
      stmts.length - ignore
    end

  private

    def handle_context(klass, type, exp)
      scope = klass.new(@element, exp)
      push(scope) do
        process_default(exp)
        check_smells(type)
      end
      scope
    end

    def check_smells(type)
      @sniffer.examine(@element, type)
    end

    def push(context)
      orig = @element
      @element = context
      yield
      @element = orig
    end
  end
end
