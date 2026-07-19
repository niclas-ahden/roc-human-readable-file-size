# roc-human-readable-file-size

Format byte counts as human-readable strings (e.g. `"1.23 kB"`, `"1 KiB"`) in
Roc. A port of the excellent [`elm-human-readable-filesize`](https://package.elm-lang.org/packages/basti1302/elm-human-readable-filesize/latest/), see [`NOTICE`](NOTICE).

## Example usage

```roc
app [main!] {
    pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.21.0-rc4/FvCh4vdqm3nBY6DWEfZ8RuGCVfjuMY43HA8KSNk9qVDn.tar.zst",
    filesize: "https://github.com/niclas-ahden/roc-human-readable-file-size/releases/download/0.1.0/...tar.zst",
}

import pf.Stdout
import filesize.FileSize

main! = |_| {
    Stdout.line!(FileSize.format(238_674_052))          # "238.67 MB"
    Stdout.line!(FileSize.format_binary(1_073_741_824)) # "1 GiB"

    custom = { ..FileSize.defaults, decimal_places: 1, decimal_separator: "," }
    Stdout.line!(FileSize.format_with(custom, 1234))    # "1,2 kB"

    Ok({})
}
```

Run a fuller example like so `roc examples/main.roc`.

## Documentation

See [https://niclas-ahden.github.io/roc-human-readable-file-size/](https://niclas-ahden.github.io/roc-human-readable-file-size/).
