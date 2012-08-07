require 'spec_helper'

describe "SAYT suggestions rake tasks" do
  before do
    @rake = Rake::Application.new
    Rake.application = @rake
    load Rails.root + "lib/tasks/sayt_suggestions.rake"
    Rake::Task.define_task(:environment)
  end

  describe "usasearch:sayt_suggestions" do

    describe "usasearch:sayt_suggestions:compute" do
      before do
        @task_name = "usasearch:sayt_suggestions:compute"
      end

      it "should have 'environment' as a prereq" do
        @rake[@task_name].prerequisites.should include("environment")
      end

      context "when target day is specified" do
        it "should populate sayt_suggestions for that given day" do
          day = Date.current.to_s(:number).to_i
          SaytSuggestion.should_receive(:populate_for).with(day, nil)
          @rake[@task_name].invoke(day)
        end
      end

      context "when target day is not specified" do
        it "should default to yesterday" do
          day = Date.yesterday.to_s(:number).to_i
          SaytSuggestion.should_receive(:populate_for).with(day, nil)
          @rake[@task_name].invoke
        end
      end

      context "when limit is specified" do
        it "should pass that along to #populate_for" do
          day = Date.current.to_s(:number).to_i
          limit = "20"
          SaytSuggestion.should_receive(:populate_for).with(day, limit.to_i)
          @rake[@task_name].invoke(day, limit)
        end
      end

      context "when limit is not specified" do
        it "should pass nil to #populate_for" do
          day = Date.current.to_s(:number).to_i
          SaytSuggestion.should_receive(:populate_for).with(day, nil)
          @rake[@task_name].invoke(day)
        end
      end
    end

    describe "usasearch:sayt_suggestions:expire" do
      before do
        @task_name = "usasearch:sayt_suggestions:expire"
      end

      it "should have 'environment' as a prereq" do
        @rake[@task_name].prerequisites.should include("environment")
      end

      context "when days back is specified" do
        it "should expire sayt_suggestions that have not been updated for that many days" do
          days_back = "7"
          SaytSuggestion.should_receive(:expire).with(days_back.to_i)
          @rake[@task_name].invoke(days_back)
        end
      end

      context "when days back is not specified" do
        it "should expire sayt_suggestions that have not been updated for 30 days" do
          days_back = "30"
          SaytSuggestion.should_receive(:expire).with(days_back.to_i)
          @rake[@task_name].invoke
        end
      end
    end

    describe "usasearch:sayt_suggestions:prune_dead_ends" do
      before do
        @task_name = "usasearch:sayt_suggestions:prune_dead_ends"
      end

      it "should have 'environment' as a prereq" do
        @rake[@task_name].prerequisites.should include("environment")
      end

      it "should prune sayt_suggestions that yield no search results" do
        SaytSuggestion.should_receive(:prune_dead_ends)
        @rake[@task_name].invoke
      end
    end
  end
end
