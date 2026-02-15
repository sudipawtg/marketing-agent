# Contributing to Marketing Agent Workflow

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to this project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [CI/CD Pipeline](#cicd-pipeline)

## Code of Conduct

Please be respectful and constructive in all interactions. We aim to maintain a welcoming and inclusive environment for all contributors.

## Getting Started

### Prerequisites

- Python 3.11+
- Node.js 18+
- Docker & Docker Compose
- Git
- Make

### Setup Development Environment

1. **Fork and clone the repository**
   ```bash
   git clone https://github.com/your-username/marketing-agent-workflow.git
   cd marketing-agent-workflow
   ```

2. **Install dependencies**
   ```bash
   make install
   ```

3. **Install pre-commit hooks**
   ```bash
   make install-pre-commit
   ```

4. **Start development environment**
   ```bash
   make dev
   ```

## Development Workflow

1. **Create a feature branch**
   ```bash
   git checkout -b feat/your-feature-name
   ```

2. **Make your changes**
   - Write code following our coding standards
   - Add tests for new functionality
   - Update documentation as needed

3. **Run tests locally**
   ```bash
   make test
   make lint
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add new feature"
   ```
   Pre-commit hooks will run automatically.

5. **Push and create pull request**
   ```bash
   git push origin feat/your-feature-name
   ```

## Coding Standards

### Python

- **Style**: Follow PEP 8, enforced by Black and Ruff
- **Line length**: 100 characters
- **Type hints**: Use type hints for all function signatures
- **Docstrings**: Use Google-style docstrings

Example:
```python
def process_data(input_data: dict[str, Any]) -> list[str]:
    """Process input data and return list of results.
    
    Args:
        input_data: Dictionary containing input parameters
        
    Returns:
        List of processed result strings
        
    Raises:
        ValueError: If input_data is invalid
    """
    pass
```

### TypeScript/React

- **Style**: Follow Airbnb style guide
- **Formatting**: Use Prettier
- **Components**: Use functional components with TypeScript
- **Naming**: PascalCase for components, camelCase for variables

Example:
```typescript
interface Props {
  title: string;
  onSubmit: (data: FormData) => void;
}

export const MyComponent: React.FC<Props> = ({ title, onSubmit }) => {
  // Component implementation
};
```

## Testing Guidelines

### Backend Tests

- **Unit tests**: Test individual functions and classes
- **Integration tests**: Test API endpoints and database interactions
- **Coverage**: Maintain >70% code coverage

```python
# tests/unit/test_example.py
import pytest

def test_example_function():
    """Test example function with various inputs."""
    assert example_function("input") == "expected"
```

### Frontend Tests

- Write tests for components and utilities
- Test user interactions and state changes

### Running Tests

```bash
# All tests
make test

# Unit tests only
make test-unit

# Integration tests only
make test-integration

# With coverage
make test-coverage
```

## Commit Guidelines

We follow [Conventional Commits](https://www.conventionalcommits.org/) specification.

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, etc.)
- **refactor**: Code refactoring
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **build**: Build system changes
- **ci**: CI/CD changes
- **chore**: Other changes that don't modify src or test files

### Examples

```bash
feat(agent): add new reasoning step for campaign analysis
fix(api): resolve authentication token expiration issue
docs(readme): update installation instructions
test(agent): add unit tests for signal processing
ci(workflows): update deployment pipeline configuration
```

## Pull Request Process

1. **Ensure all CI checks pass**
   - Linting and formatting
   - All tests passing
   - Code coverage maintained
   - Security scans clean

2. **Update documentation**
   - Update README if adding features
   - Add/update docstrings
   - Update API documentation

3. **Write descriptive PR description**
   - What changes were made
   - Why these changes are needed
   - How to test the changes
   - Link related issues

4. **Request review**
   - At least one approval required
   - Address all review comments

5. **Merge requirements**
   - All CI checks passing
   - Approved by reviewer(s)
   - No merge conflicts
   - Up to date with base branch

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
How was this tested?

## Checklist
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] CI passing
- [ ] No new warnings
```

## CI/CD Pipeline

Our CI/CD pipeline automatically:

1. **On every push/PR:**
   - Runs linting and formatting checks
   - Executes all tests
   - Checks code coverage
   - Scans for security vulnerabilities
   - Validates Docker builds

2. **On merge to main:**
   - Deploys to staging environment
   - Runs smoke tests

3. **On version tags:**
   - Deploys to production (with approval)
   - Creates GitHub release

See [CI/CD documentation](docs/CI_CD_PIPELINE.md) for details.

## Project Structure

```
marketing-agent-workflow/
├── src/                    # Backend source code
│   ├── agent/             # Agent logic
│   ├── api/               # API endpoints
│   └── database/          # Database models
├── frontend/              # Frontend source code
│   └── src/
│       ├── components/    # React components
│       └── pages/         # Page components
├── tests/                 # Test files
├── infrastructure/        # Infrastructure configs
│   ├── docker/           # Dockerfiles
│   └── k8s/              # Kubernetes manifests
├── scripts/              # Utility scripts
└── docs/                 # Documentation
```

## Questions?

- Create an issue for bugs or feature requests
- Check existing documentation
- Review closed issues for similar questions

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.
