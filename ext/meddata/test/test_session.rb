#!/usr/bin/env ruby
# ODDB::MedData::TestSession -- 14.04.2011 -- mhatakeyama@ywesee.com

$: << File.expand_path('../..', File.dirname(__FILE__))


require 'minitest/autorun'
require 'flexmock/minitest'
require 'meddata/src/session'

module ODDB
  module MedData
    class StubSession < Session
      def get(arg)
        raise Timeout::Error.new('timeout error')
      end
    end
  end
end

module ODDB
  module MedData
    class TestSession <Minitest::Test
      def setup
        @response = flexmock('response') do |r|
          r.should_receive(:[]).with('set-cookie').and_return('cookie_header')
          r.should_receive(:body).and_return('body')
        end
        @http = flexmock('http', :get => @response) 
        flexmock(Net::HTTP, :new => @http)
        @http_server = flexmock('http_server')
        ODDB::MedData::Session::HTTP_PATHS.store  :search_type_test, 'http_path'
        ODDB::MedData::Session::FORM_KEYS.store   :search_type_test, [ [:name, 'txtSearchName'] ]
        ODDB::MedData::Session::DETAIL_KEYS.store :search_type_test, 'detail_key'

        @session = ODDB::MedData::Session.new(:search_type_test, @http_server)
      end
      def test_initialize__timeout_error
        @response = flexmock('response') do |r|
          r.should_receive(:[]).with('set-cookie').and_return('cookie_header')
          r.should_receive(:body).and_return('body')
        end
        @http = flexmock('http', :get => @response) 
        flexmock(Net::HTTP, :new => @http)
        @http_server = flexmock('http_server')
        ODDB::MedData::Session::HTTP_PATHS.store  :search_type_test, 'http_path'
        ODDB::MedData::Session::FORM_KEYS.store   :search_type_test, [ [:name, 'txtSearchName'] ]
        ODDB::MedData::Session::DETAIL_KEYS.store :search_type_test, 'detail_key'

        assert_raises(Timeout::Error) do 
          ODDB::MedData::StubSession.new(:search_type_test, @http_server)
        end
      end
      def test_handle_resp
        assert_nil(@session.handle_resp!(@response))
      end
      def test_post_hash
        criteria = {}
        expected = [
          ["__EVENTTARGET", ""],
          ["__EVENTARGUMENT", ""],
          ["btnSearch", "Suche"],
          ["hiddenlang", "de"]
        ]
        assert_equal(expected, @session.post_hash(criteria))
      end
      def test_post_hash__ctl
        criteria = {}
        expected = [
          ["__EVENTTARGET", "detail_key$ctl$ctl00"],
          ["__EVENTARGUMENT", ""],
          ["hiddenlang", "de"]
        ]
        assert_equal(expected, @session.post_hash(criteria, 'ctl'))
      end
      def test_post_hash__viewstate
        flexmock(@response, :body => 'VIEWSTATE value="viewstate"')
        @session.handle_resp!(@response)
        criteria = {}
        expected = [
          ["__EVENTTARGET", ""],
          ["__EVENTARGUMENT", ""],
          ["btnSearch", "Suche"],
          ["hiddenlang", "de"],
        ]
        assert_equal(expected, @session.post_hash(criteria))
      end
      def test_post_hash__eventvalidation
        flexmock(@response, :body => 'EVENTVALIDATION value="eventvalidation"')
        @session.handle_resp!(@response)
        criteria = {}
        expected = [
          ["__EVENTTARGET", ""],
          ["__EVENTARGUMENT", ""],
          ["btnSearch", "Suche"],
          ["hiddenlang", "de"]
        ]
        assert_equal(expected, @session.post_hash(criteria))
      end
      def test_post_hash__criteria_key
        criteria = {:name => 'value'}
        expected = [
          ["__EVENTTARGET", ""],
          ["__EVENTARGUMENT", ""],
          ["btnSearch", "Suche"],
          ["txtSearchName", "value"],
          ["hiddenlang", "de"]
        ]
        assert_equal(expected, @session.post_hash(criteria))
      end
      def test_post_header
        expected = [
          ["Host", @http_server],
          ["User-Agent",
           "Mozilla/5.0 (X11; Linux x86_64; rv:20.0) Gecko/20100101 Firefox/20.0"],
          ["Accept",
           "text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,video/x-mng,image/png,image/jpeg,image/gif;q=0.2,*/*;q=0.1"],
          ["Accept-Encoding", "gzip, deflate"],
          ["Accept-Language", "de-ch,en-us;q=0.7,en;q=0.3"],
          ["Accept-Charset", "UTF-8"],
          ["Keep-Alive", "300"],
          ["Connection", "keep-alive"],
          ["Content-Type", "application/x-www-form-urlencoded"],
          ["Referer", ""],
          ["Cookie", "cookie_header"],
        ]
        assert_equal(expected, @session.post_headers)
      end
      def stderr_null
        require 'tempfile'
        $stderr = Tempfile.open('stderr')
        yield
        $stderr.close
        $stderr = STDERR
      end
      def test_get_result_list
        criteria = {}
        response = Net::HTTPFound.new(1,2,3)
        flexmock(@http, 
                 :post => response, 
                 :get  => @response
                )
        uri = flexmock('uri', :request_uri => 'request_uri')
        flexmock(URI, :parse => uri)
        stderr_null do 
          assert_equal('body', @session.get_result_list(criteria))
        end
      end
      def test_detail_html
        response = Net::HTTPFound.new(1,2,3)
        flexmock(@http, 
                 :post => response, 
                 :get  => @response
                )
        uri = flexmock('uri', :request_uri => 'request_uri')
        flexmock(URI, :parse => uri)
        stderr_null do 
          assert_equal('body', @session.detail_html(nil))
        end
      end
    end
    
    class TestSessionException <Minitest::Test
      
      def stdout_null
        require 'tempfile'
        $stdout = Tempfile.open('stdout')
        yield
        $stdout.close
        $stdout = STDOUT
      end

      def stderr_null
        require 'tempfile'
        $stderr = Tempfile.open('stderr')
        yield
        $stderr.close
        $stderr = STDERR
      end
      
      def setup_to_raise_error
        response = Net::HTTPFound.new(1,2,3)
        @response = flexmock('response') do |r|
          r.should_receive(:[]).with('set-cookie').and_return('cookie_header')
          r.should_receive(:body).once.and_return('body')
        end
        @http = flexmock('http', 
                 :post => response,
                 :get  => @response) 
        flexmock(Net::HTTP, :new => @http)
        @http_server = flexmock('http_server')
        ODDB::MedData::Session::HTTP_PATHS.store  :search_type_test, 'http_path'
        ODDB::MedData::Session::FORM_KEYS.store   :search_type_test, [ [:name, 'txtSearchName'] ]
        ODDB::MedData::Session::DETAIL_KEYS.store :search_type_test, 'detail_key'
        uri = flexmock('uri', :request_uri => 'request_uri')
        flexmock(URI, :parse => uri)
        flexmock(@session, 
                 :sleep => nil,
                 :flexmock_original_behavior_for_should_receive => nil
                )
      end
      
      def test_get_result_list__errno_enetunreach
        setup_to_raise_error
        criteria = {}
        stderr_null do 
          assert_raises(Errno::ENETUNREACH) do 
            @session = ODDB::MedData::Session.new(:search_type_test, @http_server)
            @response.should_receive(:body).and_raise(Errno::ENETUNREACH)
            @session.get_result_list(criteria)
          end
        end
      end 
      
      def test_get_result_list__runtime_error
        setup_to_raise_error
        criteria = {}
        flexmock(@session, 
                 :sleep => nil,
                 :flexmock_original_behavior_for_should_receive => nil
                )
        stderr_null do 
          assert_raises(RuntimeError) do 
            @session = ODDB::MedData::Session.new(:search_type_test, @http_server)
            @response.should_receive(:body).and_raise(RuntimeError)
            @session.get_result_list(criteria)
          end
        end
      end
      
      def test_detail_html__errno__econnreset
        setup_to_raise_error
        stderr_null do 
          assert_raises(Errno::ECONNRESET) do 
            @session = ODDB::MedData::Session.new(:search_type_test, @http_server)
            @response.should_receive(:body).and_raise(Errno::ECONNRESET)
            @session.detail_html('detail')
          end
        end
      end
      
      def test_get_result_list__internal_server_error
        criteria = {}
        @response = flexmock('response') do |r|
          r.should_receive(:[]).with('set-cookie').and_return('cookie_header')
          r.should_receive(:body).times(1).and_return('body')
        end
        response = Net::HTTPFound.new(1,2,3) 
        @http = flexmock(@http, 
                 :post => response, 
                 :get  => @response
                )
        flexmock(Net::HTTP, :new => @http)
        @http_server = flexmock('http_server')
        ODDB::MedData::Session::HTTP_PATHS.store  :search_type_test, 'http_path'
        ODDB::MedData::Session::FORM_KEYS.store   :search_type_test, [ [:name, 'txtSearchName'] ]
        ODDB::MedData::Session::DETAIL_KEYS.store :search_type_test, 'detail_key'
        uri = flexmock('uri', :request_uri => 'request_uri')
        flexmock(URI, :parse => uri)
        @session = ODDB::MedData::Session.new(:search_type_test, @http_server)
        stderr_null{stdout_null{
          assert_raises(RuntimeError) do 
            @response.should_receive(:body).and_raise(RuntimeError)
            @session.get_result_list(criteria)
          end
       }}
        
      end
    end
  end # MedData
end # ODDB
