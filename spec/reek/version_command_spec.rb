require File.dirname(__FILE__) + '/../spec_helper.rb'

require 'reek/version_command'

include Reek

describe VersionCommand do
  before :each do
    @text = 'Piece of interesting text'
    @cmd = VersionCommand.new(@text)
    @view = mock('view', :null_object => true)
    @view.should_not_receive(:report_smells)
  end

  it 'displays the text on the view' do
    @view.should_receive(:output).with(/#{@text}/)
    @cmd.execute(@view)
  end

  it 'displays the Reek version on the view' do
    @view.should_receive(:output).with(/#{Reek::VERSION}/)
    @cmd.execute(@view)
  end

  it 'tells the view it succeeded' do
    @view.should_receive(:report_success)
    @cmd.execute(@view)
  end
end
