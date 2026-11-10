# WAV ↔ WV BAT scripts for Windows

Batch scripts for converting between **WAV** and **WavPack (`.wv`)** using [ffmpeg](https://ffmpeg.org/) on Windows.

## Disclaimer: these scripts are specifically for my own use-case working in REAPER:

- I record at 32bit Floating Point (48khz) WAV
- Therefore these scritps assume that as the input format
- These scripts are not recommended or endorsed for any other input format

## Requirements

- Windows
- [ffmpeg](https://ffmpeg.org/download.html) installed and available on `PATH`

## Quick use

Drag and drop WAV/WV file(s) or a folder onto a script, or run a script in a folder of matching files (no arguments).

Existing outputs are **never overwritten** (skipped).

| Script | Direction | Notes |
|--------|-----------|--------|
| `wav-to-wv-32fp.bat` | WAV → WV | 32-bit float + **−144 dBFS** noise gate |
| `wav-to-wv-32fp-recycle.bat` | WAV → WV | Same, then send source WAV to Recycle Bin |
| `wav-to-wv-32fp-recursive.bat` | WAV → WV | −144 gate; this folder + **1 level** of subfolders |
| `wav-to-wv-32fp-recycle-recursive.bat` | WAV → WV | −144 + recycle + 1 level |
| `wav-to-wv-32fp-full.bat` | WAV → WV | 32-bit float, **no gate**; SHA256 float-PCM verify |
| `wav-to-wv-32fp-full-recycle.bat` | WAV → WV | Full + recycle (only after verify OK) |
| `wav-to-wv-32fp-full-recursive.bat` | WAV → WV | Full + verify + 1 level |
| `wav-to-wv-32fp-full-recycle-recursive.bat` | WAV → WV | Full + verify + recycle + 1 level |
| `wv-to-wav-32fp.bat` | WV → WAV | Decode to 32-bit float WAV (`pcm_f32le`) |
| `wv-to-wav-32fp-recycle.bat` | WV → WAV | Same, then recycle source WV |
| `wv-to-wav-32fp-recursive.bat` | WV → WAV | This folder + 1 level of subfolders |
| `wv-to-wav-32fp-recycle-recursive.bat` | WV → WAV | Decode + recycle + 1 level |

`wav-to-wv.ico` is a simple icon you can use for shortcuts or Explorer context menus.

## −144 dB vs full

- **−144 scripts** gate samples below about −144 dBFS to silence (roughly a 24-bit theoretical floor). Useful if you want that floor applied; on many real files it changes nothing.
- **Full scripts** keep all float data (no gate). After encode they verify losslessness by comparing **SHA256 of `pcm_f32le`** from the source WAV and from the `.wv`. On mismatch the `.wv` is deleted and the file is counted as failed.

Ungated encode (as typed in a console):

```text
ffmpeg -hide_banner -n -i "input.wav" -vn -map 0:a:0 -c:a wavpack -sample_fmt fltp "input.wv"
```

## Notes

- Paths with spaces are supported.
- Recycle uses the Windows Recycle Bin (not permanent delete).
- “Recursive” here means **one subfolder level deep**, not a full tree walk.
- Prefer recording to WAV in your DAW, then converting to WV afterwards if you want archival size savings without encode CPU during takes.

## License

Use and modify freely for your own workflow.
