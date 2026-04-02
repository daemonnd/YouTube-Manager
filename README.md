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
- video filtering, only takes videos from the last 2 weeks
- make custom system prompt for ai validation depending on the channel
- LLM scoring
- Automated process of fetching, validating, taking action depending on validation
- Runs in the background, no user intervention required
- config system with options for ai model selection, destination directories, etc.
- channel specific actions performed on every video (validate, summary, download) depending on the channel

## Usage

1. Install it (pre-v1, not ready for general use)
2. Create a dir at ~/Videos/vidsift/ and one at ~/Documents/vidsift/
3. Create a new file name channelids.json
    Edit it, make it like this:

    ```json
    {
        "<channel name>": "<matching channel id>",
        "<channel name 2>": "<matching channel id>"
    }
    ```

    Example:

    ```json
    {
        "typecraft": "UCo71RUe6DX4w-Vd47rFLXPg",
        "networkchuck": "UC9x0AN7BWHpCDHSm9NiJFJQ",
        "pewdiepie": "UC-lHJZR3Gqxm24_Vd_AJ5Yw"
    }
    ```

4. Edit the custom instructions:

    - go to ./custom_channel_instructions/
    - create a file for each name and put in what kind of videos you want to see from that channel
    - if you want to do it for typecraft: touch ./custom_channel_instructions/typecraft.md

5. Run vidsift.sh with `./vidsift.sh`

## Issues & How to fix them

- YouTube rate limit exeded: Add the url to already_processed_urls.txt
- Parser error in url_collector.sh: Update the channel id in channelids.json, check out the url manually.
Exact Error message when that last happened:

```
-:2: parser error : AttValue: " or ' expected
<html lang=en>
           ^
-:2: parser error : attributes construct error
<html lang=en>
           ^
-:2: parser error : Couldn't find end of Start Tag html line 2
<html lang=en>
           ^
Script url_collector.sh interupted or failed. Cleaning up...
```

## Dependencies

### Required Dependencies

- [fabric](https://github.com/danielmiessler/Fabric) for fetching the transcript and using the ai, with a working ai model
- [yt-dlp](https://github.com/yt-dlp/yt-dlp) for downloading the yt video

### Optional Dependencies

- [file-renamer](https://github.com/daemonnd/file-renamer) for automatically rename video and summary files for a linux fs

## Future improvements

- make it with a daemon service
- job queue
- retry system
- structured logging
- rate limit handling
- plugin architecture
- a background daemon that manages everything
