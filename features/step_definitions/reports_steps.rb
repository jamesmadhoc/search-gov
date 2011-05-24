Given /^the following MonthlyPopularQueries exist$/ do |table|
  MonthlyPopularQuery.delete_all
  table.hashes.each do |hash|
    MonthlyPopularQuery.create!(:year => hash["year"], :month => hash["month"], :query => hash["query"], :times => hash["times"], :is_grouped => hash["is_grouped"].present? ? hash["is_grouped"] : false)
  end
end

Given /^the following MonthlyClickTotals exist$/ do |table|
  MonthlyClickTotal.delete_all
  table.hashes.each do |hash|
    MonthlyClickTotal.create!(:year => hash["year"], :month => hash["month"], :source => hash["source"], :total => hash["total"])
  end
end

Given /^the following DailyUsageStats exists for each day in yesterday's month$/ do |table|
  DailyUsageStat.delete_all
  yday = Date.yesterday
  table.hashes.each do |hash|
    yday.day.times do |index|
      DailyUsageStat.create!(:day => yday - index, :profile => hash["profile"], :total_queries => hash["total_queries"], :total_page_views => hash["total_page_views"], :total_unique_visitors => hash["total_unique_visitors"], :affiliate => hash["affiliate"])
    end
  end
end

Given /^the following DailyUsageStats exist for each day in "([^\"]*)"$/ do |month, table|
  DailyUsageStat.delete_all
  month_date = Date.parse(month + "-01")
  table.hashes.each do |hash|
    (Date.new(Time.now.year,12,31).to_date<<(12-month_date.month)).day.times do |index|
      DailyUsageStat.create!(:day => month_date + index.days, :profile => hash["profile"], :total_queries => hash["total_queries"], :total_page_views => hash["total_page_views"], :total_unique_visitors => hash["total_unique_visitors"], :affiliate => hash["affiliate"])
    end
  end
end

Then /^I should see the header for the report date$/ do
  page.body.should match("Monthly Usage Stats for #{Date::MONTHNAMES[Date.yesterday.month]} #{Date.yesterday.year}")
end

Then /^I should see the "([^\"]*)" queries total within "([^\"]*)"$/ do |profile, selector|
  value = 1000 * Date.yesterday.day
  page.body.should match("Total Queries: #{value.to_s.reverse.gsub(/...(?=.)/,'\&,').reverse}")
end

Then /^I should see the "([^\"]*)" page views total within "([^\"]*)"$/ do |profile, selector|
  value = 1000 * Date.yesterday.day
  page.body.should match("Total Page Views: #{value.to_s.reverse.gsub(/...(?=.)/,'\&,').reverse}")
end

Then /^I should see the "([^\"]*)" unique visitors total within "([^\"]*)"$/ do |profile, selector|
  value = 1000 * Date.yesterday.day
  page.body.should match("Total Unique Visitors: #{value.to_s.reverse.gsub(/...(?=.)/,'\&,').reverse}")
end

Then /^I should see the "([^\"]*)" clicks total within "([^\"]*)"$/ do |profile, selector|
  value = 10 * Date.yesterday.day
  page.body.should match("Total Click Throughs: #{value.to_s.reverse.gsub(/...(?=.)/,'\&,').reverse}")
end

Then /^I should see the report header for "([^\"]*)"$/ do |month|
  date = Date.parse(month + "-01")
  page.body.should match("Monthly Usage Stats for #{Date::MONTHNAMES[date.month]} #{date.year}")
end

Then /^I should see the "([^\"]*)" "([^\"]*)" total within "([^\"]*)" with a total of "([^\"]*)"$/ do |profile, stat_name, selector, total|
  page.body.should match("Total #{stat_name}: #{total}")
end

Given /^I select "([^\"]*)" as the report date$/ do |date_string|
  date = Date.parse(date_string)
  select date.year.to_s, :from => "date[year]"
  select date.strftime('%B'), :from => "date[month]"
end

Given /^the following Clicks exist for each day in yesterday's month$/ do |table|
  time = Date.yesterday
  table.hashes.each do |hash|
    time.day.times do |index|
      hash['total_clicks'].to_i.times do
        Click.create!(:affiliate => hash['affiliate'], :query => "foo", :queried_at => time - index, :clicked_at => time - index, :url => 'bar', :results_source => 'BWEB')
      end
    end
  end
end

Given /^the following Clicks exist for each day in "([^\"]*)"$/ do |month_year, table|
  start_date = Date.parse(month_year + "-01")
  end_date = (start_date + 1.month)
  table.hashes.each do |hash|
    (end_date - start_date).to_i.times do |index|
      hash['total_clicks'].to_i.times do
        click = Click.create!(:affiliate => hash['affiliate'], :query => "foo", :queried_at => start_date + index, :clicked_at => start_date + index, :url => 'bar', :results_source => 'BWEB')
      end
    end
  end
end

