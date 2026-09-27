# AdaptlyPost — Claude Code Plugin

[![smithery badge](https://smithery.ai/badge/tarasshyn/adaptlypost)](https://smithery.ai/servers/tarasshyn/adaptlypost)

Post and schedule to **10 social media platforms** from Claude Code: Instagram, TikTok, YouTube, X (Twitter), LinkedIn, Facebook, Pinterest, Threads, Bluesky, and Mastodon.

## Install

```
/plugin marketplace add adaptlypost/claude-plugin
/plugin install adaptlypost
```

## Setup

1. Create an account at [adaptlypost.com](https://adaptlypost.com) and connect your social media accounts.
2. In Claude Code, run `/mcp`, pick `adaptlypost` and sign in with the email you use on AdaptlyPost.

The plugin talks to AdaptlyPost only through its MCP server at `mcp.adaptlypost.com`, signed in with OAuth. It never asks for an API key and reads nothing from your environment or config files.

### Workspaces and roles

A sign-in reaches every workspace you belong to. Claude calls `list_workspaces` to see them and passes a workspace id to the other tools; without one it works in your default workspace.

In each workspace Claude acts with your own role there. Admin does everything, Editor creates, schedules and publishes, Contributor creates and edits its own drafts and uploads media but cannot schedule or publish, Viewer reads.

An operation outside the role answers 403 with `code: permission_denied`. The skill tells Claude to stop, save a draft where that applies, and ask a workspace member to publish, instead of retrying.

## What it does

Once installed, Claude can:

- **Post** to 10 platforms simultaneously with per-platform caption overrides
- **Schedule** posts for any future time
- **Bulk schedule** up to 100 posts at once
- **Check results** per-platform with success/failure and error details
- **Retry** just the failed platforms
- **Draft → publish** workflow — save drafts, review, publish later
- **Read analytics** — views, likes, comments, followers and engagement per window, per platform and per post

## Example

```
You: Schedule a LinkedIn post for tomorrow at 9am about our feature launch.
Claude: Done. Post scheduled for tomorrow at 9:00 AM on your LinkedIn account.
```

## Alternative: MCP

For Claude Desktop, Cursor, or other MCP-compatible clients:

```json
{
  "mcpServers": {
    "adaptlypost": {
      "type": "http",
      "url": "https://mcp.adaptlypost.com/mcp",
      "headers": { "Authorization": "Bearer adaptly_your_key" }
    }
  }
}
```

[MCP setup docs →](https://adaptlypost.com/features/agents)

## Links

- Product: [adaptlypost.com](https://adaptlypost.com)
- AI Agents: [adaptlypost.com/features/agents](https://adaptlypost.com/features/agents)
- API Tokens: [adaptlypost.com/api-tokens](https://adaptlypost.com/api-tokens)
- Privacy policy: [adaptlypost.com/privacy](https://adaptlypost.com/privacy)

## License

MIT
