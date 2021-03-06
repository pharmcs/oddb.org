#!/usr/bin/env ruby
# encoding: utf-8
# ODDB::State::Admin::TestSponsor- oddb.org -- 06.07.2011 -- mhatakeyama@ywesee.com

$: << File.expand_path("../../../src", File.dirname(__FILE__))


require 'minitest/autorun'
require 'flexmock/minitest'
require 'state/admin/sponsor'
require 'fileutils'
require 'tempfile'

module ODDB
	module State
		module Admin

class TestSponsor <Minitest::Test
  @@tempfile = Tempfile.new('admin') {|f|f.write('some_content') }
  def setup
    company  = flexmock('company', :pointer => 'pointer')
    @app     = flexmock('app', :company_by_name => company)
    @lnf     = flexmock('lookandfeel', :lookup => 'lookup')
    flexmock(File) do |file|
      file.should_receive(:exist?).and_return(true)
      file.should_receive(:delete)
      file.should_receive(:open).and_yield('')
    end
    @io = flexmock('io', :[] => @@tempfile)

    user_input = {:company_name => 'company_name', :logo_file => @io}
    @session = flexmock('session', 
                        :lookandfeel => @lnf,
                        :user_input  => user_input,
                        :app         => @app,
                        :flavor      => 'flavor'
                       )
    @model   = flexmock('model', 
                        :pointer => 'pointer',
                        :logo_filenames => {:default => 'default'}
                       )
    model = flexmock('model2', :logo_filenames => {})
    flexmock(@app, :update => model)
    @state   = ODDB::State::Admin::Sponsor.new(@session, @model)
    flexmock(@state, :unique_email => 'unique_email')
  end
  def test_update__company
    assert_equal(@state, @state.update)
  end
  def test_update__empty_name
    flexmock(@session, :user_input => {:company_name => ''})
    assert_equal(@state, @state.update)
  end
  def test_update__else
    flexmock(@app, :company_by_name => nil)
    assert_equal(@state, @state.update)
  end
  def test_update__logo
    flexmock(@session, 
             :user_input => {
                :company_name => 'company_name', 
                :logo_file    => @io, 
                :logo_fr      => @io
              }
            )
    assert_equal(@state, @state.update)
  end
  def test_store_logo
    @io = flexmock('io', :[] => @@tempfile)
    skip('Niklaus does not now howto to mock correctlythe File.open')
    assert_equal("flavor_key_original_filename", @state.store_logo(@io, 'key', 'oldname'))
  end
end

		end # Admin
	end # State
end # ODDB
