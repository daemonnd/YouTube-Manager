# VidSift

Ai-powered YouTube feed filtering and video relevance scoring.

YouTube has a lot of videos, we all have a lot of YouTube channels we like, but there is still one problem:
The Time.
We don't have the time to fully watch each and every video. But we also want to watch the good ones.
The problem is usually that we don't know which video is good and which one is not worth our time.

The goal of this project is to solve this problem. To see how exactly, check out the `How it works` section.

## How it works

1. It reads the rss feed channel ids from the channelid.json file.
2. It reads the rss feed of each channel
3. for each url:

- It checks if the latest urls have already been processed (if they are on already_processed.json), if it is already on the file, it goes to the next url, else:
- It fetches the transcript with fabric
- It feeds the transcript into ai (any supported by fabric) and validates it, it gets a score from 0 to 100
- depending on the score, here is what happens:
  - score from 100 to 80: Download the video
  - score from 80 to 40: Summarize the video
  - score from 40 to 0: do nothing
- It writes the video url to already_processed.json

## Features

- RSS integration
- transcript extraction
- LLM scoring
- Automated process of fetching, validating, taking action depending on validation
- Runs in the background, no user intervention required

## Dependencies

- [fabric](https://github.com/danielmiessler/Fabric) for fetching the transcript and using the ai
- yt-dlp for downloading the yt video

## Future improvements

- make custom system prompt for fabric depending on the channel
- make it with a background daemon that manages everything
