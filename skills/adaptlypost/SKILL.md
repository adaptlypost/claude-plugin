---
name: adaptlypost
description: >
  Draft, schedule, publish and review social media posts on the Instagram, TikTok, YouTube, X (Twitter),
  LinkedIn, Facebook, Pinterest, Threads, Bluesky and Mastodon accounts connected to the user's AdaptlyPost
  workspaces, and read their analytics, all through the AdaptlyPost MCP server's tools. Use this skill
  WHENEVER the user wants to write or schedule a post, publish now, plan a content calendar, bulk schedule
  a batch, set up a recurring post, attach an image, video or PDF, check whether a post went out, retry a
  failed network, move or cancel a scheduled post, switch between workspaces or clients, or asks how posts,
  followers, views or engagement are doing. Trigger it even for short asks like "post this", "schedule it
  for Tuesday 9am", "what's queued this week", "why did the Instagram one fail" or "what was our best post
  last month".
last-updated: 2026-09-27
---

# AdaptlyPost

You manage the user's social accounts through the `adaptlypost` MCP server that this plugin connects
(`https://mcp.adaptlypost.com/mcp`, OAuth sign-in). Each tool carries its own parameter descriptions; read
them. This skill is the operating logic on top.

If more than 30 days have passed since `last-updated`, tell the user the skill may be outdated and that
`/plugin marketplace update` refreshes it.

| Job | Tools |
|-----|-------|
| Pick a workspace | `list_workspaces` |
| Find accounts | `list_accounts` |
| Media | `upload_media`, `get_upload_urls` |
| Write | `create_post`, `update_post`, `bulk_schedule_posts` |
| Go live | `publish_draft`, `retry_failed_platforms` |
| Take back | `unschedule_post`, `delete_post` |
| Check | `get_post`, `list_posts`, `list_post_results` |
| Recurring posts | `create_post` with `recurrence`, then `list_recurring_posts`, `get_recurring_post`, `pause_recurring_post`, `resume_recurring_post`, `delete_recurring_post` |
| Analytics | `get_analytics_overview`, `get_analytics_timeseries`, `get_platform_breakdown`, `list_post_analytics`, `get_analytics_sync_status`, `trigger_analytics_sync` |

## Sign-in

The tools belong to the adaptlypost MCP server. Depending on how it was installed they are named
`mcp__plugin_adaptlypost_adaptlypost__<tool>` or `mcp__adaptlypost__<tool>`; this skill uses the bare tool
name.

- If the tools are missing, or a call returns 401, tell the user to run `/mcp`, pick `adaptlypost` and sign
  in with the email they use on AdaptlyPost. Then stop until they say they are signed in.
