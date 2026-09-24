# pinentry-omarchy

An Omarchy-styled [pinentry](https://www.gnupg.org/software/pinentry/index.html) dialog.
It replaces the GTK/Qt/curses passphrase prompt with one that matches your Omarchy shell —
theme colors, fonts, and spacing included — because it runs as a plugin inside `omarchy-shell`.

It speaks the standard pinentry Assuan protocol, so anything that can use pinentry can use it:
it is tested with [rbw](https://github.com/doy/rbw) (Bitwarden) and works with gpg-agent.

![Preview](preview.png)

## Requirements

- Omarchy with the Omarchy shell (this installs as a shell plugin)
- `jq` (ships with Omarchy)

## Install

```bash
omarchy plugin add https://github.com/coelebs/pinentry-omarchy
```

Confirm the prompt, then choose Enable.

## Use with rbw (Bitwarden)

```bash
rbw config set pinentry ~/.config/omarchy/plugins/coelebs.pinentry/bin/pinentry-omarchy
```

## Use with gpg-agent

Add this to `~/.gnupg/gpg-agent.conf` (create it if it does not exist):

```text
pinentry-program ~/.config/omarchy/plugins/coelebs.pinentry/bin/pinentry-omarchy
```

Then reload the agent:

```bash
gpgconf --kill gpg-agent
```

## How it works

`bin/pinentry-omarchy` is an Assuan stdio pinentry. When the caller asks for a password
(`GETPIN`), it summons the `coelebs.pinentry` plugin through `omarchy-shell`
IPC, and the plugin writes the entered password to a private response file that
`bin/pinentry-omarchy-reply` picks up. Cancel (Escape) returns the standard
canceled error the way real pinentry does.

## Manual install without the plugin command

The plugin is just files; a manual copy works too:

```bash
git clone https://github.com/coelebs/pinentry-omarchy ~/.config/omarchy/plugins/coelebs.pinentry
omarchy-shell shell rescanPlugins
omarchy-shell shell enablePlugin coelebs.pinentry true
```

## License

MIT — see [LICENSE](LICENSE).
