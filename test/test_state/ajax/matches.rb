#!/usr/bin/env ruby
# ODDB::State::Ajax::TestMatches -- oddb.org -- 05.07.2011 -- mhatakeyama@ywesee.com

$: << File.expand_path("../../../src", File.dirname(__FILE__))

require 'test/unit'
require 'flexmock'
require 'odba'
require 'sbsm/state'
require 'state/ajax/matches'

module ODDB
  module State
    module Ajax

class TestMatches < Test::Unit::TestCase
  include FlexMock::TestCase
  def setup
    @lnf     = flexmock('lookandfeel', :lookup => 'lookup')
    @session = flexmock('session', 
                        :lookandfeel => @lnf,
                        :user_input  => 'term'
                       )
    @model   = flexmock('model')
    @state   = ODDB::State::Ajax::Matches.new(@session, @model)
  end
  def test_init
    flexmock(ODBA.cache, :index_matches => ['term'])
    expected = [{:search_query => "term"}]
    assert_equal(expected, @state.init)
  end
end

    end # Ajax
  end # State
end # ODDB