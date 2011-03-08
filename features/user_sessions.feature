Feature: User sessions

  Scenario: Visiting the login page
    Given I am on the program welcome page
    When I follow "Sign In"
    Then I should see "Log In"

  Scenario: Already logged-in user visits login page
    Given I am logged in with email "affiliate_admin@fixtures.org" and password "admin"
    When I go to the login page
    Then I should be on the user account page

    When I follow "Sign Out"
    Then I should be on the login page

  Scenario: User has trouble logging in
    Given I am on the login page
    And I fill in the following in the login form:
      | Email                         | not@valid.gov      |
      | Password                      | fail               |
    And I press "Login"
    Then I should see "Email is not valid"

  Scenario: Affiliate admin should be on the affiliate home page upon successful login
    Given I am on the login page
    And I fill in the following in the login form:
      | Email                         | affiliate_admin@fixtures.org      |
      | Password                      | admin                             |
    And I press "Login"
    Then I should be on the affiliate admin page

  Scenario: Analyst should be on the analytics homepage upon successful login
    Given I am on the login page
    And I fill in the following in the login form:
      | Email                         | analyst@fixtures.org              |
      | Password                      | admin                             |
    And I press "Login"
    Then I should be on the analytics homepage

  Scenario: Affiliate manager should be on the affiliate home page upon successful login
    Given I am on the login page
    And I fill in the following in the login form:
      | Email                         | affiliate_manager@fixtures.org    |
      | Password                      | admin                             |
    And I press "Login"
    Then I should be on the affiliate admin page
