# Forker Examples

This document provides detailed examples of using Forker in various scenarios.

## Basic Workflow

### Scenario 1: Contributing to a Popular Gem

You want to contribute a bug fix to the Devise authentication gem.

**Step 1: Fork the repository**

```bash
bin/forker fork --url=https://github.com/heartcombo/devise --account=myusername
```

Output:
```
Successfully forked repository!
  Original: https://github.com/heartcombo/devise
  Fork: https://github.com/myusername/devise
  Root: https://github.com/heartcombo/devise
```

**Step 2: Check your fork status**

```bash
bin/forker status
```

Output:
```
Fork Status:
--------------------------------------------------------------------------------

devise
  Fork: https://github.com/myusername/devise
  Root: https://github.com/heartcombo/devise
  Commits ahead: 0
  Commits behind: 0
  Last updated: 2024-01-20T10:30:00Z

Total tracked forks: 1
```

**Step 3: Find other contributors**

```bash
bin/forker peers
```

Output:
```
Peer Forks:
--------------------------------------------------------------------------------

devise (https://github.com/heartcombo/devise)
  Other forks (1247):
    - plataformatec/devise (updated: 2024-01-19T15:30:00Z)
    - activeadmin/devise (updated: 2024-01-18T12:00:00Z)
    - thoughtbot/devise (updated: 2024-01-17T09:45:00Z)
    ...
```

### Scenario 2: Managing Multiple Forks

You maintain forks of several gems for your organization.

**Step 1: List all your forks**

```bash
bin/forker list --account=mycompany
```

Output:
```
Forks for mycompany:
--------------------------------------------------------------------------------

rails
  URL: https://github.com/mycompany/rails
  Root: https://github.com/rails/rails
  Description: Ruby on Rails
  Updated: 2024-01-20T14:45:00Z

devise
  URL: https://github.com/mycompany/devise
  Root: https://github.com/heartcombo/devise
  Description: Flexible authentication solution for Rails
  Updated: 2024-01-15T10:30:00Z

sidekiq
  URL: https://github.com/mycompany/sidekiq
  Root: https://github.com/sidekiq/sidekiq
  Description: Simple, efficient background processing for Ruby
  Updated: 2024-01-18T08:15:00Z

Total forks: 3
```

**Step 2: Check which forks need updating**

```bash
bin/forker status
```

Output:
```
Fork Status:
--------------------------------------------------------------------------------

rails
  Fork: https://github.com/mycompany/rails
  Root: https://github.com/rails/rails
  Commits ahead: 5
  Commits behind: 23
  Last updated: 2024-01-20T14:45:00Z

devise
  Fork: https://github.com/mycompany/devise
  Root: https://github.com/heartcombo/devise
  Commits ahead: 2
  Commits behind: 8
  Last updated: 2024-01-15T10:30:00Z

sidekiq
  Fork: https://github.com/mycompany/sidekiq
  Root: https://github.com/sidekiq/sidekiq
  Commits ahead: 1
  Commits behind: 15
  Last updated: 2024-01-18T08:15:00Z

Total tracked forks: 3
```

### Scenario 3: Monitoring Pull Request Activity

You want to track PR activity across gems you're interested in.

**Step 1: Fork the gems you want to track**

```bash
bin/forker fork --url=https://github.com/rails/rails --account=myusername
bin/forker fork --url=https://github.com/rspec/rspec-core --account=myusername
```

**Step 2: Monitor PRs**

```bash
bin/forker prs
```

Output:
```
Pull Requests:
--------------------------------------------------------------------------------

rails
  Open PRs (156):
    #50234: Fix ActiveRecord query optimization
      Author: dhh | State: OPEN | Created: 2024-01-20T09:00:00Z
    #50233: Add support for PostgreSQL 16
      Author: tenderlove | State: OPEN | Created: 2024-01-19T16:30:00Z
    #50232: Improve ActionCable performance
      Author: rafaelfranca | State: OPEN | Created: 2024-01-19T14:00:00Z
    ...

rspec-core
  Open PRs (12):
    #3045: Add new matcher for better error messages
      Author: JonRowe | State: OPEN | Created: 2024-01-18T11:00:00Z
    #3044: Fix deprecation warnings
      Author: pirj | State: OPEN | Created: 2024-01-17T15:30:00Z
    ...
```

### Scenario 4: Finding Active Collaborators

You want to find the most active forks to see who's working on similar features.

**Step 1: Check active forks**

```bash
bin/forker active
```

