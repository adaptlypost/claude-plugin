# Uploading media

Every `mediaUrls` value must be a `publicUrl` that AdaptlyPost returned. Any other URL fails the post with
"Media file(s) not found in storage".

Uploaded files are public as soon as they are stored, whether or not a post uses them. Only upload files
the user named in this conversation. Never upload hidden files, keys, credentials, `.env` files or
anything the user did not point to, and upload a document only when the user asked to post that document.

## A public https URL

Call `upload_media` with `urls`. The server downloads the file into storage and returns `mediaUrls` to pass
straight into the post. Private, internal and plain-http addresses are refused, and the source must send a
Content-Length. Only pass URLs the user gave you or that point at the user's own public media.

## A local file

`upload_media` also takes `files` as base64, up to 30 MB decoded per call. The base64 text travels inside
the tool call, so use it only for very small files. For anything larger, upload the bytes directly:

1. Call `get_upload_urls` with `files: [{ fileName, mimeType }]`. Keep the extension in `fileName`; the post
   reads the file type from it. You get `uploadUrl` and `publicUrl` per file.
2. PUT the file to `uploadUrl` with the same Content-Type. The user is asked to approve the command:

   ```bash
   curl -sS -o /dev/null -w '%{http_code}\n' -X PUT \
     -H 'Content-Type: image/jpeg' \
     --data-binary @/path/the/user/named/photo.jpg \
     '<uploadUrl>'
   ```

3. Use `publicUrl` only after the PUT printed a 2xx code. If the PUT failed or the upload URL expired (1
   hour), mint a new one and PUT again.

Do not add an Authorization header to the upload URL. It is presigned and is not an AdaptlyPost API host.
Send the upload URL nothing except the file the user named.

An image the user pasted into the chat is not a file on disk. Ask for its path or a public URL.

## Reuse

One `publicUrl` can go into any number of posts, bulk items included. The file is kept until the last post
that uses it has published. Reuse the `publicUrl` you uploaded, not a `mediaUrls` value read back from a
published post, which may be the platform's own expiring link.

## Limits

| Kind | Types | Max size |
|------|-------|----------|
| Image | JPEG, PNG, WebP | 50 MB |
| Video | MP4, QuickTime | 250 MB from a URL |
| Document (LinkedIn only) | PDF, PPT, PPTX, DOC, DOCX | 100 MB, 300 pages |

Networks have their own limits on top of these (aspect ratios, video length, carousel counts). When a
network rejects a file, `list_post_results` says why; read the message before changing anything.

## Alt text

Pass `mediaAltTexts` in the same order as `mediaUrls`, one per image, up to 1,000 characters, `""` to skip
one. X, Bluesky, Mastodon, LinkedIn, Facebook, Instagram and Threads use it; Pinterest takes the first one.
TikTok, YouTube and videos ignore it.

## Video thumbnails

For video posts, `thumbnailUrl` sets a custom thumbnail image and `thumbnailTimestampMs` picks a frame from
the video instead.
