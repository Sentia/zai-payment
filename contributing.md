# Contributing to Zai Payment

First off, thank you for considering contributing to Zai Payment! 🎉 It's people like you that make this library better for everyone.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Enhancements](#suggesting-enhancements)
  - [Your First Code Contribution](#your-first-code-contribution)
  - [Pull Requests](#pull-requests)
- [Development Setup](#development-setup)
- [Development Workflow](#development-workflow)
- [Style Guidelines](#style-guidelines)
  - [Git Commit Messages](#git-commit-messages)
  - [Ruby Style Guide](#ruby-style-guide)
  - [Documentation](#documentation)
- [Testing](#testing)
- [Community](#community)

---

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](code_of_conduct.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to [contact@sentia.com.au](mailto:contact@sentia.com.au).

---

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the [existing issues](https://github.com/Sentia/zai-payment/issues) as you might find that you don't need to create one. When you are creating a bug report, please include as many details as possible:

**Before Submitting A Bug Report:**
- Check the [documentation](https://rubydoc.info/gems/zai_payment) to confirm your understanding of the expected behavior
- Check if the issue has already been reported
- Perform a cursory search to see if the problem has been discussed or resolved

**How to Submit A Good Bug Report:**

Bugs are tracked as [GitHub issues](https://github.com/Sentia/zai-payment/issues). Create an issue and provide the following information:

- **Use a clear and descriptive title** for the issue to identify the problem
- **Describe the exact steps to reproduce the problem** in as much detail as possible
- **Provide specific examples** to demonstrate the steps (include code snippets)
- **Describe the behavior you observed** after following the steps
- **Explain which behavior you expected to see instead** and why
- **Include details about your environment**:
  - Ruby version (`ruby -v`)
  - Gem version (`bundle list | grep zai_payment`)
  - OS and version

### Suggesting Enhancements

Enhancement suggestions are tracked as [GitHub issues](https://github.com/Sentia/zai-payment/issues). When creating an enhancement suggestion, please include:

- **Use a clear and descriptive title**
- **Provide a detailed description** of the suggested enhancement
- **Provide specific examples** to demonstrate the use case
- **Describe the current behavior** and **explain the desired behavior**
- **Explain why this enhancement would be useful** to most users
- **List any similar features** in other libraries that inspired the suggestion

### Your First Code Contribution

Unsure where to begin contributing? You can start by looking through these issues:

- **Good First Issue** - issues that should only require a few lines of code
- **Help Wanted** - issues that may be more involved

### Pull Requests

Please follow these steps to have your contribution considered by the maintainers:

1. **Fork the repository** and create your branch from `main`
2. **Make your changes** following our [style guidelines](#style-guidelines)
3. **Add or update tests** as needed
4. **Ensure the test suite passes** (`bundle exec rspec`)
5. **Run the linter** and fix any issues (`bundle exec rubocop`)
6. **Update the documentation** if you've changed APIs or added features
7. **Write clear commit messages** following our [commit message guidelines](#git-commit-messages)
8. **Open a pull request** with a clear title and description

**Pull Request Guidelines:**
- Keep changes focused - one feature/fix per PR
- Link any relevant issues in the PR description
- Update changelog.md if appropriate
- Maintain backward compatibility when possible
- Include tests for new functionality
- Follow the existing code style

---

## Development Setup

### Prerequisites

- **Ruby** 3.0 or higher
- **Bundler** 2.0 or higher
- **Git**

### Getting Started

1. **Fork and clone the repository:**

```bash
git clone git@github.com:Sentia/zai-payment.git
cd zai-payment
```

2. **Install dependencies:**

```bash
bin/setup
```

This will:
- Install all required gems
- Set up git hooks (if applicable)
- Prepare your development environment

3. **Verify your setup:**

```bash
bundle exec rspec
bundle exec rubocop
```

All tests should pass and there should be no linting errors.

### Interactive Console

For quick testing and experimentation:

```bash
bin/console
```

This launches an IRB session with the gem loaded and ready to use.

---

## Development Workflow

### Branch Naming

Use descriptive branch names that reflect the work being done:

- `feature/description` - for new features
- `bugfix/description` - for bug fixes
- `docs/description` - for documentation changes
- `refactor/description` - for code refactoring
- `test/description` - for test improvements

Examples:
- `feature/add-payment-resource`
- `bugfix/fix-token-refresh`
- `docs/improve-webhook-examples`

### Making Changes

1. **Create a feature branch:**

```bash
git checkout -b feature/my-new-feature
```

2. **Make your changes** following our style guidelines

3. **Write or update tests:**

```bash
bundle exec rspec
```

4. **Check code quality:**

```bash
bundle exec rubocop
# Auto-fix issues when possible
bundle exec rubocop -a
```

5. **Commit your changes:**

```bash
git add .
git commit -m "feat: add awesome new feature"
```

6. **Push to your fork:**

```bash
git push origin feature/my-new-feature
```

7. **Open a Pull Request** on GitHub

---

## Style Guidelines

### Git Commit Messages

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

**Format:**
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat:` - A new feature
- `fix:` - A bug fix
- `docs:` - Documentation only changes
- `style:` - Changes that don't affect code meaning (whitespace, formatting)
- `refactor:` - Code change that neither fixes a bug nor adds a feature
- `perf:` - Performance improvements
- `test:` - Adding or updating tests
- `chore:` - Changes to build process or auxiliary tools

**Examples:**
```
feat(webhooks): add support for webhook signature verification

fix(auth): prevent token refresh race condition

docs: update readme with webhook examples

test(client): add specs for error handling
```

**Guidelines:**
- Use present tense ("add feature" not "added feature")
- Use imperative mood ("move cursor to..." not "moves cursor to...")
- First line should be 50 characters or less
- Reference issues and pull requests after the first line

### Ruby Style Guide

This project follows the [Ruby Style Guide](https://rubystyle.guide/) and uses [RuboCop](https://github.com/rubocop/rubocop) for enforcement.

**Key principles:**
- Use 2 spaces for indentation (no tabs)
- Keep line length to 120 characters or less
- Use `snake_case` for methods and variables
- Use `CamelCase` for classes and modules
- Write clear, self-documenting code
- Add comments for complex logic
- Follow existing patterns in the codebase

**Run RuboCop:**
```bash
# Check for issues
bundle exec rubocop

# Auto-fix issues when possible
bundle exec rubocop -a
```

### Documentation

- **Public APIs must be documented** using YARD syntax
- **Include examples** in documentation when helpful
- **Update readme.md** when adding new features
- **Update relevant docs/** files for architectural changes
- **Keep changelog.md** updated with notable changes

**YARD Documentation Example:**
```ruby
# Fetches a webhook by its ID
#
# @param id [String] the webhook ID
# @return [ZaiPayment::Response] the response containing webhook data
# @raise [ZaiPayment::Errors::NotFoundError] if webhook doesn't exist
#
# @example
#   response = client.webhooks.get('wh_123')
#   webhook = response.data
#
def get(id)
  # implementation
end
```

---

## Testing

This project uses [RSpec](https://rspec.info/) for testing.

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/zai_payment/client_spec.rb

# Run specific test
bundle exec rspec spec/zai_payment/client_spec.rb:10

# Run with coverage report
bundle exec rspec --format documentation
```

### Writing Tests

- **Write tests for all new features and bug fixes**
- **Use descriptive test names** that explain what is being tested
- **Follow the Arrange-Act-Assert pattern**
- **Use factories or fixtures** for test data
- **Mock external API calls** using VCR or WebMock
- **Aim for high test coverage** (we target 90%+ coverage)

**Test Example:**
```ruby
RSpec.describe ZaiPayment::Client do
  describe '#initialize' do
    context 'with valid configuration' do
      it 'creates a client instance' do
        config = ZaiPayment::Config.new
        client = described_class.new(config: config)
        
        expect(client).to be_a(described_class)
      end
    end

    context 'without configuration' do
      it 'uses default configuration' do
        client = described_class.new
        
        expect(client.config).to be_a(ZaiPayment::Config)
      end
    end
  end
end
```

### Test Coverage

- Coverage reports are generated automatically with SimpleCov
- View coverage reports in `coverage/index.html`
- New code should maintain or improve overall coverage
- Don't write tests just to increase coverage - write meaningful tests

---

## Community

### Questions?

- **GitHub Discussions** - For general questions and discussions
- **GitHub Issues** - For bugs and feature requests
- **Email** - [contact@sentia.com.au](mailto:contact@sentia.com.au)

### Recognition

Contributors will be recognized in:
- The project's readme (if significant contribution)
- The CHANGELOG for their specific contributions
- Release notes

### Need Help?

Don't hesitate to ask questions! We're here to help:
- Comment on an issue you'd like to work on
- Open a discussion for clarification
- Reach out via email

---

## Thank You! 🙏

Your contributions to open source, large or small, make projects like this possible. Thank you for taking the time to contribute!