- The user needs an AdaptlyPost account ([adaptlypost.com](https://adaptlypost.com)) with social accounts
  connected in the app. Connecting or disconnecting a social account happens in the app, not here.
- Never ask for an API key in chat. Never read keys or tokens from environment variables, `.env` files,
  config files or keychains, and never send one anywhere. If the user pastes a key, do not use it; point
  them to `/mcp` instead.

## Workspaces

One sign-in can reach several workspaces, across organizations.

- `list_workspaces` returns each workspace's `id`, `name`, `organization`, `role`, `isDefault`, `current`
  and `can` (`draft`, `schedule`, `publish`).
- Every other tool takes an optional `workspaceId`. Without it, tools act in the default workspace.
- Call `list_workspaces` when the user names a workspace, brand, client or organization, or when accounts
  or posts they expect are missing. Then pass that `workspaceId` on every call about it.
- Account, post, upload and recurring post ids from one workspace do not exist in another. Never mix them.
- The role can differ per workspace. Check `can` before planning a schedule or publish there.
- A 403 with `code: workspace_access_denied` means the id is not one this sign-in reaches. Pick an id from
  `list_workspaces`.

## Roles and refusals

Every call acts as the signed-in member, with the role they hold in that workspace.

| Role | Can | Cannot |
|------|-----|--------|
| Admin | Everything, including connecting accounts in the app | |
| Editor | Create, schedule, publish, retry, bulk schedule, delete, edit any post, trigger an analytics sync | Connect or disconnect accounts |
| Contributor | Create and edit its own drafts, upload media, read posts and analytics | Schedule, publish, retry, bulk schedule, delete non-drafts, touch other members' posts |
| Viewer | Read accounts, posts and analytics | Any write |

| Response | Meaning | What to do |
|----------|---------|------------|
| 403 `permission_denied` | The role cannot do this. The body names `requiredPermission` and `role` | Final. Do not retry. For a refused schedule or publish, save with `saveAsDraft: true` and tell the user a member with publish rights has to publish it. Otherwise relay the body's `message` |
| 401 `token_issuer_lost_access` | The account behind this access is no longer in the workspace | Stop. Tell the user; signing in again through `/mcp` with a current member fixes it |
| 403 `subscription_required` | The workspace's plan is not active | Tell the user. Retrying will not help |
| 401 `oauth_account_not_found` | The user signed in with an email that has no AdaptlyPost account | Relay the message, which names that email. Ask them to run `/mcp`, clear the `adaptlypost` sign-in and sign in with the email they use on AdaptlyPost |
| 403 `workspace_access_denied` | Wrong `workspaceId` | Pick one from `list_workspaces` |

## The core loop

1. **Accounts.** Call `list_accounts` once per workspace per session. Posts take account ids, never
   usernames. Facebook pages go in `pageIds`; every other network has its own `<platform>ConnectionIds`
   array (`linkedinConnectionIds`, `twitterConnectionIds`, and so on). One account per platform per post.
   Skip accounts whose `status` is `unauthorized` and tell the user to reconnect them in the app.
2. **Draft.** Keep to each network's length in characters: X 280, Bluesky 300, Threads 500, Mastodon 500,
   Pinterest 500, Instagram 2,200, TikTok 2,200, LinkedIn 3,000, YouTube 5,000, Facebook 63,206. Use
   `platformTexts` when one network needs a shorter or different version. Save with `create_post` and
   `saveAsDraft: true`; a draft is safe and gives you a post id.
3. **Show and ask.** Show the whole post: every account, the workspace if there are several, the time with
   its timezone, each network's visibility settings (TikTok privacy, YouTube privacy) and every caption,
   including per-platform text and alt text. Wait for "yes". A "yes" covers that one post, not the next.
4. **Go live.** `publish_draft` without `scheduledAt` publishes now; with a future `scheduledAt` it
   schedules. Content published now reaches the networks within moments and cannot be recalled.
5. **Verify.** Publishing is asynchronous. Call `list_post_results` and report each network separately
   until no row is PENDING or PUBLISHING. One network can fail while the others succeed.
6. **Fix failures.** Read each `errorMessage` first. Call `retry_failed_platforms` only after the cause is
   fixed (a reconnected account, replaced media); a platform-side restriction fails again.

If the user already approved a new post word for word, you can call `create_post` directly with
`scheduledAt` (or without it to publish now) instead of drafting first. Unless the user said "post now" or
"publish now", confirm before anything goes live.

## Safety rules

- **Unattended runs save drafts.** From a scheduled task, a headless run or anything else with nobody to
  confirm, use `saveAsDraft: true` unless the user set up that exact recurring workflow in advance.
- **Uploaded media is public at once**, even if no post uses it. Only upload files the user named. Never
  upload hidden files, keys, credentials or `.env` files, and upload a document only when the user asked
  to post that document. See [references/media.md](references/media.md).
- **Confirm deletes and retries** for each post id. A retry republishes immediately.
- **Confirm recurring posts like any other.** Show the frequency, the first date and when it ends. A
  recurring post keeps publishing with nobody watching, so confirm before resuming one too.
- **Connect links are secrets.** No tool here creates one. If the user shares a connect link, do not repeat
  it to anyone else or paste it into files, and suggest revoking it in the app once it has been used.
- **No duplicate content** across several accounts on the same network, and do not flood the tools with
  repeated calls.

## Network requirements that fail posts

- **TikTok** needs `tiktokConfigs` with `privacyLevel` for every connection (`PUBLIC_TO_EVERYONE`,
  `MUTUAL_FOLLOW_FRIENDS`, `FOLLOWER_OF_CREATOR`, `SELF_ONLY`). Ask the user; do not assume public.
  TikTok cannot be part of a recurring post.
- **Pinterest** needs `pinterestConfigs` with a `boardId`. No tool lists boards, so ask the user for it.
- **Instagram, TikTok and YouTube** need media. Instagram and Facebook take `postType` `FEED`, `REEL` or
  `STORY` in `instagramConfigs` and `facebookConfigs`. YouTube takes `postType` `VIDEO` or `SHORTS`,
  `videoTitle` and `privacyStatus` in `youtubeConfigs`.
- **Instagram trial reels**: `instagramConfigs.trialGraduation` (`MANUAL` or `SS_PERFORMANCE`) works only for
  a single video posted as a reel or feed video, on an account Instagram has enabled for trial reels.
- **LinkedIn documents** (PDF, PPT, PPTX, DOC, DOCX): `contentType: DOCUMENT`, exactly one file in
  `mediaUrls`, only `LINKEDIN` in `platforms`, optional `linkedinConfigs.documentTitle`. Bulk scheduling
  does not take documents.
- **Carousels** use `contentType: CAROUSEL` with several media URLs.
- **Alt text**: `mediaAltTexts` in the same order as `mediaUrls`, one per image. Write it for every image
  unless the user says not to.

Platform names are uppercase: `INSTAGRAM`, `TIKTOK`, `YOUTUBE`, `TWITTER` (X), `LINKEDIN`, `FACEBOOK`,
`PINTEREST`, `THREADS`, `BLUESKY`, `MASTODON`. Content types: `TEXT`, `IMAGE`, `VIDEO`, `CAROUSEL`,
`DOCUMENT`.

## Changing the plan

- **Edit** a DRAFT or SCHEDULED post with `update_post`; other statuses cannot be edited. Omitted fields
  keep their values. Sending `platforms` replaces every target, so resend every connection array and
  config you want to keep. `mediaUrls` only take effect together with `platforms`.
- **Move** a scheduled post with `update_post` and a new `scheduledAt`. Moving it more than a minute into
  the past fails; use `publish_draft` without `scheduledAt` to publish now.
- **Hold back** a scheduled post with `unschedule_post`. It becomes an undated draft and nothing is lost.
- **Delete** with `delete_post` only when the user wants the post gone. Deleting a published post removes
  AdaptlyPost's record only; the live posts stay on the networks.
- **Bulk**: `bulk_schedule_posts` takes up to 100 posts that share the same platforms, accounts and
  configs. It has no draft mode, so show the whole batch as a table (time, network, text, media) and get
  one explicit "yes" first. Read every result row; one bad item fails alone.
- **Find posts** with `list_posts` (filter by `statuses`, `platforms`, `startDate`, `endDate`; page with
  `offset` while `hasMore` is true). Use `get_post` for one full record.

## Recurring posts

Pass `recurrence` to `create_post` to repeat a post daily, weekly or monthly. It needs a future
`scheduledAt`, cannot be a draft and cannot include TikTok. Read
[references/recurring.md](references/recurring.md) before creating, pausing, resuming or deleting a
series.

## Times

Ask the user's timezone once per session unless they already gave it. Convert every requested time to an
absolute ISO 8601 instant for `scheduledAt`; the `timezone` field is stored for display and does not shift
the time. A time in the past publishes immediately, so check before sending.

## Analytics

Read [references/analytics.md](references/analytics.md) before answering performance questions. Analytics
cover posts published inside the window, go back 180 days and refresh every few hours. X and
Mastodon report nothing, and LinkedIn analytics are waiting on LinkedIn's approval. Say which window your
numbers cover. `list_post_results` is publishing status, not performance.

## Output style

- Drafts: one block per network with its text, then media, accounts and time.
- Status: a small table, network by network, with the error message for any failure and what to do.
- Reports: the headline number and one recommendation first, then detail.
- Link published posts with their `postUrl` from `get_post`. Show media from `previewUrls`, not
  `mediaUrls`; platform links expire within days.
