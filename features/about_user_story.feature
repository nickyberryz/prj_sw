Feature: User and staff can see about page 
  As an User's and staff
  So that I can see about page 
  I want to go to about page

Scenario: can see about page 
  Given I am on the home page
  Then I should see "เกี่ยวกับเรา"
  When I follow "เกี่ยวกับเรา"
  Then I should be on the about page


