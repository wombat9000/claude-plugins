# Claude Plugin Marketplace

A marketplace for Claude Code agent configuration plugins.

## Overview

This repository provides a plugin marketplace for Claude Code extensions. Users can discover, install, and manage plugins distributed through this marketplace.

## Using This Marketplace

### 1. Add the marketplace to Claude Code

```shell
/plugin marketplace add autostein/agent-configs
```

Or if using a git URL:

```shell
/plugin marketplace add https://github.com/autostein/agent-configs.git
```

### 2. Browse available plugins

```shell
/plugin
```

### 3. Install plugins from this marketplace

```shell
/plugin install plugin-name@agent-configs-marketplace
```

## Available Plugins

### example-plugin

An example plugin demonstrating marketplace functionality.

**Category**: utilities
**Version**: 1.0.0
**License**: MIT

## For Plugin Developers

### Adding New Plugins to This Marketplace

#### 1. Create your plugin

Add your plugin to `.claude-plugin/plugins/your-plugin-name/`:

```
.claude-plugin/plugins/your-plugin-name/
├── plugin.json          # Plugin manifest
├── commands/           # Custom slash commands
│   └── your-command.md
├── agents/            # Custom agents
│   └── your-agent.md
├── hooks/             # Optional hooks
└── README.md          # Plugin documentation
```

#### 2. Update marketplace.json

Add your plugin entry to `.claude-plugin/marketplace.json`:

```json
{
  "name": "your-plugin-name",
  "source": "./plugins/your-plugin-name",
  "description": "Brief description of your plugin",
  "version": "1.0.0",
  "author": {
    "name": "Your Name",
    "email": "your.email@example.com"
  },
  "keywords": ["tag1", "tag2"],
  "category": "category-name",
  "license": "MIT"
}
```

#### 3. Test your plugin

```shell
# Add local marketplace for testing
/plugin marketplace add ./path/to/this/repo

# Install and test your plugin
/plugin install your-plugin-name@agent-configs-marketplace
```

#### 4. Submit your plugin

Create a pull request with:
1. Your plugin files in `.claude-plugin/plugins/your-plugin-name/`
2. Updated marketplace.json entry
3. Documentation in your plugin's README.md

### Plugin Structure

Each plugin should include:

- **plugin.json**: Required manifest file with metadata and configuration
- **commands/**: Optional directory containing slash command markdown files
- **agents/**: Optional directory containing agent definition markdown files
- **hooks/**: Optional directory for hook configurations
- **README.md**: Documentation for your plugin

## Marketplace Configuration

The marketplace is configured in `.claude-plugin/marketplace.json`:

```json
{
  "name": "agent-configs-marketplace",
  "owner": {
    "name": "Autostein",
    "email": "contact@autostein.com"
  },
  "metadata": {
    "description": "A marketplace for Claude Code agent configuration plugins",
    "version": "1.0.0",
    "pluginRoot": "./plugins"
  },
  "plugins": [
    // Plugin entries...
  ]
}
```

## Team Configuration

For automatic marketplace installation in team projects, add to `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "agent-configs": {
      "source": {
        "source": "github",
        "repo": "autostein/agent-configs"
      }
    }
  }
}
```

## Validation

Validate your marketplace configuration:

```bash
claude plugin validate .
```

## Contributing

We welcome contributions! Please:

1. Follow the plugin structure guidelines
2. Include comprehensive documentation
3. Test your plugin before submitting
4. Keep plugins focused and well-scoped
5. Use semantic versioning

## License

MIT

## Support

For issues or questions:
- Open an issue on GitHub
- Contact: contact@autostein.com

## Learn More

- [Claude Code Plugin Documentation](https://docs.claude.com/en/docs/claude-code/plugins)
- [Plugin Marketplace Guide](https://docs.claude.com/en/docs/claude-code/plugin-marketplaces)
- [Plugin Development](https://docs.claude.com/en/docs/claude-code/plugins#develop-more-complex-plugins)