Output:
```
Most Active Forks:
--------------------------------------------------------------------------------

1. rails
   URL: https://github.com/basecamp/rails
   Root: https://github.com/rails/rails
   Last activity: 2024-01-20T16:00:00Z

2. rails
   URL: https://github.com/shopify/rails
   Root: https://github.com/rails/rails
   Last activity: 2024-01-20T14:30:00Z

3. devise
   URL: https://github.com/plataformatec/devise
   Root: https://github.com/heartcombo/devise
   Last activity: 2024-01-19T15:30:00Z

4. sidekiq
   URL: https://github.com/mperham/sidekiq
   Root: https://github.com/sidekiq/sidekiq
   Last activity: 2024-01-19T12:00:00Z
```

## Integration with Vendorer

Forker works seamlessly with the Vendorer gem for local development.

### Complete Workflow: Fork, Vendor, Develop, Push

**Step 1: Fork the gem on GitHub**

```bash
bin/forker fork --url=https://github.com/thoughtbot/factory_bot --account=myusername
```

**Step 2: Vendor your fork for local development**

```bash
bin/vendorer vendor factory_bot --url=https://github.com/myusername/factory_bot.git
```

**Step 3: Make changes in vendor/factory_bot/**

Edit files, add features, fix bugs...

**Step 4: Push changes to your fork**

```bash
bin/vendorer push factory_bot --branch=feature/my-awesome-feature --message="Add awesome feature"
```

**Step 5: Check PR status**

```bash
bin/forker prs
```

**Step 6: Monitor your fork's status**

```bash
bin/forker status
```

## Advanced Usage

### Working with Private Repositories

Forker works with private repositories as long as you have access through GitHub CLI.

```bash
# Ensure you're authenticated with appropriate permissions
gh auth status

# Fork a private repository
bin/forker fork --url=https://github.com/mycompany/private-gem --account=myusername
```

### Batch Operations

You can script Forker commands for batch operations.

**Example: Fork multiple gems at once**

```bash
#!/bin/bash

GEMS=(
  "rails/rails"
  "rspec/rspec-core"
  "thoughtbot/factory_bot"
  "heartcombo/devise"
)

for gem in "${GEMS[@]}"; do
  bin/forker fork --url="https://github.com/${gem}" --account=myusername
done
```

### Monitoring Fork Health

Create a script to check which forks are falling behind.

```bash
#!/bin/bash

# Get status and parse for forks that are more than 10 commits behind
bin/forker status | grep "behind:" | awk '$3 > 10 {print}'
```

## Troubleshooting

### GitHub CLI Not Authenticated

If you see authentication errors:

```bash
gh auth login
```

Follow the prompts to authenticate with GitHub.

### Rate Limiting

If you hit GitHub API rate limits, the commands will fail. Wait for the rate limit to reset or authenticate with a token that has higher limits.

### Fork Already Exists

If you try to fork a repository you've already forked:

```bash
bin/forker fork --url=https://github.com/rails/rails --account=myusername
```

You'll see an error. Use `bin/forker list` to see your existing forks.

## Tips and Best Practices

### Regular Status Checks

Set up a cron job or scheduled task to regularly check fork status:

```bash
# Add to crontab
0 9 * * * cd /path/to/project && bin/forker status
```

### Documenting Your Forks

Keep a README in your project documenting which gems you've forked and why:

```markdown
# Forked Gems

- **rails**: Custom patches for our deployment infrastructure
- **devise**: Added support for our custom authentication provider
- **sidekiq**: Performance optimizations for our workload
```

### Cleaning Up Old Forks

Periodically review your forks and delete ones you're no longer using:

```bash
# List your forks
bin/forker list --account=myusername

# Delete unused forks via GitHub CLI
gh repo delete myusername/unused-fork
```

### Collaboration Workflow

When working with a team:

1. One person forks the gem using Forker
2. Team members clone from the fork
3. Use Forker to monitor upstream changes
4. Coordinate PRs using `bin/forker prs`

## Real-World Use Cases

### Case Study 1: Enterprise Gem Management

A large company maintains forks of 50+ gems with custom patches. They use Forker to:

- Track which forks are falling behind upstream
- Monitor PR activity to see when their patches might be merged
- Discover other companies with similar forks for collaboration

### Case Study 2: Open Source Contributor

An active open source contributor uses Forker to:

- Manage forks of 20+ gems they contribute to
- Find other active contributors for collaboration
- Track PR status across all projects
- Identify which forks need attention

### Case Study 3: Gem Maintainer

A gem maintainer uses Forker to:

- Monitor all forks of their gem
- Identify the most active forks
- Reach out to fork maintainers about merging changes
- Track which features are being developed in forks
