# Forker - Fork Management for Ruby Gems

[![Ruby](https://img.shields.io/badge/ruby-3.0%2B-red.svg)](https://www.ruby-lang.org/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.txt)

Forker is a Ruby gem that helps you manage forked gems using Git and GitHub CLI. It tracks fork relationships, monitors activity across fork networks, and helps you discover collaborators working on similar forks.

## Features

- **Fork Management**: Fork repositories directly from the command line
- **Ecosystem Awareness**: See who else is working on the same gems
- **Local Metadata Storage**: Fast access to fork information without repeated API calls
- **Root Repository Tracking**: Automatically identify the canonical upstream repository
- **Peer Discovery**: Find other active forks and potential collaborators
- **Pull Request Monitoring**: Track PR activity across the fork network
- **Activity Tracking**: Identify the most recently active forks

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'forker'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install forker
```

## Prerequisites

Forker uses the GitHub CLI (`gh`) for GitHub operations. You need to:

1. **Install GitHub CLI**: 
   - macOS: `brew install gh`
   - Linux: See [https://cli.github.com/](https://cli.github.com/)
   - Windows: See [https://cli.github.com/](https://cli.github.com/)

2. **Authenticate with GitHub**:
   ```bash
   gh auth login
   ```

## Usage

### Quick Start

```bash
# Fork a gem you want to contribute to
bin/forker fork --url=https://github.com/original/gem.git --account=your-github-account

# List your forks
bin/forker list --account=your-github-account

# Check status of your forks
bin/forker status

# Find other active forks (potential collaborators)
bin/forker active

# Check peers working on similar forks
bin/forker peers

# Monitor pull requests across the ecosystem
bin/forker prs
```

### Commands

#### `forker list`

List all forked gems for a specific GitHub account and identify the root repository for each fork.

```bash
bin/forker list --account=GITHUB_ACCOUNT
```

**Example:**
```bash
bin/forker list --account=myusername

Forks for myusername:
--------------------------------------------------------------------------------

devise
  URL: https://github.com/myusername/devise
  Root: https://github.com/heartcombo/devise
  Description: Flexible authentication solution for Rails
  Updated: 2024-01-15T10:30:00Z

rails
  URL: https://github.com/myusername/rails
  Root: https://github.com/rails/rails
  Description: Ruby on Rails
  Updated: 2024-01-20T14:45:00Z

Total forks: 2
```

#### `forker fork`

Fork a repository on GitHub to your account.

```bash
bin/forker fork --url=GIT_URL --account=GITHUB_ACCOUNT
```

**Example:**
```bash
bin/forker fork --url=https://github.com/rails/rails --account=myusername

Successfully forked repository!
  Original: https://github.com/rails/rails
  Fork: https://github.com/myusername/rails
  Root: https://github.com/rails/rails
```

#### `forker status`

Check the status of all tracked forks, including how many commits ahead or behind the root repository.

```bash
bin/forker status
```

**Example:**
```bash
bin/forker status

Fork Status:
--------------------------------------------------------------------------------

devise
  Fork: https://github.com/myusername/devise
  Root: https://github.com/heartcombo/devise
  Commits ahead: 3
  Commits behind: 15
  Last updated: 2024-01-15T10:30:00Z

Total tracked forks: 1
```

#### `forker peers`

List other forks of the same repositories, helping you discover other contributors.

```bash
bin/forker peers
```

**Example:**
```bash
bin/forker peers

Peer Forks:
--------------------------------------------------------------------------------

devise (https://github.com/heartcombo/devise)
  Other forks (45):
    - user1/devise (updated: 2024-01-20T08:00:00Z)
    - user2/devise (updated: 2024-01-18T15:30:00Z)
    - user3/devise (updated: 2024-01-15T12:00:00Z)
    ...
```

#### `forker prs`

List pull requests across the fork network.

```bash
bin/forker prs
```

**Example:**
```bash
bin/forker prs

Pull Requests:
--------------------------------------------------------------------------------

devise
  Open PRs (3):
    #1234: Fix authentication bug
      Author: user1 | State: OPEN | Created: 2024-01-15T10:00:00Z
    #1235: Add new feature
      Author: user2 | State: OPEN | Created: 2024-01-16T14:30:00Z
```

#### `forker active`

Show the most recently active forks across all tracked repositories.

```bash
bin/forker active
```

**Example:**
```bash
bin/forker active

Most Active Forks:
--------------------------------------------------------------------------------

1. rails
   URL: https://github.com/user1/rails
   Root: https://github.com/rails/rails
   Last activity: 2024-01-20T16:00:00Z

2. devise
   URL: https://github.com/user2/devise
   Root: https://github.com/heartcombo/devise
   Last activity: 2024-01-20T08:00:00Z
```

## Fork Metadata Storage

All fork metadata is stored locally in the `.forker/` directory:

```
.forker/
├── gem_name_1/
│   ├── fork_info.json    # Basic fork information
│   ├── peers.json        # Other forks of the same repository
│   └── prs.json          # Pull requests
├── gem_name_2/
│   └── fork_info.json
└── ...
```

This allows forker commands to cache and track fork information locally, reducing API calls and providing faster access to data.

## Integration with Vendorer

Forker works great with the `vendorer` gem for local development:

1. **Fork** a gem using forker to create your GitHub fork
2. **Vendor** the fork using vendorer to work on it locally
3. **Push** changes using vendorer
4. **Monitor** PR status using forker

**Example workflow:**
```bash
# Fork the gem on GitHub
bin/forker fork --url=https://github.com/original/some_gem.git --account=your-account

# Vendor your fork for local development
bin/vendorer vendor some_gem --url=https://github.com/your-account/some_gem.git

# Make changes in vendor/some_gem/

# Push changes to your fork
bin/vendorer push some_gem --branch=feature/my-fix --message="Fix issue"

# Check PR status across the fork network
bin/forker prs
```

## Use Cases

### Contributing to Open Source

When you want to contribute to an open source gem:

1. Fork the gem using `forker fork`
2. Track the fork's status relative to upstream
3. Discover other contributors working on similar changes
4. Monitor PR activity to avoid duplicate work

### Managing Multiple Forks

If you maintain forks of multiple gems:

1. Use `forker list` to see all your forks
2. Use `forker status` to check which forks need updating
3. Use `forker active` to see which forks have recent activity

### Finding Collaborators

To find potential collaborators:

1. Use `forker peers` to see who else has forked the same gems
2. Check their fork activity to find active contributors
3. Review their PRs to understand their contributions

## Development

After checking out the repo, run:

```bash
bundle install
```

Run the test suite:

```bash
bundle exec rake spec        # Run RSpec tests
bundle exec rake cucumber    # Run Cucumber features
bundle exec rake             # Run all tests
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/magenticmarketactualskill/forker.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).

## Credits

Developed by the Forker Team to help Ruby developers manage their gem fork ecosystems more effectively.
