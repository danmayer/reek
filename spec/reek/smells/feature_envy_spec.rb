require File.dirname(__FILE__) + '/../../spec_helper.rb'

require 'reek/smells/feature_envy'
require 'spec/reek/smells/smell_detector_shared'

include Reek
include Reek::Smells

describe FeatureEnvy do
  it 'should not report use of self' do
    'def simple() self.to_s + self.to_i end'.should_not reek
  end

  it 'should not report vcall with no argument' do
    'def simple() func; end'.should_not reek
  end

  it 'should not report vcall with argument' do
    'def simple(arga) func(17); end'.should_not reek
  end

  it 'should not report single use' do
    'def no_envy(arga) arga.barg(@item) end'.should_not reek
  end

  it 'should not report return value' do
    'def no_envy(arga) arga.barg(@item); arga end'.should_not reek
  end

  it 'should report many calls to parameter' do
    'def envy(arga) arga.b(arga) + arga.c(@fred) end'.should reek_only_of(:FeatureEnvy, /arga/)
  end

  it 'should report highest affinity' do
    src = <<EOS
def total_envy
  fred = @item
  total = 0
  total += fred.price
  total += fred.tax
  total *= 1.15
end
EOS
    src.should reek_only_of(:FeatureEnvy, /total/)
  end

  it 'should report multiple affinities' do
    src = <<EOS
def total_envy
  fred = @item
  total = 0
  total += fred.price
  total += fred.tax
end
EOS
    src.should reek_of(:FeatureEnvy, /total/)
    src.should reek_of(:FeatureEnvy, /fred/)
  end

  it 'should ignore global variables' do
    'def no_envy() $s2.to_a; $s2[@item] end'.should_not reek
  end

  it 'should not report class methods' do
    'def simple() self.class.new.flatten_merge(self) end'.should_not reek
  end

  it 'should not report single use of an ivar' do
    'def no_envy() @item.to_a end'.should_not reek
  end

  it 'should not report returning an ivar' do
    'def no_envy() @item.to_a; @item end'.should_not reek
  end

  it 'should not report ivar usage in a parameter' do
    'def no_envy() @item.price + tax(@item) - savings(@item) end'.should_not reek
  end

  it 'should not be fooled by duplication' do
    'def feed(thing) @cow.feed_to(thing.pig); @duck.feed_to(thing.pig) end'.should reek_only_of(:Duplication, /thing.pig/)
  end

  it 'should count local calls' do
    'def feed(thing) cow.feed_to(thing.pig); duck.feed_to(thing.pig) end'.should reek_only_of(:Duplication, /thing.pig/)
  end

  it 'should not report single use of an lvar' do
    'def no_envy() lv = @item; lv.to_a end'.should_not reek
  end

  it 'should not report returning an lvar' do
    'def no_envy() lv = @item; lv.to_a; lv end'.should_not reek
  end

  it 'should report many calls to lvar' do
    'def envy() lv = @item; lv.price + lv.tax; end'.should reek_only_of(:FeatureEnvy, /lv/)
    #
    # def moved_version
    #   price + tax
    # end
    #
    # def envy
    #   @item.moved_version
    # end
  end

  it 'ignores lvar usage in a parameter' do
    'def no_envy() lv = @item; lv.price + tax(lv) - savings(lv); end'.should_not reek
  end

  it 'ignores multiple ivars' do
    src = <<EOS
def func
  @other.a
  @other.b
  @nother.c
  @nother.d
end
EOS
    src.should_not reek
    #
    # def other.func(me)
    #   a
    #   b
    #   me.nother_c
    #   me.nother_d
    # end
    #
  end

  it 'ignores frequent use of a call' do
    'def func() other.a; other.b; nother.c end'.should_not reek_of(:FeatureEnvy)
  end

  it 'counts self references correctly' do
    src = <<EOS
def adopt!(other)
  other.keys.each do |key|
    self[key] += 3
    self[key] = o4
  end
  self
end
EOS
    src.should_not reek
  end
end

describe FeatureEnvy do
  it 'counts references to self correctly' do
    ruby = <<EOS
def report
  unless @report
    @report = Report.new
    cf = SmellConfig.new
    cf = cf.load_local(@dir) if @dir
    CodeParser.new(@report, cf.smell_listeners).check_source(@source)
  end
  @report
end
EOS
    ruby.should_not reek
  end

  it 'interprets << correctly' do
    ruby = <<EOS
def report_on(report)
  if @is_masked
    report.record_masked_smell(self)
  else
    report << self
  end
end
EOS

    ruby.should_not reek
  end
end

describe FeatureEnvy do
  before(:each) do
    @detector = FeatureEnvy.new
  end

  it_should_behave_like 'SmellDetector'
end
