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

## Example prompts

- "Schedule this announcement on LinkedIn and X for tomorrow at 9am, with a shorter version for X."
- "Turn https://example.com/blog/launch into posts for Instagram, Threads and Bluesky and save them as drafts."
- "Post this video as an Instagram Reel and a TikTok, with a first comment that links to our site."
- "Check this post for problems on every platform before you schedule it."
- "Which platforms failed on yesterday's post? Retry only those."
- "Repeat our weekly tips post every Monday at 10am."
- "Connect our blog's RSS feed so every new article becomes a LinkedIn draft."
- "What were my five best posts last month by engagement, and on which platforms?"
- "Create a connect link my client can use to add their Instagram and Facebook accounts."

## Tools

58 tools. Analytics cover Facebook, Instagram, Threads, TikTok, Pinterest, Bluesky, LinkedIn, YouTube, X and Google Business Profile. Google Business Profile reports location impressions only, with no per-post numbers. Mastodon, Telegram, Tumblr and WordPress have no analytics. Connecting an account imports its posts from the last 180 days. The upload box also calls `get_upload_ticket` once per file; that tool is hidden from the model.

### Workspaces and accounts

| Tool | What it does | Changes data |
| --- | --- | --- |
| `list_workspaces` | List the workspaces the sign-in can act in; pass an id as `workspaceId` to any other tool | No |
| `get_me` | What this connection may do in a workspace: role, permission keys and `can { draft, schedule, publish }` | No |
| `list_accounts` | List all connected social media accounts with IDs, platforms and `status` (`active` or `unauthorized`) | No |
| `check_account` | Re-check a Facebook page with Facebook and get its fresh `status` | Yes |
| `remove_account` | Disconnect an account from the workspace; it comes off pending and recurring posts | Yes |
| `create_connect_link` | Create a link a client opens to connect their accounts, optionally private, limited to some platforms, capped or never expiring | Yes |
| `revoke_connect_link` | Revoke a connect link | Yes |

### Posts

| Tool | What it does | Changes data |
| --- | --- | --- |
| `create_post` | Create a post: publish immediately, schedule, or save as draft (a draft can carry a planned date). Takes first comments, per-platform thumbnails and image shapes, Instagram and Facebook story sharing, Instagram collaborators, user tags, AI labels and Reel audio, Facebook text backgrounds and link carousels, LinkedIn reshares, X quotes of the account's own posts, threads of replies with images, Tumblr tags, WordPress titles, categories and tags, the YouTube audio language and Google Business Profile events and offers | Yes |
| `validate_post` | Dry-run `create_post` with the same input: every problem, per account, without creating anything | No |
| `get_post` | Get full details of a single post by ID | No |
| `list_posts` | List posts with filters by status, platform, date range | No |
| `update_post` | Update a scheduled or draft post | Yes |
| `delete_post` | Delete a post record; cancels a draft or scheduled post, never removes content already live | Yes |
| `unschedule_post` | Turn a scheduled post back into an undated draft without deleting it | Yes |
| `publish_draft` | Publish a draft post immediately or schedule it. Without a date, a draft with a future planned date is scheduled for it and any other draft publishes now; `publishNow: true` publishes now regardless | Yes |
| `list_post_results` | Check per-platform posting results, success or failure with error details | No |
| `retry_failed_platforms` | Retry publishing on platforms that failed | Yes |
| `bulk_schedule_posts` | Schedule up to 100 posts at once | Yes |
| `validate_bulk_posts` | Dry-run `bulk_schedule_posts`: one validation report per item | No |

### Media

| Tool | What it does | Changes data |
| --- | --- | --- |
| `upload_media` | Upload images, videos or documents from ChatGPT attachments, public URLs or base64 and get `mediaUrls` for a post | Yes |
| `get_upload_urls` | Mint presigned upload URLs for larger files; PUT the bytes, then use `publicUrl` | Yes |
| `open_upload_widget` | Show an upload box in ChatGPT or Claude chat so the user can add files from their device; the box sends back the `mediaUrls`. Where the box can't show (Claude Cowork, Claude Code), it returns an upload link instead; call it again with `uploadId` to get the `mediaUrls` | Yes |

### Platform options

| Tool | What it does | Changes data |
| --- | --- | --- |
| `search_instagram_audio` | Search Instagram music and original sounds to add to a Reel | No |
| `list_pinterest_boards` | List the boards of a Pinterest account; pass a board `id` as `pinterestConfigs[].boardId`, or its name as `boardName` (not both) | No |
| `list_wordpress_categories` | List the categories of a WordPress site; pass their `id`s as `wordpressConfigs[].categoryIds` | No |

### Recurring posts

| Tool | What it does | Changes data |
| --- | --- | --- |
| `list_recurring_posts` | List recurring posts (daily, weekly, monthly or yearly series made with `recurrence` on `create_post`) by status | No |
| `get_recurring_post` | Get one recurring post with its schedule, status and next occurrence | No |
| `pause_recurring_post` | Pause a recurring post and delete its upcoming scheduled post | Yes |
| `resume_recurring_post` | Resume a paused recurring post from the next occurrence after now | Yes |
| `delete_recurring_post` | Stop a recurring post for good; posts already published are kept | Yes |

### RSS feeds

