# VidSift

Ai-powered YouTube feed filtering and video relevance scoring

YouTube has a lot of videos, we all have a lot of YouTube channels we like, but that also brings two main Problems:

1. the Time, because consuming all of that costs a lot of time
2. Distractions, because we always see new videos that we click which then causes the first Problem

We don't have the time to fully watch each and every video. But we also want to watch the good ones.
The problem is usually that we don't know which video is good and which one is not worth our time.

The goal of this project is to solve this problem. To see how exactly, check out the `How it works` section.

## How it works

1. It reads the rss feed channel ids from the config.jsonc file.
2. It reads the rss feed of each channel
3. for each url:

- It checks if the latest urls have already been processed (if they are on already_processed_urls.txt), if it is already on the file, it goes to the next url, else:
- It performs an action depending on how defined in `config.jsonc`:
- validating:
  - It fetches the transcript with fabric and devides it into multiple chunks if it is too long
  - It feeds the transcript into ai (any supported by fabric) and validates it, it gets a score from 0 to 100
  - depending on the score, here is what happens:
    - score from 100 to 80: Download the video
    - score from 80 to 40: Summarize the video
    - score from 40 to 0: do nothing
- downloading:
  - it downloads the video directly, without validation
summarizing:
  - it Summarizes the video transcript directly, without validation
- It writes the video url to already_processed_urls.txt

If, while fetching the transcript or title, a YouTube rate limit is reached,
vidsift blocks the channel automatically for a time range defined by the config (default: 7 days)

## Features

- RSS integration
- transcript extraction and chunking
- video filtering, only takes videos from the last 2 weeks (can be changed in config)
- make custom system prompt for ai validation depending on the channel
- LLM scoring
- Automated process of fetching, validating, taking action depending on validation
- Runs in the background, no user intervention required
- config file for customizing vidsift (config.jsonc)
- channel specific actions performed on every video (validate, summary, download) depending on the channel
- locking mechanism for making file-related interactions from vidsift more stable
- auto-block of channels that have YouTube rate limit issues and auto-unblocking after

## Usage

### Installation

Install it with the following commands

```bash
curl -fsSL https://raw.githubusercontent.com/daemonnd/VidSift/main/install.sh | bash
# if it tells you to update your ~/.bashrc file
source ~/.bashrc
# if you want the background service
cd vidsift/
sudo ./install.sh daemon-setup
```

### Getting started

1. Edit vidsifts `config.jsonc`, usually located at `~/.config/vidsift/config.jsonc`
    Make sure to set destination directories for both summaries and downloads.
    Edit it like this for the channelids:

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

    Note:
    It is also recommended to add a `--cookies-from-browser firefox` (or whatever browser you are using)
    to avoid YouTube related issues at the custom yt-dlp args under `general_processing`.
    To use ai features, set the ai provider and model to what you use.

2. Edit the custom instructions:

    - go to ~/.config/vidsift/custom_channel_instructions/
    - create a file for each name and put in what kind of videos you want to see from that channel
    - if you want to do it for typecraft: touch ./custom_channel_instructions/typecraft.md

3. Set up the ai (recommended, but not needed if you don't want summaries and validation)
    - Run `fabric --setup` or edit fabrics `.env` file, usually located at `~/.config/fabric/.env`.

4. Run vidsift with `vidsift` or start the service with `sudo systemctl start vidsift-manager.timer`

### Using vidsift with flags for output control

- no flag: Only output warnings, errors and critical
- `-v`: Output critical, errors, warnings and infos
- `-vv`: Output critical, errors, warnings, infos and debug logs
- `-s`: Only output errors and critical messages
- `-ss`: Only output critical error messages

Note:
When using the background service, the default after
`sudo ./install.sh daemon-setup` will be no flags.
Feel free to change that with `sudo systemctl edit vidsift-manager.service`.

### How to set up the background service

To set up a background service that runs vidsift every 15 minutes (default, can be changed by editing the systemd timer),
you need to run install.sh with as root and use the `daemon-setup` argument.
The systemd service is named `vidsift-manager.service` and the systemd timer is named `vidsift-manager.timer`.
They live both in `/etc/systemd/system/`.
Make sure to add the directories paths for the requirements to `config.jsonc` under general_processing.required_paths, they will be added to the limited `$PATH` while the service runs.

```bash
# first, cd to the vidsift project dir
sudo ./install.sh daemon-setup
```

That will enable the systemd timer starting the service. You can also enable it manually with this:

```bash
sudo systemctl start vidsift-manager.service
```

To check logs and status of the background service, you can try these commands:

```bash
# checking the status of the timer
systemctl status vidsift-manager.timer
# checking the status of the service
systemctl status vidsift-manager.service

# checking the logs of the timer
journalctl -u vidsift-manager.timer
# checking the logs of the service
journalctl -u vidsift-manager.service
```

## Issues & How to fix them

- Parser error in url_collector.sh: Update the channel id in config.jsonc, check out the url manually.
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

- one of the supported browsers by yt-dlp with a signed in google account to avoid YouTube related issues
- [file-renamer](https://github.com/daemonnd/file-renamer) for automatically rename video and summary files for a linux fs
- [systemd](https://systemd.io/) for the vidsift background service

## Limitations

- uses the custom fabric pattern `vidsift_score_youtube_transcript` and overwrites it on each video validation

## Future improvements

- job queue
- retry system
- plugin architecture
