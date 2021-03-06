require File.dirname(__FILE__) + '/../../spec_helper.rb'

require 'reek/smells/nested_iterators'

include Reek::Smells

describe NestedIterators do

  it 'should report nested iterators in a method' do
    'def bad(fred) @fred.each {|item| item.each {|ting| ting.ting} } end'.should reek_only_of(:NestedIterators)
  end

  it 'should not report method with successive iterators' do
    src = <<EOS
def bad(fred)
  @fred.each {|item| item.each }
  @jim.each {|ting| ting.each }
end
EOS
    src.should_not reek
  end

  it 'should not report method with chained iterators' do
    src = <<EOS
def chained
  @sig.keys.sort_by { |xray| xray.to_s }.each { |min| md5 << min.to_s }
end
EOS
    src.should_not reek
  end

  it 'should report nested iterators only once per method' do
    src = <<EOS
def bad(fred)
  @fred.each {|item| item.each {|part| @joe.send} }
  @jim.each {|ting| ting.each {|piece| @hal.send} }
end
EOS
    src.should reek_only_of(:NestedIterators)
  end
end

require 'spec/reek/smells/smell_detector_shared'

describe NestedIterators do
  before(:each) do
    @detector = NestedIterators.new
  end

  it_should_behave_like 'SmellDetector'
end
