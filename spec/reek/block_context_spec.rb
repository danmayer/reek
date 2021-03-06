require File.dirname(__FILE__) + '/../spec_helper.rb'

require 'reek/block_context'
require 'reek/method_context'

include Reek

describe BlockContext do

  it "should record single parameter" do
    element = StopContext.new
    element = BlockContext.new(element, s(:iter, nil, s(:lasgn, :x), nil))
    element.variable_names.should == [Name.new(:x)]
  end

  it "should record single parameter within a method" do
    element = StopContext.new
    element = MethodContext.new(element, s(:defn, :help))
    element = BlockContext.new(element, s(:iter, nil, s(:lasgn, :x), nil))
    element.variable_names.should == [Name.new(:x)]
  end

  it "records multiple parameters" do
    element = StopContext.new
    element = BlockContext.new(element, s(:iter, nil, s(:masgn, s(:array, s(:lasgn, :x), s(:lasgn, :y))), nil))
    element.variable_names.should == [Name.new(:x), Name.new(:y)]
  end

  it "should not pass parameters upward" do
    mc = MethodContext.new(StopContext.new, s(:defn, :help, s(:args)))
    element = BlockContext.new(mc, s(:iter, nil, s(:lasgn, :x)))
    mc.variable_names.should be_empty
  end

  it 'records local variables' do
    bctx = BlockContext.new(StopContext.new, s(nil, nil))
    bctx.record_local_variable(:q2)
    bctx.variable_names.should include(Name.new(:q2))
  end

  it 'copes with a yield to an ivar' do
    scope = BlockContext.new(StopContext.new, s(:iter, nil, s(:iasgn, :@list), s(:self)))
    scope.record_instance_variable(:@list)
    scope.variable_names.should == [:@list]
  end

  context 'full_name' do
    it "reports full context" do
      bctx = BlockContext.new(StopContext.new, s(nil, nil))
      bctx.full_name.should == 'block'
    end
    it 'uses / to connect to the class name' do
      element = StopContext.new
      element = ClassContext.new(element, :Fred, s(:class, :Fred))
      element = BlockContext.new(element, s(:iter, nil, s(:lasgn, :x), nil))
      element.full_name.should == 'Fred/block'
    end
    it 'uses / to connect to the module name' do
      element = StopContext.new
      element = ModuleContext.new(element, :Fred, s(:module, :Fred))
      element = BlockContext.new(element, s(:iter, nil, s(:lasgn, :x), nil))
      element.full_name.should == 'Fred/block'
    end
  end
end
