require "#{File.dirname(__FILE__)}/../spec_helper"

describe Search do
  fixtures :affiliates

  before do
    @affiliate = affiliates(:basic_affiliate)
    @valid_options = {:query => 'government', :page => 3, :affiliate => @affiliate}
  end

  describe "when new" do
    it "should have a settable query" do
      search = Search.new(@valid_options)
      search.query.should == 'government'
    end

    it "should have a settable affiliate" do
      search = Search.new(@valid_options)
      search.affiliate.should == @affiliate
    end

    it "should not require a query or affiliate" do
      lambda { Search.new }.should_not raise_error(ArgumentError)
    end
  end

  describe "using different search indexes" do

    it "should default to Bing" do
      Search.new(@valid_options).engine.should be_instance_of Bing
    end

    it "should be settable to GSS" do
      Search.new(@valid_options.merge(:engine => "gss")).engine.should be_instance_of Gss
    end

    it "should be settable to Gweb" do
      Search.new(@valid_options.merge(:engine => "gweb")).engine.should be_instance_of Gweb
    end

    it "should run the appropriate search engine" do
      Search::ENGINES.each do | sym, klass |
        engine = klass.new(@valid_options)
        klass.stub!(:new).and_return(engine)
        klass.should_receive(:new).once.with(@valid_options).and_return(engine)
        Search.new(@valid_options.merge(:engine => sym.to_s))
      end
    end

    Search::ENGINES.each do | sym, klass |

      describe "when searching with valid queries on #{klass.name}" do
        before do
          @search = Search.new(@valid_options.merge(:engine => sym.to_s))
          @search.run
        end

        it "should find results based on query" do
          @search.results.size.should > 0
        end

        it "should have a total at least as large as the first set of results" do
          @search.total.should >= @search.results.size
        end

      end

      describe "when searching with really long queries" do
        before do
          @search = Search.new(@valid_options.merge(:engine => sym.to_s, :query => "X"*10000))
        end

        it "should return false when searching" do
          @search.run.should be_false
        end

        it "should have 0 results" do
          @search.run
          @search.results.size.should == 0
        end

        it "should set error message" do
          @search.run
          @search.error_message.should_not be_nil
        end
      end

      describe "when searching with nonsense queries" do
        before do
          @search = Search.new(@valid_options.merge(:engine => sym.to_s, :query => 'kjdfgkljdhfgkldjshfglkjdsfhg'))
        end

        it "should return true when searching" do
          @search.run.should be_true
        end

        it "should have 0 results" do
          @search.run
          @search.results.size.should == 0
        end
      end
    end
  end

  describe "when paginating" do
    default_page = 0

    it "should default to page 0 if no valid page number was specified" do
      options_without_page = @valid_options.reject{|k, v| k == :page}
      Search.new(options_without_page).page.should == default_page
      Search.new(@valid_options.merge(:page => '')).page.should == default_page
      Search.new(@valid_options.merge(:page => 'string')).page.should == default_page
    end

    it "should set the page number" do
      search = Search.new(@valid_options.merge(:page => 2))
      search.page.should == 2
    end

    it "should use the underlying engine's results per page" do
      search = Search.new(@valid_options)
      search.run
      search.results.size.should == search.per_page
    end

    it "should set startrecord/endrecord" do
      page = 7
      search = Search.new(@valid_options.merge(:page => page))
      search.run
      search.startrecord.should == search.per_page * page + 1
      search.endrecord.should == search.startrecord + search.results.size - 1
    end
  end
end
