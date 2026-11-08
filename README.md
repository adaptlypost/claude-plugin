# AdaptlyPost plugin for Claude Code and Hermes Agent

Draft, schedule, publish and measure posts on Instagram, TikTok, YouTube, X (Twitter), LinkedIn, Facebook, Pinterest, Threads, Bluesky, Mastodon, Google Business Profile, Tumblr, Telegram and WordPress, all 14 platforms AdaptlyPost supports, from Claude Code or Hermes Agent.

## What this repo is

This repo is the AdaptlyPost plugin for Claude Code and Hermes Agent, and nothing else. Both read the same package: `.claude-plugin/plugin.json`, `.mcp.json` and `.claude-plugin/marketplace.json` for Claude Code, `plugin.json` and `mcp.json` for Hermes, and one skill in [`skills/adaptlypost/`](./skills/adaptlypost). The plugin connects to the hosted MCP server at `https://mcp.adaptlypost.com/mcp`, signs in with OAuth and never asks for an API key. Its skill only calls MCP tools and ships no script, because the Claude plugin directory and the Hermes catalog both review for that.

Everything else lives in [adaptlypost/agent](https://github.com/adaptlypost/agent): the agent skill for `npx skills add` (a CLI script with an API key), the source of the MCP server, and the Gemini CLI extension.

| You use | Install | Sign-in |
| --- | --- | --- |
| Claude Code | `/plugin install adaptlypost --marketplace adaptlypost/claude-plugin` | OAuth |
| Hermes Agent | `hermes plugins install adaptlypost` | OAuth |
| Gemini CLI | `gemini extensions install https://github.com/adaptlypost/agent` | OAuth |
| Claude Desktop, Cursor, ChatGPT or any MCP client | Add `https://mcp.adaptlypost.com/mcp` as a remote server | OAuth, or an API key header |
| Cursor, Codex, Windsurf, Claude Code or any agent with skills | `npx skills add adaptlypost/agent` | API key |

## Install in Claude Code

```
/plugin install adaptlypost --marketplace adaptlypost/claude-plugin
```

On Claude Code older than 2.1.275, add the marketplace first:

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

Once installed, Claude or Hermes can:

- Post to any of the 14 platforms in one call, with per-platform captions, first comments, thumbnails and image shapes
- Check a post before creating it, and get every problem back at once
- Schedule for any future time, or bulk schedule up to 100 posts
- See per-platform results with error details, and retry only the platforms that failed
- Save drafts and publish them later
- Repeat a post daily, weekly, monthly or yearly, then pause, resume or stop the series
- Turn new RSS feed items into drafts or posts
- Read analytics: views, likes, comments, followers and engagement per window, per platform and per post
- Manage webhooks and client connect links, and check or remove connected accounts
- Write captions and generate images with AdaptlyPost AI, paid from your AI credits
- Work in any workspace your sign-in reaches, with your own role there

## Example

```
You: Schedule a LinkedIn post for tomorrow at 9am about our feature launch.
Agent: Done. Post scheduled for tomorrow at 9:00 AM on your LinkedIn account.
```

## Links

- Product: [adaptlypost.com](https://adaptlypost.com)
- AI agents: [adaptlypost.com/features/agents](https://adaptlypost.com/features/agents)
- Skill, MCP server and Gemini extension: [adaptlypost/agent](https://github.com/adaptlypost/agent)
- Privacy policy: [adaptlypost.com/privacy](https://adaptlypost.com/privacy)

## License

MIT
