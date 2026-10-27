---
name: adaptlypost
description: >
  Draft, schedule, publish and review social media posts on the Instagram, TikTok, YouTube, X (Twitter),
  LinkedIn, Facebook, Pinterest, Threads, Bluesky, Mastodon, Google Business Profile, Tumblr and Telegram accounts
  connected to the user's AdaptlyPost workspaces, and read their analytics, all through the AdaptlyPost MCP server's
  tools. Also covers RSS feeds that post new articles, client connect links, removing accounts and webhooks. Use this skill
  WHENEVER the user wants to write or schedule a post, publish now, plan a content calendar, bulk schedule
  a batch, set up a recurring post, attach an image, video or PDF, check whether a post went out, retry a
  failed network, move or cancel a scheduled post, switch between workspaces or clients, write or rewrite a
  caption with AI, generate an image for a post, or asks how posts, followers, views or engagement are doing. Trigger it even for short asks like "post this", "schedule it
  for Tuesday 9am", "what's queued this week", "why did the Instagram one fail" or "what was our best post
  last month".
last-updated: 2026-10-27
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
| What this sign-in may do | `get_me`, or `can` in `list_workspaces` |
| Find accounts | `list_accounts` |
| Manage accounts | `check_account` (Facebook pages), `remove_account`, `create_connect_link`, `revoke_connect_link` |
| Reel music | `search_instagram_audio` |
| Pinterest boards | `list_pinterest_boards`, or `boardName` when the user named the board |
| Media | `upload_media`, `get_upload_urls` |
| Check before posting | `validate_post`, `validate_bulk_posts` |
| Write | `create_post`, `update_post`, `bulk_schedule_posts` |
| Go live | `publish_draft`, `retry_failed_platforms` |
| Take back | `unschedule_post`, `delete_post` |
| Check | `get_post`, `list_posts`, `list_post_results` |
| Recurring posts | `create_post` with `recurrence`, then `list_recurring_posts`, `get_recurring_post`, `pause_recurring_post`, `resume_recurring_post`, `delete_recurring_post` |
| RSS feeds | `preview_rss_feed`, `create_rss_feed`, `list_rss_feeds`, `get_rss_feed`, `update_rss_feed`, `list_rss_feed_items`, `check_rss_feed`, `pause_rss_feed`, `resume_rss_feed`, `delete_rss_feed` |
| Analytics | `get_analytics_overview`, `get_analytics_timeseries`, `get_platform_breakdown`, `list_post_analytics`, `list_top_posts`, `list_discovered_posts`, `get_analytics_sync_status`, `trigger_analytics_sync` |
| Webhooks | `list_webhooks`, `get_webhook`, `create_webhook`, `update_webhook`, `test_webhook`, `delete_webhook` |
| AI captions and images | `generate_caption`, `refine_caption`, `generate_image`, `get_image_job` |

## Sign-in

The tools belong to the adaptlypost MCP server. Depending on how it was installed they are named
`mcp__plugin_adaptlypost_adaptlypost__<tool>` or `mcp__adaptlypost__<tool>`; this skill uses the bare tool
name.

- If the tools are missing, or a call returns 401, tell the user to run `/mcp`, pick `adaptlypost` and sign
  in with the email they use on AdaptlyPost. Then stop until they say they are signed in.
