# AdaptlyPost — Claude Code Plugin

[![smithery badge](https://smithery.ai/badge/tarasshyn/adaptlypost)](https://smithery.ai/servers/tarasshyn/adaptlypost)

Post and schedule to **10 social media platforms** from Claude Code: Instagram, TikTok, YouTube, X (Twitter), LinkedIn, Facebook, Pinterest, Threads, Bluesky, and Mastodon.

## Install

```
/plugin marketplace add adaptlypost/claude-plugin
/plugin install adaptlypost
```

## Setup

1. Create an account at [adaptlypost.com](https://adaptlypost.com)
2. Connect your social media accounts
3. Generate an API token at [Settings → API Tokens](https://adaptlypost.com/api-tokens) and pick its role
4. From inside Claude Code:
   ```
   ./scripts/adaptlypost.js setup --key adaptly_xxxxx
   ```

### Roles

A token is issued under a workspace role and never does more than the member who created it. Admin does everything, Editor creates, schedules and publishes, Contributor creates and edits its own drafts and uploads media but cannot schedule or publish, Viewer reads. Contributor is the safe choice when Claude should not post on its own.

`./scripts/adaptlypost.js whoami` shows the role, the permission list and `can { draft, schedule, publish }`. An operation outside the role answers 403 with `code: permission_denied`; the skill tells Claude to stop, save a draft where that applies, and ask a workspace member to publish, instead of retrying or hunting for another key.

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

## License

MIT
