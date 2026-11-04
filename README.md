# AdaptlyPost plugin for Claude Code and Hermes Agent

[![smithery badge](https://smithery.ai/badge/tarasshyn/adaptlypost)](https://smithery.ai/servers/tarasshyn/adaptlypost)

Post and schedule to **14 social media platforms** from Claude Code: Instagram, TikTok, YouTube, X (Twitter), LinkedIn, Facebook, Pinterest, Threads, Bluesky, Mastodon, Google Business Profile, Tumblr, Telegram and WordPress.

## Install in Claude Code

```
/plugin marketplace add adaptlypost/claude-plugin
/plugin install adaptlypost
```

## Setup

1. Create an account at [adaptlypost.com](https://adaptlypost.com) and connect your social media accounts.
2. In Claude Code, run `/mcp`, pick `adaptlypost` and sign in with the email you use on AdaptlyPost.

The plugin talks to AdaptlyPost only through its MCP server at `mcp.adaptlypost.com`, signed in with OAuth. It never asks for an API key and reads nothing from your environment or config files.

### Workspaces and roles

A sign-in reaches every workspace you belong to. Claude calls `list_workspaces` to see them and passes a workspace id to the other tools; without one it works in the workspace `list_workspaces` marks `current`.

In each workspace Claude acts with your own role there. Admin does everything, Editor creates, schedules and publishes, Contributor creates and edits its own drafts, uploads media and generates captions and images but cannot schedule or publish, Viewer reads.

An operation outside the role answers 403 with `code: permission_denied`. The skill tells Claude to stop, save a draft where that applies, and ask a workspace member to publish, instead of retrying.

## Install in Hermes Agent

You need Hermes Agent 0.21.6 or newer and Node.js 20.18.1 or newer with `npx` on your `PATH`.

From the Hermes plugin catalog:

```bash
hermes plugins install adaptlypost
hermes plugins enable adaptlypost
```

Or straight from GitHub:

```bash
hermes plugins install adaptlypost/claude-plugin --no-enable
hermes plugins enable adaptlypost
```

Start a new session. The first time the server starts, your browser opens the AdaptlyPost sign-in page. Sign in with the email you use on AdaptlyPost and approve. The token is kept and refreshed, so you sign in once. If the tools don't show up after you sign in, run `/reload-mcp`.

The Hermes package is `plugin.json`, `mcp.json` and the skill in `skills/adaptlypost/`. It ships no code of its own. Before you install, know that:

- `mcp.json` runs the pinned `mcp-remote@0.1.49` through `npx`, which downloads it from npm on first use. It opens a local callback port for the sign-in and stores the OAuth tokens in `~/.mcp-auth`.
- Every tool call goes to `mcp.adaptlypost.com` and acts on your AdaptlyPost account, with your own role in each workspace. The server decides the tool set at runtime, so the pinned commit doesn't cover it.
- `plugin.json` marks the server `untrusted`. Hermes asks before every tool the server doesn't mark read-only (creating, scheduling, publishing and deleting posts, removing accounts, connect links, webhooks and AI generation), and refuses those tools in cron and other unattended runs.
- A post you publish goes out to your connected social accounts. `generate_caption`, `refine_caption` and `generate_image` spend AdaptlyPost AI credits.
- The package sends no telemetry.

On a server or another machine without a browser, skip the plugin and add the server to `~/.hermes/config.yaml` with an API key from [adaptlypost.com/api-tokens](https://adaptlypost.com/api-tokens):

```yaml
mcp_servers:
  adaptlypost:
    url: "https://mcp.adaptlypost.com/mcp"
    headers:
      Authorization: "Bearer ${ADAPTLYPOST_API_KEY}"
```

Put `ADAPTLYPOST_API_KEY=...` in `~/.hermes/.env`. The key works like a password for your AdaptlyPost account, so don't paste it into a chat.

## What it does

Once installed, Claude can:

- **Post** to 14 platforms simultaneously with per-platform caption overrides
- **Schedule** posts for any future time
- **Bulk schedule** up to 100 posts at once
- **Check results** per-platform with success/failure and error details
- **Retry** just the failed platforms
- **Draft, then publish**: save drafts, review, publish later
- **Repeat** a post daily, weekly, monthly or yearly, then pause, resume or stop the series
- **Read analytics**: views, likes, comments, followers and engagement per window, per platform and per post
- **Write captions and generate images** with AdaptlyPost AI, paid from your AI credits

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