- The user needs an AdaptlyPost account ([adaptlypost.com](https://adaptlypost.com)) with social accounts
  connected in the app. The user connects their own accounts in the app; `create_connect_link` makes a link
  someone else, such as a client, opens to connect theirs. `remove_account` disconnects one.
- Never ask for an API key in chat. Never read keys or tokens from environment variables, `.env` files,
  config files or keychains, and never send one anywhere. If the user pastes a key, do not use it; point
  them to `/mcp` instead.

## Workspaces

One sign-in can reach several workspaces, across organizations.

- `list_workspaces` returns each workspace's `id`, `name`, `organization`, `role`, `isDefault`, `current`
  and `can` (`draft`, `schedule`, `publish`).
- Every other tool takes an optional `workspaceId`. Without it, tools act in the workspace marked `current`.
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
| Admin | Everything, including removing accounts, checking Facebook pages and connect links | |
| Editor | Create, schedule, publish, retry, bulk schedule, delete, edit any post, RSS feeds in any mode, trigger an analytics sync, manage webhooks | Remove accounts, check pages, connect links |
| Contributor | Create and edit its own drafts, draft-mode RSS feeds, upload media, generate captions and images, read posts and analytics | Schedule, publish, retry, bulk schedule, delete non-drafts, trigger an analytics sync, webhooks, touch other members' posts or feeds |
| Viewer | Read accounts, posts, RSS feeds, webhooks and analytics | Any write, AI generation |

| Response | Meaning | What to do |
|----------|---------|------------|
| 403 `permission_denied` | The role cannot do this. The body names `requiredPermission` and `role` | Final. Do not retry. For a refused schedule or publish, save with `saveAsDraft: true` and tell the user a member with publish rights has to publish it. Otherwise relay the body's `message` |
| 401 `token_issuer_lost_access` | The account behind this access is no longer in the workspace | Stop. Tell the user; signing in again through `/mcp` with a current member fixes it |
| 403 `subscription_required` | The organization's plan does not include API access or has lapsed. Every tool fails the same way | Tell the user to renew the plan. Retrying will not help |
| 401 `oauth_account_not_found` | The user signed in with an email that has no AdaptlyPost account | Relay the message, which names that email. Ask them to run `/mcp`, clear the `adaptlypost` sign-in and sign in with the email they use on AdaptlyPost |
| 403 `workspace_access_denied` | Wrong `workspaceId` | Pick one from `list_workspaces` |
| 429 | Too many calls in a short time | Wait the number of seconds the error gives (`Retry-After`) before the next call. Do not loop |

## The core loop

1. **Accounts.** Call `list_accounts` once per workspace per session. Posts take account ids, never
   usernames. The simplest form is `accountIds`, which works out each account's platform. Otherwise
   Facebook pages go in `pageIds` and every other network has its own `<platform>ConnectionIds` array
   (`linkedinConnectionIds`, `tumblrConnectionIds`, `telegramConnectionIds`, and so on).
   Skip accounts whose `status` is `unauthorized` and tell the user to reconnect them in the app.
2. **Draft.** Keep to each network's length in characters: X 280, Bluesky 300, Threads 500, Mastodon 500,
   Pinterest 500, Google Business Profile 1,500, Instagram 2,200, TikTok 2,200, LinkedIn 3,000, Telegram 4,096,
   YouTube 5,000, Facebook 63,206. Use
   `platformTexts` when one network needs a shorter or different version. For anything unusual (several
   networks, media, stories, carousels), call `validate_post` with the same input first: it lists every
   problem per account and creates nothing. Save with `create_post` and `saveAsDraft: true`; a draft is
   safe and gives you a post id.
3. **Show and ask.** Show the whole post: every account, the workspace if there are several, the time with
   its timezone, each network's visibility settings (TikTok privacy, YouTube privacy) and every caption,
   including per-platform text, alt text, first comments, thread replies, Instagram collaborators, tags and Reel audio, any
   story that goes out alongside the post, and a Google Business Profile post's type and button. Wait for "yes". A "yes" covers that one post, not the next.
4. **Go live.** `publish_draft` without `scheduledAt` publishes now; with a future `scheduledAt` it
   schedules. Content published now reaches the networks within moments and cannot be recalled.
5. **Verify.** Publishing is asynchronous. Call `list_post_results` and report each network separately
   until no row is PENDING or PUBLISHING. One network can fail while the others succeed. A TikTok row with
   `tiktokDraftFallback: true` went to the TikTok inbox as a draft because of TikTok's daily cap; tell the
   user to finish it in the TikTok app.
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
- **Connect links are secrets.** Create one with `create_connect_link` only when the user asks, give the
  `url` to the user alone, and never paste it into files. Suggest `revoke_connect_link`, or `maxAccounts`
  up front, so it stops working once used.
- **Confirm `remove_account`** naming the account. It takes the account off every pending and recurring
  post, and bringing it back means connecting it again.
- **RSS feeds post with nobody watching.** Confirm the feed, the accounts, `postMode` and the text before
  `create_rss_feed`, before switching a feed to `SCHEDULE` or `PUBLISH`, and before `resume_rss_feed`.
  Show `preview_rss_feed` first. `DRAFT` mode is the safe default.
- **Webhook secrets** come back once, from `create_webhook`. Give the secret to the user to store; do not
  write it into files.
- **No duplicate content** across several accounts on the same network, and do not flood the tools with
  repeated calls.

## Network requirements that fail posts

- **TikTok** needs `tiktokConfigs` with `privacyLevel` for every connection (`PUBLIC_TO_EVERYONE`,
  `MUTUAL_FOLLOW_FRIENDS`, `FOLLOWER_OF_CREATOR`, `SELF_ONLY`). Ask the user; do not assume public.
  TikTok cannot be part of a recurring post.
- **Pinterest boards**: when the user named a board, pass that name as `boardName` in `pinterestConfigs`
  and skip the lookup. AdaptlyPost finds it among that Pinterest account's boards (exact match first, then
  case-insensitive) and never falls back to another board: a name that matches no board, or several, fails
  with a 400 that says so (a shared name lists the matching ids). Otherwise call `list_pinterest_boards`
  with the Pinterest account's id, ask the user which board to pin to, and pass its `id` as `boardId`.
  Send `boardId` or `boardName`, never both in one config (400). A board belongs to one Pinterest account,
  so each config's board must be on its `connectionId`. With neither, the pin goes to a public board
  named "AdaptlyPost", created on the account the first time it is needed; leave both out only when the
  user is happy with that board. A 400 from `list_pinterest_boards` usually means the user has to
  reconnect the Pinterest account in the app.
- **Instagram, TikTok and YouTube** need media. Instagram and Facebook take `postType` `FEED`, `REEL` or
  `STORY` in `instagramConfigs` and `facebookConfigs`; `REEL` needs a video and `STORY` an image, video or
  carousel (each item becomes its own story). `shareToStory: true` on a `FEED` or `REEL` post also posts
  the same media as a story; the story is its own row in the results, skips the caption and takes videos up
  to 60 seconds. YouTube takes `postType` `VIDEO` or `SHORTS`, `videoTitle` and `privacyStatus` in
  `youtubeConfigs`.
- **Instagram collaborators**: `instagramConfigs.collaborators`, up to 3 usernames, on feed images,
  carousels and reels (not stories or trial reels). Each one has to accept the invite in Instagram.
- **Instagram Reel audio**: find a track with `search_instagram_audio` (leave out `searchQuery` for
  trending), then pass its `audioId` in `instagramConfigs.audio`, with optional `audioVolume` and
  `videoVolume` from 1 to 100. Only video reels, and only accounts with `supportsInstagramAudio: true`
  in `list_accounts` (connected through Facebook). Let the user pick the track; don't choose for them.
- **Instagram user tags**: `instagramConfigs.userTags`, up to 20 public usernames on a single image, a
  single video or a single story (not carousels). On a feed image each tag needs `x` and `y` from 0 to 1.
  A private or unknown account is dropped and listed in `instagramUntaggedUsernames` in `get_post`.
- **AI labels**: `instagramConfigs.aiGenerated` shows Instagram's "AI info" label;
  `youtubeConfigs.aiGenerated` shows YouTube's "Altered or synthetic content" label;
  `tiktokConfigs.aiGenerated` labels TikTok videos. Set them when the user made the media with AI.
- **Instagram trial reels**: `instagramConfigs.trialGraduation` (`MANUAL` or `SS_PERFORMANCE`) works only for
  a single video posted as a reel or feed video, on an account Instagram has enabled for trial reels.
- **LinkedIn documents** (PDF, PPT, PPTX, DOC, DOCX): `contentType: DOCUMENT`, exactly one file in
  `mediaUrls`, only `LINKEDIN` in `platforms`, optional `linkedinConfigs.documentTitle`. Bulk scheduling
  does not take documents.
- **LinkedIn reshares**: `linkedinConfigs.reshareOf` takes a `urn:li:share:` or `urn:li:ugcPost:` URN (the
  `platformPostId` of an earlier LinkedIn post) or a `linkedin.com/feed/update/<urn>` link, and posts the
  text as commentary on it. `urn:li:activity:` links fail. Not available in bulk.
- **Facebook text backgrounds**: `facebookConfigs.textFormatPresetId` (for example `106018623298955`, solid
  purple) on a `TEXT` post with no media and at most 130 characters. If Facebook refuses it, the post goes
  out as plain text.
- **Facebook link carousels**: `facebookConfigs.imageLayout: CAROUSEL` with 2 to 5 images, `postType`
  `FEED` and one `carouselCards` entry (`link`, optional `title` and `description`) per image. Facebook
  shows the card text only for links to a website the Page owns. `GRID` is the plain photo grid.
- **Tumblr** posts go in `tumblrConnectionIds`; `tumblrConfigs` adds up to 30 `tags`, a `title` and a
  `sourceUrl`.
- **Telegram** channels and groups go in `telegramConnectionIds`. Text up to 4,096 characters, up to 10
  images (10 MB each) or one MP4 or MOV video (50 MB); a caption over 1,024 characters goes out as its
  own message after the media.
- **Google Business Profile** posts go in `googleBusinessConnectionIds`. Text or one JPEG or PNG image up to
  5 MB, no video or carousel. `googleBusinessConfigs` sets `topicType`: `STANDARD` (the default),
  `EVENT` or `OFFER`; events and offers need `eventTitle`, `eventStart` and `eventEnd` as `YYYY-MM-DD` or
  `YYYY-MM-DDTHH:mm` in the business's local time. An optional button is `callToActionType` (`BOOK`,
  `ORDER`, `SHOP`, `LEARN_MORE`, `SIGN_UP`, `CALL`) with `callToActionUrl` for all but `CALL`. Offers can
  add `offerCouponCode`, `offerRedeemUrl` and `offerTerms`.
