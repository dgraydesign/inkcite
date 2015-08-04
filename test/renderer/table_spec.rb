require 'minitest/spec'
require 'minitest/autorun'
require 'inkcite'

describe Inkcite::Renderer::Table do

  before do
    @view = Inkcite::Email.new('test/project/').view(:development, :email)
  end

  it 'defaults border, cellpadding and cellspacing to zero' do
    Inkcite::Renderer.render('{table}{/table}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0><tr></tr></table>')
  end

  it 'supports custom margins in px' do
    Inkcite::Renderer.render('{table margin-top=15}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0 style="margin-top:15px"><tr>')
    Inkcite::Renderer.render('{table margin-left=16}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0 style="margin-left:16px"><tr>')
    Inkcite::Renderer.render('{table margin-bottom=17}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0 style="margin-bottom:17px"><tr>')
    Inkcite::Renderer.render('{table margin-right=18}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0 style="margin-right:18px"><tr>')
  end

  it 'supports multiple custom margins in px' do
    Inkcite::Renderer.render('{table margin-top=15 margin-left=6}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0 style="margin-left:6px;margin-top:15px"><tr>')
  end

  it 'supports a single all margin attribute' do
    Inkcite::Renderer.render('{table margin=15}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0 style="margin-bottom:15px;margin-left:15px;margin-right:15px;margin-top:15px"><tr>')
  end

  it 'supports unified margins with directional override' do
    Inkcite::Renderer.render('{table margin=15 margin-left=8}', @view).must_equal('<table border=0 cellpadding=0 cellspacing=0 style="margin-bottom:15px;margin-left:8px;margin-right:15px;margin-top:15px"><tr>')
  end

end