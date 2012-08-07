require 'spec_helper'

describe RssFeedUrl do
  fixtures :affiliates, :rss_feeds, :rss_feed_urls

  it { should belong_to :rss_feed }
  it { should have_many(:news_items).dependent(:destroy) }
  it { should validate_presence_of :url }

  describe "validation" do
    let(:rss_feed) { rss_feeds(:basic) }

    context "when the RSS feed is a valid feed" do
      before do
        rss_feed_content = File.open(Rails.root.to_s + '/spec/fixtures/rss/wh_blog.xml')
        Kernel.should_receive(:open).with('http://bogus.example.gov/feed/blog').and_return(rss_feed_content)
      end

      it "should be_valid" do
        expect { rss_feed.rss_feed_urls.create!(:url => 'http://bogus.example.gov/feed/blog') }.to_not raise_error
      end
    end

    context "when the URL does not point to an RSS feed" do
      before do
        not_rss_feed_content = File.read(Rails.root.to_s + '/spec/fixtures/html/usa_gov/site_index.html')
        Kernel.should_receive(:open).with('http://bogus.example.gov/not_feed/blog').and_return(not_rss_feed_content)
      end

      it "should not be valid" do
        rss_feed_url = rss_feed.rss_feed_urls.build(:url => 'http://bogus.example.gov/not_feed/blog')
        rss_feed_url.should_not be_valid
        rss_feed_url.errors.full_messages.should include('Url does not appear to be a valid RSS feed.')
      end
    end

    context "when some error is raised in checking the RSS feed" do
      before do
        Kernel.should_receive(:open).and_raise('Some exception')
      end

      it "should not be valid" do
        rss_feed_url = rss_feed.rss_feed_urls.build(:url => 'http://bogus.example.gov/feed/with_error')
        rss_feed_url.should_not be_valid
        rss_feed_url.errors.full_messages.should include('Url does not appear to be a valid RSS feed. Additional information: Some exception')
      end
    end

    context "when URL has the wrong format" do
      it "should not be valid" do
        rss_feed_url = rss_feed.rss_feed_urls.build(:url => 'not_a_valid_url')
        rss_feed_url.save.should be_false
        rss_feed_url.errors[:url].should include('is invalid')
      end
    end

    context "when URL has not changed" do
      before do
        rss_feed_content = File.open(Rails.root.to_s + '/spec/fixtures/rss/wh_blog.xml')
        Kernel.should_receive(:open).with('http://bogus.example.gov/feed').and_return(rss_feed_content)
      end

      it "should not validate url again" do
        rss_feed_url = rss_feed.rss_feed_urls.create!(:url => 'http://bogus.example.gov/feed')
        rss_feed_url.update_attributes!(:last_crawled_at => Time.current)
      end
    end
  end

  describe "#is_video?" do
    let(:rss_feed) { rss_feeds(:basic) }

    context "when url starts with gdata.youtube.com/feeds/" do
      before do
        rss_feed_content = File.open(Rails.root.to_s + '/spec/fixtures/rss/youtube.xml')
        Kernel.should_receive(:open).with('http://gdata.youtube.com/feeds/base/videos?alt=rss&user=USGovernment').and_return(rss_feed_content)
      end

      specify { rss_feed.rss_feed_urls.create!(:url => 'http://gdata.youtube.com/feeds/base/videos?alt=rss&user=USGovernment').should be_is_video }
    end
  end

  describe "#freshen" do
    context "when the feed is in the RSS 2.0 format" do
      before do
        rss_feed_content = File.open(Rails.root.to_s + '/spec/fixtures/rss/wh_blog.xml')
        Kernel.should_receive(:open).with('http://some.agency.gov/feed').and_return rss_feed_content
      end

      context "when there are no news items associated with the source" do
        let(:rss_feed_url) { rss_feed_urls(:basic) }

        before do
          rss_feed_url.news_items.destroy_all
        end

        it "should populate news items from the RSS feed source with HTML stripped from the description" do
          rss_feed_url.freshen
          rss_feed_url.reload
          rss_feed_url.last_crawl_status.should == 'OK'
          rss_feed_url.news_items.count.should == 3

          newest = rss_feed_url.news_items.first
          newest.guid.should == '80731 at http://www.whitehouse.gov'
          newest.link.should == 'http://www.whitehouse.gov/blog/2011/09/26/famine-horn-africa-be-part-solution'
          newest.published_at.should == DateTime.parse('26 Sep 2011 21:33:05 +0000')
          newest.description[0, 40].should == 'Dr. Biden and David Letterman refer to a'
          newest.title.should == 'Famine in the Horn of Africa: Be a Part of the Solution'

          oldest = rss_feed_url.news_items.last
          oldest.guid.should == 'http://www.whitehouse.gov/blog/2011/09/26/supporting-scientists-lab-bench-and-bedtime-0'
        end
      end

      context "when some news items are newer and some are older than the most recent published_at time for the feed" do
        let(:rss_feed_url) { rss_feed_urls(:basic) }

        before do
          rss_feed_url.update_attributes(:last_crawl_status => RssFeedUrl::OK_STATUS)
          NewsItem.destroy_all
          rss_feed_url.news_items.create!(
              :rss_feed => rss_feed_url.rss_feed,
              :link => 'http://www.whitehouse.gov/latest_story.html',
              :title => 'Big story here',
              :description => 'Corps volunteers have promoted blah blah blah.',
              :published_at => DateTime.parse('26 Sep 2011 18:31:23 +0000'),
              :guid => 'unique')
        end

        context "when ignore_older_items set to true (default)" do
          it "should populate news items with only the new ones from the RSS feed source based on the pubDate" do
            rss_feed_url.freshen
            rss_feed_url.reload
            rss_feed_url.last_crawl_status.should == 'OK'
            rss_feed_url.news_items.count.should == 3
          end
        end

        context "when ignore_older_items set to false" do
          it "should populate news items with both the new and old ones from the RSS feed source based on the pubDate" do
            rss_feed_url.freshen(false)
            rss_feed_url.reload
            rss_feed_url.last_crawl_status.should == 'OK'
            rss_feed_url.news_items.count.should == 4
          end
        end
      end

      context "when there are duplicate news items" do
        let(:rss_feed_url) { rss_feed_urls(:basic) }

        before do
          NewsItem.destroy_all
          rss_feed_url.news_items.create!(
              :rss_feed => rss_feed_url.rss_feed,
              :link => 'http://www.whitehouse.gov/latest_story.html',
              :title => 'Big story here',
              :description => 'Corps volunteers have promoted blah blah blah.',
              :published_at => DateTime.parse('26 Sep 2011 18:31:21 +0000'),
              :guid => '80671 at http://www.whitehouse.gov')
        end

        it "should ignore them" do
          rss_feed_url.freshen
          rss_feed_url.reload
          rss_feed_url.last_crawl_status.should == 'OK'
          rss_feed_url.news_items.count.should == 3
        end
      end

      context "when an exception is raised somewhere along the way" do
        let(:rss_feed_url) { rss_feed_urls(:basic) }
        before do
          DateTime.should_receive(:parse).and_raise Exception.new("Error Message!")
        end

        it "should log it and move on" do
          Rails.logger.should_receive(:warn).once.with(an_instance_of(Exception))
          rss_feed_url.freshen
          rss_feed_url.last_crawl_status.should == "Error Message!"
        end
      end
    end

    context 'when the feed is non playlist video' do
      context 'when the last crawl status is Pending' do
        let(:rss_feed_url) { rss_feed_urls(:youtube_video) }

        before do
          rss_feed_url.news_items.create!(:rss_feed => rss_feed_url.rss_feed,
                                          :link => 'http://gdata.youtube.com/feeds/base/videos/MOCK1',
                                          :title => 'mock title',
                                          :description => 'mock description',
                                          :published_at => DateTime.parse('Sat, 12 May 2011 16:24:46 +0000'),
                                          :guid => 'http://gdata.youtube.com/feeds/base/videos/MOCK1')
          video_content = File.open(Rails.root.to_s + '/spec/fixtures/rss/youtube.xml')
          next_video_content = File.open(Rails.root.to_s + '/spec/fixtures/rss/next_youtube.xml')
          Kernel.should_receive(:open).twice.and_return(video_content, next_video_content)
        end

        it 'should iterate through all videos' do
          rss_feed_url.freshen
          rss_feed_url.news_items(true).count.should == 29
          newest = rss_feed_url.news_items.first
          newest.guid.should == 'http://gdata.youtube.com/feeds/base/videos/WR595t0HBGE'
          newest.title.should == 'President Obama Honors the Nations TOP COPS'
          newest.description[0, 40].should == 'President Obama Honors the Nations TOP C'
          newest.link.should == 'http://www.youtube.com/watch?v=WR595t0HBGE&feature=youtube_gdata'
          newest.published_at.should == DateTime.parse('Sat, 12 May 2012 16:24:46 +0000')
        end
      end

      context 'when the last crawl status is not pending' do
        let(:rss_feed_url) { rss_feed_urls(:youtube_video) }

        before do
          video_content = File.open(Rails.root.to_s + '/spec/fixtures/rss/youtube.xml')
          Kernel.should_receive(:open).and_return(video_content)

          rss_feed_url.news_items.create!(:rss_feed => rss_feed_url.rss_feed,
                                          :link => 'http://gdata.youtube.com/feeds/base/videos/MOCK1',
                                          :title => 'mock title',
                                          :description => 'mock description',
                                          :published_at => DateTime.current,
                                          :guid => 'http://gdata.youtube.com/feeds/base/videos/MOCK1')
          rss_feed_url.update_attributes!(:last_crawl_status => RssFeedUrl::OK_STATUS)
        end

        it 'should iterate through all videos' do
          rss_feed_url.freshen
          rss_feed_url.news_items(true).count.should == 1
        end
      end
    end

    context 'when the feed is managed video playlist' do
      let(:rss_feed_url) { rss_feed_urls(:playlist_video) }

      context "when there are existing news items that are not in the current playlists" do
        before do
          rss_feed_url.news_items.create!(:rss_feed => rss_feed_url.rss_feed,
                                          :link => 'http://gdata.youtube.com/feeds/base/videos/MOCK1',
                                          :title => 'mock title',
                                          :description => 'mock description',
                                          :published_at => DateTime.current,
                                          :guid => 'http://gdata.youtube.com/feeds/base/videos/MOCK1',
                                          :updated_at => Time.current.yesterday)

          rss_feed_url.news_items.create!(:rss_feed => rss_feed_url.rss_feed,
                                          :link => 'http://gdata.youtube.com/feeds/base/videos/MOCK2',
                                          :title => 'mock title',
                                          :description => 'mock description',
                                          :published_at => DateTime.current,
                                          :guid => 'http://gdata.youtube.com/feeds/base/videos/MOCK2',
                                          :updated_at => Time.current.yesterday)

          rss_feed_url.news_items.create!(:rss_feed => rss_feed_url.rss_feed,
                                          :link => 'http://www.youtube.com/watch?v=FxwcJx0-21E&feature=youtube_gdata',
                                          :title => 'already exist',
                                          :description => 'already exist description',
                                          :published_at => DateTime.parse('2012-01-24T17:31:04.000Z'),
                                          :guid => 'tag:youtube.com,2008:playlist:2A8E588CD55F0FAF:PL9aiTdkQHdAGGrzu_jRXeJy4LBJWSWvrZ',
                                          :updated_at => Time.current.yesterday)
          rss_feed_url.update_attributes!(:last_crawl_status => RssFeedUrl::OK_STATUS)

          playlist_content = File.open(Rails.root.to_s + '/spec/fixtures/rss/playlist_videos.xml')
          Kernel.should_receive(:open).with('http://gdata.youtube.com/feeds/api/playlists/2A8E588CD55F0FAF?alt=rss&start-index=1&max-results=50&v=2').and_return(playlist_content)

          next_playlist_content = File.open(Rails.root.to_s + '/spec/fixtures/rss/next_playlist_videos.xml')
          Kernel.should_receive(:open).with('http://gdata.youtube.com/feeds/api/playlists/2A8E588CD55F0FAF?alt=rss&start-index=51&max-results=50&v=2').and_return(next_playlist_content)
        end

        it 'should delete the obsolete news items' do
          rss_feed_url.freshen
          rss_feed_url.news_items(true).count.should == 88
          rss_feed_url.news_items.find_by_guid('tag:youtube.com,2008:playlist:2A8E588CD55F0FAF:PL9aiTdkQHdAG_mC82ulkmKvpwR7Ls-fzZ').should be_present
          rss_feed_url.news_items.find_by_title('mock title').should be_nil

          newest = rss_feed_url.news_items.first
          newest.guid.should == 'tag:youtube.com,2008:playlist:2A8E588CD55F0FAF:PL9aiTdkQHdAG_mC82ulkmKvpwR7Ls-fzZ'
          newest.title.should == 'Female Engagement Teams: The Changing Face of the US Marines'
          newest.description[0, 40].should == %q(Meet the brave women who are on the grou)
          newest.link.should == 'http://www.youtube.com/watch?v=dN0w8uPnX3s&feature=youtube_gdata'
          newest.published_at.should == DateTime.parse('2012-05-08T22:21:25.000Z')
        end
      end
    end

    context "when the feed is in the Atom format" do
      let(:rss_feed_url) { rss_feed_urls(:atom_feed) }
      let(:url) { 'http://www.icpsr.umich.edu/icpsrweb/ICPSR/feeds/studies?fundingAgency=United+States+Department+of+Justice.+Office+of+Justice+Programs.+National+Institute+of+Justice' }

      before do
        rss_feed_content = File.open(Rails.root.to_s + '/spec/fixtures/rss/atom_feed.xml')
        Kernel.should_receive(:open).with(url).and_return rss_feed_content
      end

      context "when there are no news items associated with the source" do
        before do
          rss_feed_url.news_items.destroy_all
        end

        it "should populate news items from the RSS feed source with HTML stripped from the description" do
          rss_feed_url.freshen
          rss_feed_url.reload
          rss_feed_url.news_items.count.should == 25
          newest = rss_feed_url.news_items.first
          newest.guid.should == 'http://www.icpsr.umich.edu/icpsrweb/ICPSR/studies/22642'
          newest.link.should == 'http://www.icpsr.umich.edu/icpsrweb/ICPSR/studies/22642'
          newest.published_at.should == DateTime.parse('2009-11-30T12:00:00-05:00')
          newest.description[0, 40].should == 'Assessing Consistency and Fairness in Se'
          newest.title.should == 'Assessing Consistency and Fairness in Sentencing in Michigan, Minnesota, and Virginia, 2001-2002, 2004'
        end
      end
    end

    context "when the RSS feed format can not be determined" do
      let(:rss_feed_url) { rss_feed_urls(:atom_feed) }
      let(:url) { 'http://www.icpsr.umich.edu/icpsrweb/ICPSR/feeds/studies?fundingAgency=United+States+Department+of+Justice.+Office+of+Justice+Programs.+National+Institute+of+Justice' }

      before do
        rss_feed_url.news_items.destroy_all
        rss_feed_content = File.open(Rails.root.to_s + '/spec/fixtures/rss/atom_feed.xml')
        Kernel.should_receive(:open).with(url).and_return rss_feed_content
        rss_feed_url.should_receive(:detect_feed_type).and_return(nil)
      end

      it "should not change the number of news items, and update the crawl status" do
        rss_feed_url.freshen
        rss_feed_url.reload
        rss_feed_url.news_items.count.should == 0
        rss_feed_url.last_crawl_status.should == "Unknown feed type."
      end
    end
  end
end