- **X links**: links in X text are broken on purpose (`example.com` becomes `example. com`) because X
  charges far more for posts with links. `twitterKeepLinks: true` keeps them clickable only on AppSumo
  lifetime deals, for 20 credits instead of 2; any other plan gets a 400. Don't set it unless asked.
- **Carousels** use `contentType: CAROUSEL` with 2 or more media URLs: up to 4 on X, Bluesky and Mastodon,
  5 on Pinterest, 10 on Instagram, Facebook, Threads and Telegram, 20 on LinkedIn, 30 on Tumblr and 35 on
  TikTok. Only Instagram
  and Threads mix images and videos.
- **Alt text**: `mediaAltTexts` in the same order as `mediaUrls`, one per image. Write it for every image
  unless the user says not to.

## Per-network extras

Each of these is a list with one entry per platform, and works on `create_post`, `update_post` and each
`bulk_schedule_posts` item. On `update_post`, sending the list replaces every entry; leaving it out keeps
the stored ones.

- **First comments** (`firstComments: [{ platform, text }]`) go up under the post from the same account
  shortly after it publishes. LinkedIn (1,250 characters), X (280), Threads (500), Bluesky (300), Mastodon
  (500), YouTube (10,000), Facebook (8,000) and Instagram (2,200) only, not on stories or private or
  made-for-kids YouTube videos. A Facebook Page or Instagram account connected before first comments came
  to them needs one reconnect. A failed comment never fails the post: read `firstCommentStatus` and
  `firstCommentError` in `get_post`.