| Tool | What it does | Changes data |
| --- | --- | --- |
| `list_rss_feeds` | List the RSS and Atom feeds that turn new items into posts, with why a paused one stopped | No |
| `get_rss_feed` | One RSS feed with its settings and status | No |
| `preview_rss_feed` | Fetch a feed without saving it and show the 5 newest items as posts | No |
| `create_rss_feed` | Connect a feed: each new item becomes a draft, a scheduled post or a published post on the target accounts | Yes |
| `update_rss_feed` | Change a feed's targets, mode, template, keywords or interval | Yes |
| `delete_rss_feed` | Stop a feed for good; its posts stay | Yes |
| `list_rss_feed_items` | What a feed did with each item: posted, filtered, skipped or failed | No |
| `pause_rss_feed` | Pause a feed | Yes |
| `resume_rss_feed` | Resume a paused feed | Yes |
| `check_rss_feed` | Check a feed now instead of waiting for its interval | Yes |

### Analytics

| Tool | What it does | Changes data |
| --- | --- | --- |
| `get_analytics_overview` | Views, likes, comments, shares, followers and engagement rate for a date window, with the change against the previous window | No |
| `get_analytics_timeseries` | The same metrics bucketed by day, week or month | No |
| `get_platform_breakdown` | The same metrics split per platform, with the metrics each platform reports | No |
| `list_post_analytics` | Per-post metrics, sortable by any metric, for top-post and "how did this post do" questions | No |
| `list_top_posts` | The best posts in a window by one metric, in one call | No |
| `list_discovered_posts` | Posts found on the connected accounts that were not published through AdaptlyPost | No |
| `get_analytics_sync_status` | When each account last synced and whether one needs reconnecting for analytics | No |
| `trigger_analytics_sync` | Refresh analytics now (once per 4 hours per workspace) | Yes |

### Webhooks

| Tool | What it does | Changes data |
| --- | --- | --- |
| `list_webhooks` | List webhook endpoints and their delivery state | No |
| `get_webhook` | One webhook endpoint | No |
| `create_webhook` | Register an endpoint for every event; the signing secret is shown only in this response | Yes |
| `update_webhook` | Change an endpoint's URL or turn it off and on | Yes |
| `delete_webhook` | Delete an endpoint | Yes |
| `test_webhook` | Send a signed `webhook.test` event and see how the endpoint answered | Yes |

### AI captions and images

| Tool | What it does | Changes data |
| --- | --- | --- |
| `generate_caption` | Write a caption from a prompt, kept within a platform's character limit; 2 AI credits | Yes |
| `refine_caption` | Rewrite an existing caption from an instruction, or continue a partial one; 2 AI credits | Yes |
| `generate_image` | Start an image generation and get a `jobId`; 2 credits standard, 4 premium | Yes |
| `get_image_job` | Poll an image job until `completed` (with a public `imageUrl`) or `failed` | No |

## Roles, permissions and safety

- Every call runs under a workspace role: Admin, Editor, Contributor or Viewer. An API key carries the role it was created with and never does more than the member who created it; an OAuth sign-in acts with the member's own role in each workspace.
- Admin does everything. Editor creates, schedules and publishes. Contributor creates and edits its own drafts, uploads media and generates captions and images, but cannot schedule, publish, retry, bulk schedule or delete non-drafts. Viewer only reads. Give an agent that should not post on its own a Contributor key, or sign in as a Contributor.
- An action outside the role answers 403 with `code: permission_denied`. The tool tells the agent to save a draft and ask a workspace member to publish, not to retry or look for another key.
- Read-only tools carry `readOnlyHint`, so clients that ask before a write (Claude, ChatGPT, Hermes) ask before creating, scheduling, publishing or deleting anything.
- `generate_caption`, `refine_caption` and `generate_image` spend AdaptlyPost AI credits on every call: 2 credits per caption, 2 or 4 per image.
- Without an API-capable plan every call answers 403 with `code: subscription_required`. A 429 carries `Retry-After`.

## FAQ

**Do I need an API key?**
No. Point your client at `https://mcp.adaptlypost.com/mcp` and sign in with the email you use on AdaptlyPost. Keys are for headless agents and clients without OAuth.

**Will the agent post without asking me?**
Every tool that creates, schedules, publishes or deletes is marked as a write, so clients that confirm writes ask first. For a hard limit, use a Contributor role: it can only save drafts.

**Which platforms can I post to?**
Instagram, TikTok, YouTube, X (Twitter), LinkedIn, Facebook, Pinterest, Threads, Bluesky, Mastodon, Google Business Profile, Tumblr, Telegram and WordPress.

**Can it upload my own photos and videos?**
Yes. `upload_media` takes public URLs, base64 or ChatGPT attachments; `open_upload_widget` shows an upload box in ChatGPT and Claude, or gives an upload link where a box can't show.

**Can I use AdaptlyPost outside Claude Code and Hermes?**
Yes. Claude Desktop, ChatGPT, Cursor, Windsurf, VS Code, Codex and Gemini CLI connect to the same server at `https://mcp.adaptlypost.com/mcp`. The setup for each is in [adaptlypost/agent](https://github.com/adaptlypost/agent#setup-by-client).

## Links

- Product: [adaptlypost.com](https://adaptlypost.com)
- AI agents: [adaptlypost.com/features/agents](https://adaptlypost.com/features/agents)
- Skill, MCP server and Gemini extension: [adaptlypost/agent](https://github.com/adaptlypost/agent)
- Privacy policy: [adaptlypost.com/privacy](https://adaptlypost.com/privacy)

## License

MIT
