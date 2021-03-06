require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'annotate/annotate_routes'

describe AnnotateRoutes do
  ROUTE_FILE = 'config/routes.rb'.freeze
  ANNOTATION_ADDED = "#{ROUTE_FILE} annotated.".freeze
  ANNOTATION_REMOVED = "Removed annotations from #{ROUTE_FILE}.".freeze
  FILE_UNCHANGED = "#{ROUTE_FILE} unchanged.".freeze

  def mock_file(stubs = {})
    @mock_file ||= double(File, stubs)
  end

  def magic_comments_list_each
    [
      '# encoding: UTF-8',
      '# coding: UTF-8',
      '# -*- coding: UTF-8 -*-',
      '#encoding: utf-8',
      '# encoding: utf-8',
      '# -*- encoding : utf-8 -*-',
      "# encoding: utf-8\n# frozen_string_literal: true",
      "# frozen_string_literal: true\n# encoding: utf-8",
      '# frozen_string_literal: true',
      '#frozen_string_literal: false',
      '# -*- frozen_string_literal : true -*-'
    ].each { |magic_comment| yield magic_comment }
  end

  it 'should check if routes.rb exists' do
    expect(File).to receive(:exists?).with(ROUTE_FILE).and_return(false)
    expect(AnnotateRoutes).to receive(:puts).with("Can't find routes.rb")
    AnnotateRoutes.do_annotations
  end

  describe 'Annotate#example' do
    let(:rake_routes_content) do
      "                                      Prefix Verb       URI Pattern                                               Controller#Action
                                   myaction1 GET        /url1(.:format)                                           mycontroller1#action
                                   myaction2 POST       /url2(.:format)                                           mycontroller2#action
                                   myaction3 DELETE|GET /url3(.:format)                                           mycontroller3#action\n"
    end

    before(:each) do
      expect(File).to receive(:exists?).with(ROUTE_FILE).and_return(true).at_least(:once)

      expect(File).to receive(:read).with(ROUTE_FILE).and_return("").at_least(:once)

      expect(AnnotateRoutes).to receive(:puts).with(ANNOTATION_ADDED).at_least(:once)
    end

    context 'without magic comments' do
      before(:each) do
        expect(AnnotateRoutes).to receive(:`).with('rake routes').and_return(rake_routes_content)
      end

      it 'annotate normal' do
        expect(File).to receive(:open).with(ROUTE_FILE, 'wb').and_yield(mock_file)
        expect(@mock_file).to receive(:puts).with("
# == Route Map
#
#                                       Prefix Verb       URI Pattern                                               Controller#Action
#                                    myaction1 GET        /url1(.:format)                                           mycontroller1#action
#                                    myaction2 POST       /url2(.:format)                                           mycontroller2#action
#                                    myaction3 DELETE|GET /url3(.:format)                                           mycontroller3#action\n")

        AnnotateRoutes.do_annotations
      end

      it 'annotate markdown' do
        expect(File).to receive(:open).with(ROUTE_FILE, 'wb').and_yield(mock_file)
        expect(@mock_file).to receive(:puts).with("
# ## Route Map
#
# Prefix    | Verb       | URI Pattern     | Controller#Action   
# --------- | ---------- | --------------- | --------------------
# myaction1 | GET        | /url1(.:format) | mycontroller1#action
# myaction2 | POST       | /url2(.:format) | mycontroller2#action
# myaction3 | DELETE-GET | /url3(.:format) | mycontroller3#action\n")

        AnnotateRoutes.do_annotations(format_markdown: true)
      end

      it 'wraps annotation if wrapper is specified' do
        expect(File).to receive(:open).with(ROUTE_FILE, 'wb').and_yield(mock_file)
        expect(@mock_file).to receive(:puts).with("
# START
# == Route Map
#
#                                       Prefix Verb       URI Pattern                                               Controller#Action
#                                    myaction1 GET        /url1(.:format)                                           mycontroller1#action
#                                    myaction2 POST       /url2(.:format)                                           mycontroller2#action
#                                    myaction3 DELETE|GET /url3(.:format)                                           mycontroller3#action
# END\n")

        AnnotateRoutes.do_annotations(wrapper_open: 'START', wrapper_close: 'END')
      end
    end

    context 'file with magic comments' do
      it 'should not remove magic comments' do
        magic_comments_list_each do |magic_comment|
          expect(AnnotateRoutes).to receive(:`).with('rake routes')
            .and_return("#{magic_comment}\n#{rake_routes_content}")

          expect(File).to receive(:open).with(ROUTE_FILE, 'wb').and_yield(mock_file)
          expect(@mock_file).to receive(:puts).with("
#{magic_comment}

# == Route Map
#
#                                       Prefix Verb       URI Pattern                                               Controller#Action
#                                    myaction1 GET        /url1(.:format)                                           mycontroller1#action
#                                    myaction2 POST       /url2(.:format)                                           mycontroller2#action
#                                    myaction3 DELETE|GET /url3(.:format)                                           mycontroller3#action\n")

          AnnotateRoutes.do_annotations
        end
      end

      it 'annotate markdown' do
        magic_comments_list_each do |magic_comment|
          expect(AnnotateRoutes).to receive(:`).with('rake routes')
            .and_return("#{magic_comment}\n#{rake_routes_content}")

          expect(File).to receive(:open).with(ROUTE_FILE, 'wb').and_yield(mock_file)
          expect(@mock_file).to receive(:puts).with("
#{magic_comment}

# ## Route Map
#
# Prefix    | Verb       | URI Pattern     | Controller#Action   
# --------- | ---------- | --------------- | --------------------
# myaction1 | GET        | /url1(.:format) | mycontroller1#action
# myaction2 | POST       | /url2(.:format) | mycontroller2#action
# myaction3 | DELETE-GET | /url3(.:format) | mycontroller3#action\n")

          AnnotateRoutes.do_annotations(format_markdown: true)
        end
      end

      it 'wraps annotation if wrapper is specified' do
        magic_comments_list_each do |magic_comment|
          expect(AnnotateRoutes).to receive(:`).with('rake routes')
            .and_return("#{magic_comment}\n#{rake_routes_content}")
          expect(File).to receive(:open).with(ROUTE_FILE, 'wb').and_yield(mock_file)
          expect(@mock_file).to receive(:puts).with("
#{magic_comment}

# START
# == Route Map
#
#                                       Prefix Verb       URI Pattern                                               Controller#Action
#                                    myaction1 GET        /url1(.:format)                                           mycontroller1#action
#                                    myaction2 POST       /url2(.:format)                                           mycontroller2#action
#                                    myaction3 DELETE|GET /url3(.:format)                                           mycontroller3#action
# END\n")

          AnnotateRoutes.do_annotations(wrapper_open: 'START', wrapper_close: 'END')
        end
      end
    end
  end

  describe 'When adding' do
    before(:each) do
      expect(File).to receive(:exists?).with(ROUTE_FILE)
        .and_return(true).at_least(:once)
      expect(AnnotateRoutes).to receive(:`).with('rake routes')
        .and_return('').at_least(:once)
    end

    it 'should insert annotations if file does not contain annotations' do
      expect(File).to receive(:read).with(ROUTE_FILE).and_return("")
      expect(File).to receive(:open).with(ROUTE_FILE, 'wb').and_yield(mock_file)
      expect(@mock_file).to receive(:puts).with("\n# == Route Map\n#\n")
      expect(AnnotateRoutes).to receive(:puts).with(ANNOTATION_ADDED)

      AnnotateRoutes.do_annotations
    end

    it 'should insert annotations if file does not contain annotations and ignore routes' do
      expect(File).to receive(:read).with(ROUTE_FILE).and_return("")
      expect(File).to receive(:open).with(ROUTE_FILE, 'wb').and_yield(mock_file)
      expect(@mock_file).to receive(:puts).with("\n# == Route Map\n#\n")
      expect(AnnotateRoutes).to receive(:puts).with(ANNOTATION_ADDED)

      AnnotateRoutes.do_annotations(ignore_routes: 'my_route')
    end

    it 'should insert annotations if file does not contain annotations and position top' do
      expect(File).to receive(:read).with(ROUTE_FILE).and_return("")
      expect(File).to receive(:open).with(ROUTE_FILE, 'wb').and_yield(mock_file)
      expect(@mock_file).to receive(:puts).with("# == Route Map\n#\n")
      expect(AnnotateRoutes).to receive(:puts).with(ANNOTATION_ADDED)

      AnnotateRoutes.do_annotations(position_in_routes: 'top')
    end

    it 'should skip annotations if file does already contain annotation' do
      expect(File).to receive(:read).with(ROUTE_FILE).and_return("\n# == Route Map\n#\n")
      expect(AnnotateRoutes).to receive(:puts).with(FILE_UNCHANGED)

      AnnotateRoutes.do_annotations
    end

    context 'file with magic comments' do
      it 'leaves magic comment on top, adds an empty line between magic comment and annotation (position_in_routes :top)' do
        expect(File).to receive(:open).with(ROUTE_FILE, 'wb')
          .and_yield(mock_file).at_least(:once)

        magic_comments_list_each do |magic_comment|
          expect(File).to receive(:read).with(ROUTE_FILE).and_return("#{magic_comment}\nSomething")
          expect(@mock_file).to receive(:puts).with("#{magic_comment}\n\n# == Route Map\n#\n\nSomething\n")
          expect(AnnotateRoutes).to receive(:puts).with(ANNOTATION_ADDED)
          AnnotateRoutes.do_annotations(position_in_routes: 'top')
        end
      end

      it 'leaves magic comment on top, adds an empty line between magic comment and annotation (position_in_routes :bottom)' do
        expect(File).to receive(:open).with(ROUTE_FILE, 'wb')
          .and_yield(mock_file).at_least(:once)

        magic_comments_list_each do |magic_comment|
          expect(File).to receive(:read).with(ROUTE_FILE).and_return("#{magic_comment}\nSomething")
          expect(@mock_file).to receive(:puts).with("#{magic_comment}\nSomething\n\n# == Route Map\n#\n")
          expect(AnnotateRoutes).to receive(:puts).with(ANNOTATION_ADDED)
          AnnotateRoutes.do_annotations(position_in_routes: 'bottom')
        end
      end

      it 'skips annotations if file does already contain annotation' do
        magic_comments_list_each do |magic_comment|
          expect(File).to receive(:read).with(ROUTE_FILE)
            .and_return("#{magic_comment}\n\n# == Route Map\n#\n")
          expect(AnnotateRoutes).to receive(:puts).with(FILE_UNCHANGED)

          AnnotateRoutes.do_annotations
        end
      end
    end
  end

  describe 'When adding with older Rake versions' do
    before(:each) do
      expect(File).to receive(:exists?).with(ROUTE_FILE).and_return(true)
      expect(AnnotateRoutes).to receive(:`).with('rake routes').and_return("(in /bad/line)\ngood line")
      expect(File).to receive(:open).with(ROUTE_FILE, 'wb').and_yield(mock_file)
      expect(AnnotateRoutes).to receive(:puts).with(ANNOTATION_ADDED)
    end

    it 'should annotate and add a newline!' do
      expect(File).to receive(:read).with(ROUTE_FILE).and_return("ActionController::Routing...\nfoo")
      expect(@mock_file).to receive(:puts).with(/ActionController::Routing...\nfoo\n\n# == Route Map\n#\n# good line\n/)
      AnnotateRoutes.do_annotations
    end

    it 'should not add a newline if there are empty lines' do
      expect(File).to receive(:read).with(ROUTE_FILE).and_return("ActionController::Routing...\nfoo\n")
      expect(@mock_file).to receive(:puts).with(/ActionController::Routing...\nfoo\n\n# == Route Map\n#\n# good line\n/)
      AnnotateRoutes.do_annotations
    end
  end

  describe 'When adding with newer Rake versions' do
    before(:each) do
      expect(File).to receive(:exists?).with(ROUTE_FILE).and_return(true)
      expect(AnnotateRoutes).to receive(:`).with('rake routes').and_return("another good line\ngood line")
      expect(File).to receive(:open).with(ROUTE_FILE, 'wb').and_yield(mock_file)
      expect(AnnotateRoutes).to receive(:puts).with(ANNOTATION_ADDED)
    end

    it 'should annotate and add a newline!' do
      expect(File).to receive(:read).with(ROUTE_FILE).and_return("ActionController::Routing...\nfoo")
      expect(@mock_file).to receive(:puts).with(/ActionController::Routing...\nfoo\n\n# == Route Map\n#\n# another good line\n# good line\n/)
      AnnotateRoutes.do_annotations
    end

    it 'should not add a newline if there are empty lines' do
      expect(File).to receive(:read).with(ROUTE_FILE).and_return("ActionController::Routing...\nfoo\n")
      expect(@mock_file).to receive(:puts).with(/ActionController::Routing...\nfoo\n\n# == Route Map\n#\n# another good line\n# good line\n/)
      AnnotateRoutes.do_annotations
    end

    it 'should add a timestamp when :timestamp is passed' do
      expect(File).to receive(:read).with(ROUTE_FILE).and_return("ActionController::Routing...\nfoo")
      expect(@mock_file).to receive(:puts).with(/ActionController::Routing...\nfoo\n\n# == Route Map \(Updated \d{4}-\d{2}-\d{2} \d{2}:\d{2}\)\n#\n# another good line\n# good line\n/)
      AnnotateRoutes.do_annotations timestamp: true
    end
  end

  describe 'When removing' do
    before(:each) do
      expect(File).to receive(:exists?).with(ROUTE_FILE).and_return(true)
      expect(File).to receive(:open).with(ROUTE_FILE, 'wb').and_yield(mock_file)
      expect(AnnotateRoutes).to receive(:puts).with(ANNOTATION_REMOVED)
    end

    it 'should remove trailing annotation and trim trailing newlines, but leave leading newlines alone' do
      expect(File).to receive(:read).with(ROUTE_FILE).and_return(<<-EOS



      ActionController::Routing...
      foo


      # == Route Map
      #
      # another good line
      # good line
      EOS
                                                                )
      expect(@mock_file).to receive(:puts).with(<<-EOS



      ActionController::Routing...
      foo
      EOS
                                               )
      AnnotateRoutes.remove_annotations
    end

    it 'should remove prepended annotation and trim leading newlines, but leave trailing newlines alone' do
      expect(File).to receive(:read).with(ROUTE_FILE).and_return(<<-EOS
      # == Route Map
      #
      # another good line
      # good line




      Rails.application.routes.draw do
        root 'root#index'
      end



      EOS
                                                                )
      expect(@mock_file).to receive(:puts).with(<<-EOS
      Rails.application.routes.draw do
        root 'root#index'
      end



      EOS
                                               )
      AnnotateRoutes.remove_annotations
    end

    it 'should not remove custom comments above route map' do
      expect(File).to receive(:read).with(ROUTE_FILE).and_return(<<-EOS
      # My comment
      # == Route Map
      #
      # another good line
      # good line
      Rails.application.routes.draw do
        root 'root#index'
      end
      EOS
                                                                )

      expect(@mock_file).to receive(:puts).with(<<-EOS
      # My comment
      Rails.application.routes.draw do
        root 'root#index'
      end
      EOS
                                               )

      AnnotateRoutes.remove_annotations
    end
  end
end