- **Threads of replies** (`threadReplies: [{ platform, texts }]`) turn the post into a thread on X, Threads,
  Bluesky and Mastodon, up to 25 replies, each within that network's post length. A network cannot have
  both a thread and a first comment. A failed thread never fails the post: read `threadStatus` and
  `threadError` in `get_post`.
- **Thumbnail per network** (`platformThumbnails: [{ platform, thumbnailUrl?, thumbnailTimestampMs? }]`)
  for video posts. YouTube, Facebook, LinkedIn and Telegram take an image, Instagram and Pinterest an image or a
  frame, TikTok only a frame. Networks without an entry use the post's `thumbnailUrl` and
  `thumbnailTimestampMs`.
- **Image shape** (`platformAspectRatios: [{ platform, aspectRatio, fit? }]`) for image and carousel
  posts on Instagram (`SQUARE`, `PORTRAIT`, `LANDSCAPE`) and TikTok (those plus `VERTICAL`). `fit` is
  `CROP` (default) or `PAD`, which keeps the whole image on a blurred background.

LinkedIn text can mention a company page as `@[Page Name](urn:li:organization:<id>)`, with the page name
exactly as LinkedIn shows it.

Platform names are uppercase: `INSTAGRAM`, `TIKTOK`, `YOUTUBE`, `TWITTER` (X), `LINKEDIN`, `FACEBOOK`,
`PINTEREST`, `THREADS`, `BLUESKY`, `MASTODON`, `GOOGLE_BUSINESS`, `TUMBLR`, `TELEGRAM`. Content types: `TEXT`, `IMAGE`, `VIDEO`, `CAROUSEL`,
`DOCUMENT`.

## Changing the plan

- **Edit** a DRAFT or SCHEDULED post with `update_post`; other statuses cannot be edited. Omitted fields
  keep their values. Sending `platforms` replaces every target, so resend every connection array and
  config you want to keep. `mediaUrls` and `mediaAltTexts` only take effect together with `platforms`.
- **Move** a scheduled post with `update_post` and a new `scheduledAt`. Moving it more than a minute into
  the past fails; use `publish_draft` without `scheduledAt` to publish now.
- **Hold back** a scheduled post with `unschedule_post`. It becomes an undated draft and nothing is lost.
- **Delete** with `delete_post` only when the user wants the post gone. Deleting a published post removes
  AdaptlyPost's record only; the live posts stay on the networks. A post that is PUBLISHING cannot be
  deleted (409); wait until `list_post_results` settles.
