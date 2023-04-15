# get script file location
$SCRIPT_PATH = Split-Path -Parent $MyInvocation.MyCommand.Definition

@REM ################################################################################
@REM # Documentation on downloading models can be found in the whisper.cpp repo:
@REM # https://github.com/ggerganov/whisper.cpp/#usage
@REM #
@REM # note: unless a multilingual model is specified, WHISPER_LANG will be ignored
@REM # and the video will be transcribed as if the audio were in the English language
@REM ################################################################################
$MODEL_PATH = "$SCRIPT_PATH/models/ggml-base.bin"

@REM ################################################################################
@REM # Where to find the whisper.cpp executable.  default to the examples directory
@REM # which holds this script in source control
@REM ################################################################################
$WHISPER_EXECUTABLE = "$SCRIPT_PATH/main"

# Set to desired language to be translated into english
$WHISPER_LANG = "en"

# Default to 4 threads (this was most performant on my 2020 M1 MBP)
$WHISPER_THREAD_COUNT = 4

function msg {
    [CmdletBinding()]Param([string]$Message, [string]$ForegroundColor="Green")
    Write-Host $Message -ForegroundColor $ForegroundColor
}

function cleanup {
    [CmdletBinding()]Param([string]$CleanMe)

    if (Test-Path $CleanMe) {
        msg "Cleaning up..."
        Remove-Item $CleanMe -Recurse
    }
    else {
        msg "'$CleanMe' does not appear to be a directory!"
        exit 1
    }
}

function print_help {
    echo "################################################################################"
    echo "Usage: ./yt-wsp.sh <video_url>"
    echo "# See configurable env variables in the script; there are many!"
    echo "# This script will produce an MP4 muxed file in the working directory; it will"
    echo "# be named for the title and id of the video."
    echo "# passing in https://youtu.be/VYJtb2YXae8 produces a file named";
    echo "# 'Why_we_all_need_subtitles_now-VYJtb2YXae8-res.mp4'"
    echo "# Requirements: ffmpeg yt-dlp ./main"
    echo "################################################################################"
}

if ($args.Length -lt 1) {
    print_help
    exit 1
}

if ($args[0] -eq "help") {
    print_help
    exit 0
}

@REM ################################################################################
@REM # create a temporary directory to work in
@REM # set the temp_dir and temp_filename variables
@REM ################################################################################
$temp_dir = New-Item -ItemType Directory -Path $SCRIPT_PATH -Name "tmp.*" | Select-Object -ExpandProperty FullName
$temp_filename = "$temp_dir\yt-dlp-filename"

@REM ################################################################################
@REM # for now we only take one argument
@REM # TODO: a for loop
@REM ################################################################################
$source_url = $args[0]
$title_name = ""

msg "Downloading VOD..."

@REM ################################################################################
@REM # Download the video, put the dynamic output filename into a variable.
@REM # Optionally add --cookies-from-browser BROWSER[+KEYRING][:PROFILE][::CONTAINER]
@REM # for videos only available to logged-in users.
@REM ################################################################################
& yt-dlp `
    -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" `
    -o "$temp_dir/%(title)s-%(id)s.vod.mp4" `
    --print-to-file "%(filename)s" "$temp_filename" `
    --no-simulate `
    --no-write-auto-subs `
    --restrict-filenames `
    --embed-thumbnail `
    --embed-chapters `
    --xattrs `
    "$source_url"

$title_name = (Get-Content $temp_filename | Select-Object-Last 1) -replace ".vod.mp4$"

msg "Extracting audio and resampling..."

ffmpeg -i "$temp_dir\$title_name.vod.mp4" `
    -hide_banner `
    -vn `
    -loglevel error `
    -ar 16000 `
    -ac 1 `
    -c:a pcm_s16le `
    -y `
    "$temp_dir\$title_name.vod-resampled.wav"

msg "Transcribing to subtitle file..."
msg "Whisper specified at: '$WHISPER_EXECUTABLE'"

& $WHISPER_EXECUTABLE `
    -m "$MODEL_PATH" `
    -l "$WHISPER_LANG" `
    -f "$temp_dir\$title_name.vod-resampled.wav" `
    -t "$WHISPER_THREAD_COUNT" `
    -osrt

msg "Embedding subtitle track..."

ffmpeg -i "$temp_dir\$title_name.vod.mp4" `
    -hide_banner `
    -loglevel error `
    -i "$temp_dir\$title_name.vod-resampled.wav.srt" `
    -c copy `
    -c:s mov_text `
    -y "$title_name-res.mp4"



msg "Done! Your finished file is ready: $title_name-res.mp4"