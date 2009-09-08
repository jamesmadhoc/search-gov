Feature: Analytics Homepage
  In order to anticipate trends and topics of high public interest
  As an Analyst
  I want to view analytics on usasearch query data. The analytics contains two sections: most popular queries,
    and biggest mover queries. Each of these is broken down into different timeframes (1 day, 7 day, and 30 day).

  Scenario: Viewing the homepage
    Given there is analytics data from "20090801" thru "20090901"
    When I am on the analytics homepage
    Then I should see "Data for September  1, 2009"
    And in "dqs1" I should not see "Query data unavailable"
    And in "dqs7" I should not see "Query data unavailable"
    And in "dqs30" I should not see "Query data unavailable"
    And in "qas1" I should not see "Query data unavailable"
    And in "qas7" I should not see "Query data unavailable"
    And in "qas30" I should not see "Query data unavailable"

  Scenario: No daily query stats available for any time period
    Given there are no daily query stats
    When I am on the analytics homepage
    Then in "dqs1" I should see "Query data unavailable"
    And in "dqs7" I should see "Query data unavailable"
    And in "dqs30" I should see "Query data unavailable"

  Scenario: No query accelerations (biggest movers) available for any time period
    Given there are no query accelerations stats
    When I am on the analytics homepage
    Then in "qas1" I should see "Query data unavailable"
    And in "qas7" I should see "Query data unavailable"
    And in "qas30" I should see "Query data unavailable"
