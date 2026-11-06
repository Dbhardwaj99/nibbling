# Nibbling

Nibbling suggests the rest of what you're writing, in any app on your Mac.

This repository is where Nibbling is released. It holds the installer; each version's app is attached to [Releases](https://github.com/Dbhardwaj99/nibbling/releases).

You need a Mac with Apple silicon (M1 or later) and macOS 14 Sonoma or later.

## Install

1. Copy this command:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/Dbhardwaj99/nibbling/main/install.sh | bash
   ```

2. Open Terminal: press ⌘Space, type `Terminal` and press Return.
3. Paste the command with ⌘V and press Return.

Nibbling opens when it's installed. Its first run downloads the language model and asks for the permissions it needs.

**If macOS says "Possible malware, Paste blocked":** macOS 26.4 and later may show this the first time you paste a command copied from a browser into Terminal. It's about where the text was copied from, not what the command does. To check what the command runs, read [install.sh](install.sh). Then choose Paste Anyway.

## What the command does

It downloads [install.sh](install.sh) and runs it. The script:

- downloads the latest `Nibbling.zip` and its SHA-256 checksum from Releases, and stops if they don't match;
- quits Nibbling if it's running;
- puts `Nibbling.app` in `/Applications`, or in `~/Applications` if `/Applications` isn't writable;
- opens Nibbling.

It never uses `sudo` or asks for your password.

## Update

Run the same command again.

## Uninstall

1. Quit Nibbling.
2. Move `Nibbling.app` to the Trash.
3. To remove the downloaded model and Nibbling's other data too, move `~/Library/Application Support/Autocompleter` to the Trash.

## Release files

Each release attaches two files with the same names every time, so the installer's `releases/latest/download/` links keep working:

- `Nibbling.zip`: `Nibbling.app`, zipped with `ditto -c -k --keepParent`;
- `Nibbling.zip.sha256`: the zip's SHA-256 in hex, as the first word of the file (`shasum -a 256` output).
