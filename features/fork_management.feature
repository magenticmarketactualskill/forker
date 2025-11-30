Feature: Fork Management
  As a developer
  I want to manage forked gems
  So that I can track and collaborate on gem development

  Background:
    Given a clean forker environment

  Scenario: Creating .forker directory structure
    When I initialize forker storage
    Then the .forker directory should exist
    And the .forker directory should be empty

  Scenario: Saving fork information
    Given I have fork information for "test_gem"
    When I save the fork information
    Then the fork information should be stored in .forker/test_gem/fork_info.json
    And I should be able to load the fork information

  Scenario: Tracking multiple forks
    Given I have fork information for "gem1"
    And I have fork information for "gem2"
    When I save all fork information
    Then I should have 2 tracked gems
    And the tracked gems should include "gem1" and "gem2"

  Scenario: Saving and loading peers
    Given I have fork information for "test_gem"
    And I have peers information for "test_gem"
    When I save the peers information
    Then the peers information should be stored
    And I should be able to load the peers information

  Scenario: Saving and loading pull requests
    Given I have fork information for "test_gem"
    And I have pull requests information for "test_gem"
    When I save the pull requests information
    Then the pull requests should be stored
    And I should be able to load the pull requests

  Scenario: Deleting fork data
    Given I have fork information for "test_gem"
    And I have saved the fork information
    When I delete the fork data
    Then the fork directory should not exist