- **Bulk**: `bulk_schedule_posts` takes up to 100 posts that share the same platforms, accounts and
  configs; an item can carry its own `tiktokConfigs`, `instagramConfigs`, `facebookConfigs`,
  `youtubeConfigs`, `pinterestConfigs`, `googleBusinessConfigs` or `tumblrConfigs` to replace the shared
  ones, plus its own `firstComments`, `threadReplies`, `platformThumbnails` and `platformAspectRatios`.
  Run `validate_bulk_posts` with the same input first and fix every item it flags. It has no draft mode,
  so show the whole batch as a table (time, network, text, media) and get one explicit "yes" first. Read
  every result row; one bad item fails alone.
- **Find posts** with `list_posts` (filter by `statuses`, `platforms`, `startDate`, `endDate`; page with
  `offset` while `hasMore` is true). Use `get_post` for one full record.

## Recurring posts

Pass `recurrence` to `create_post` to repeat a post daily, weekly, monthly or yearly. It needs a future
`scheduledAt`, cannot be a draft and cannot include TikTok. Read
[references/recurring.md](references/recurring.md) before creating, pausing, resuming or deleting a
series.

## RSS feeds

A feed turns each new item of an RSS or Atom feed into a post on its target accounts (Facebook,
Instagram, Threads, X, Bluesky, LinkedIn, Mastodon, Telegram and Google Business Profile), as a draft, a
scheduled post or straight away (`postMode`). Text comes from a `template` with `{title}`, `{link}`,
`{description}`, `{author}` and `{feed}`, or from AI (`contentMode: AI`, 1 credit per network per item).
Items already in the feed when it is added are never posted unless `postLatestItem` is true. A workspace
holds 20 feeds. When the user asks why an article did or did not go out, read `list_rss_feed_items`. A
paused feed's `pauseReason` says why; fix that before `resume_rss_feed`.

## Webhooks

`create_webhook` registers a URL that receives every event (`post.published`, `post.partially_failed`,
`post.failed`, `post.scheduled`, `account.unauthorized`, `image.completed`, `image.failed`), signed with
the secret the response returns once. `test_webhook` sends a signed test event. An endpoint is turned off
after 20 failed deliveries in a row; `update_webhook` with `active: true` turns it back on.

## Times

Ask the user's timezone once per session unless they already gave it. Convert every requested time to an
absolute ISO 8601 instant for `scheduledAt`; the `timezone` field is stored for display and does not shift
the time. A time in the past publishes immediately, so check before sending.

## AI captions and images

Use the AI tools when the user asks for a caption or an image, or says "write something about X" without
giving text. For a caption the user already wrote, just use their text.

- **Captions.** `generate_caption` writes one from a `prompt`; `refine_caption` rewrites `originalText`
  from an instruction ("shorter", "add a question"). Pass `platform` to keep it within that network's
  length. Both return `{ caption }` and save nothing. Show it, then put it in a draft as usual.
- **Images.** `generate_image` does not return the image. It returns a `jobId` right away. Call
  `get_image_job` every few seconds until `status` is `completed` or `failed`, usually 10 to 40 seconds,
  and stop after a couple of minutes. A completed job's `imageUrl` is public and goes straight into
  `mediaUrls`; no `upload_media` needed. Pick `aspectRatio` for the target network (9:16 for stories and
  reels, 4:5 for the Instagram feed). Reuse `sessionId` to keep related images together.
- **Credits.** Each caption costs 2 of the member's AI credits, a standard image 2 and a premium image 4,
  refunded when generation fails. A member who connected their own AI provider key in the app pays no
  credits. With no credits left a caption call fails and an image job ends `failed` with the reason in
  `error`: tell the user to top up or upgrade, or, for a team member, to ask the organization owner or an
  admin for a larger AI credit allowance. Do not retry.
- Generate only what the user asked for. Offer one or two variations, not a loop of them.
- All four need the `ai.generate` permission: Admin, Editor and Contributor have it, Viewer does not.

## Analytics

Read [references/analytics.md](references/analytics.md) before answering performance questions. Analytics
cover posts published inside the window and refresh every few hours. Facebook, Instagram, Threads, TikTok,
Pinterest, Bluesky, YouTube, X, LinkedIn and Google Business Profile report numbers; Mastodon, Telegram and
Tumblr report nothing. Say which window your numbers cover. `list_post_results` is publishing status, not performance.

## Output style

- Drafts: one block per network with its text, then media, accounts and time.
- Status: a small table, network by network, with the error message for any failure and what to do.
- Reports: the headline number and one recommendation first, then detail.
- Link published posts with their `postUrl` from `get_post`. Show media from `previewUrls`, not
  `mediaUrls`; platform links expire within days.
