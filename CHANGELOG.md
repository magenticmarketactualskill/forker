# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2024-11-29

### Added
- Initial release of Forker gem
- `forker list` command to list all forks for a GitHub account
- `forker fork` command to fork a repository on GitHub
- `forker status` command to show status of tracked forks
- `forker peers` command to list other forks of the same repositories
- `forker prs` command to list pull requests across fork network
- `forker active` command to show most recently active forks
- Local metadata storage in `.forker/` directory
- GitHub CLI integration for all GitHub operations
- Automatic root repository identification
- Fork relationship tracking
- RSpec test suite
- Cucumber feature tests
- Comprehensive documentation

### Features
- Track fork relationships and identify root/upstream repositories
- Monitor activity across the fork network
- Discover other contributors and their work
- Cache fork metadata locally for fast access
- Compare fork status with upstream (commits ahead/behind)

[0.1.0]: https://github.com/magenticmarketactualskill/forker/releases/tag/v0.1.0
