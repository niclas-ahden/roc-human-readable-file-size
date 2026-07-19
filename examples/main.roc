app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.21.0-rc4/FvCh4vdqm3nBY6DWEfZ8RuGCVfjuMY43HA8KSNk9qVDn.tar.zst",
	filesize: "../package/main.roc",
}

import pf.Stdout
import filesize.FileSize

main! = |_| {
	samples : List(I64)
	samples = [543, 1234, 1_500_000, 238_674_052, 1_073_741_824]

	_ = Stdout.line!("Decimal:")
	for n in samples {
		Stdout.line!("  ${n.to_str()} -> ${FileSize.format(n)}")
	}

	_ = Stdout.line!("Binary:")
	for n in samples {
		Stdout.line!("  ${n.to_str()} -> ${FileSize.format_binary(n)}")
	}

	custom : FileSize.Settings
	custom = { ..FileSize.defaults, decimal_places: 1, decimal_separator: "," }
	_ = Stdout.line!("Custom (1 decimal, ',' separator):")
	_ = Stdout.line!("  1234 -> ${FileSize.format_with(custom, 1234)}")

	Ok({})
}
