## Convert byte counts into human-readable file size strings, in either decimal
## (kB, MB, GB, ...) or binary (KiB, MiB, GiB, ...) units.
##
## The number is floored, never rounded up, so a value just below a unit
## boundary (e.g. `999_999`) won't ever render as `"1000 kB"`.
##
## ```roc
## FileSize.format(1234) == "1.23 kB"
## FileSize.format(238_674_052) == "238.67 MB"
## FileSize.format(543) == "543 B"
## FileSize.format_binary(1024) == "1 KiB"
## ```
##
## Decimal units divide by 10^3 at each step:
##
##   - 1 byte (B)
##   - 1 kilobyte (kB) = 1000 bytes
##   - 1 megabyte (MB) = 1000 kilobytes
##   - 1 gigabyte (GB) = 1000 megabytes
##   - 1 terabyte (TB) = 1000 gigabytes
##   - 1 petabyte (PB) = 1000 terabytes
##   - 1 exabyte (EB) = 1000 petabytes
##
## Binary/IEC units divide by 2^10 (1024) at each step:
##
##   - 1 byte (B)
##   - 1 kibibyte (KiB) = 1024 bytes
##   - 1 mebibyte (MiB) = 1024 kibibytes
##   - 1 gibibyte (GiB) = 1024 mebibytes
##   - 1 tebibyte (TiB) = 1024 gibibytes
##   - 1 pebibyte (PiB) = 1024 tebibytes
FileSize :: {}.{

	## Pick a unit system: decimal (kB, MB, ...) or binary (KiB, MiB, ...).
	Units : [Decimal, Binary]

	## Customize the formatting. Use [defaults] and override the fields you need.
	##
	##   - `units`: `Decimal` or `Binary`. Default `Decimal`.
	##   - `decimal_places`: digits after the decimal separator. Default `2`.
	##   - `decimal_separator`: string used as decimal separator. Default `"."`.
	Settings : {
		units : FileSize.Units,
		decimal_places : U64,
		decimal_separator : Str,
	}

	## The default settings: decimal units, 2 decimal places, "." as decimal separator.
	defaults : FileSize.Settings
	defaults = {
		units: Decimal,
		decimal_places: 2,
		decimal_separator: ".",
	}

	## Format a byte count using the default settings.
	format : I64 -> Str
	format = |num| FileSize.format_with(FileSize.defaults, num)

	## Format a byte count using the default settings, returning the number and unit
	## as a tuple of strings.
	format_split : I64 -> (Str, Str)
	format_split = |num| FileSize.format_with_split(FileSize.defaults, num)

	## Format a byte count using binary/IEC units.
	format_binary : I64 -> Str
	format_binary = |num| FileSize.format_with({ ..FileSize.defaults, units: Binary }, num)

	## Format a byte count using binary/IEC units, returning the number and unit
	## as a tuple of strings.
	format_binary_split : I64 -> (Str, Str)
	format_binary_split = |num| FileSize.format_with_split({ ..FileSize.defaults, units: Binary }, num)

	## Format a byte count using the given settings.
	format_with : FileSize.Settings, I64 -> Str
	format_with = |settings, num| {
		(size, unit) = FileSize.format_with_split(settings, num)
		"${size} ${unit}"
	}

	## Format a byte count using the given settings, returning the number and unit
	## as a tuple of strings.
	format_with_split : FileSize.Settings, I64 -> (Str, Str)
	format_with_split = |settings, num|
		if num == 0 {
			("0", "B")
		} else {
			(abs_num, prefix) = 
				if num < 0 {
					(num.abs(), "-")
				} else {
					(num, "")
				}

			unit = pick_unit(settings.units, abs_num)
			scaled = abs_num.to_f64() / unit.divisor.to_f64()
			formatted = format_number(settings, scaled)
			("${prefix}${formatted}", unit.abbreviation)
		}
}

# Helpers below are defined at module scope (outside the `FileSize` associated
# block) so they stay private to this module.

UnitChoice : { divisor : I64, abbreviation : Str }

pick_unit : FileSize.Units, I64 -> UnitChoice
pick_unit = |units, num|
	match units {
		Decimal => pick_decimal_unit(num)
		Binary => pick_binary_unit(num)
	}

pick_decimal_unit : I64 -> UnitChoice
pick_decimal_unit = |num|
	if num >= 1_000_000_000_000_000_000 {
		{ divisor: 1_000_000_000_000_000_000, abbreviation: "EB" }
	} else if num >= 1_000_000_000_000_000 {
		{ divisor: 1_000_000_000_000_000, abbreviation: "PB" }
	} else if num >= 1_000_000_000_000 {
		{ divisor: 1_000_000_000_000, abbreviation: "TB" }
	} else if num >= 1_000_000_000 {
		{ divisor: 1_000_000_000, abbreviation: "GB" }
	} else if num >= 1_000_000 {
		{ divisor: 1_000_000, abbreviation: "MB" }
	} else if num >= 1_000 {
		{ divisor: 1_000, abbreviation: "kB" }
	} else {
		{ divisor: 1, abbreviation: "B" }
	}

pick_binary_unit : I64 -> UnitChoice
pick_binary_unit = |num|
	if num >= 1_125_899_906_842_624 {
		{ divisor: 1_125_899_906_842_624, abbreviation: "PiB" }
	} else if num >= 1_099_511_627_776 {
		{ divisor: 1_099_511_627_776, abbreviation: "TiB" }
	} else if num >= 1_073_741_824 {
		{ divisor: 1_073_741_824, abbreviation: "GiB" }
	} else if num >= 1_048_576 {
		{ divisor: 1_048_576, abbreviation: "MiB" }
	} else if num >= 1_024 {
		{ divisor: 1_024, abbreviation: "KiB" }
	} else {
		{ divisor: 1, abbreviation: "B" }
	}

format_number : FileSize.Settings, F64 -> Str
format_number = |settings, value| {
	truncated = floor_to_decimal_places(value, settings.decimal_places)
	cleaned = strip_trailing_zeros(truncated)
	apply_decimal_separator(cleaned, settings.decimal_separator)
}

floor_to_decimal_places : F64, U64 -> Str
floor_to_decimal_places = |value, decimal_places|
	if decimal_places == 0 {
		value.floor_to_i128().to_str()
	} else {
		factor = pow10(decimal_places)
		scaled = (value * factor).floor_to_i128()
		digits = scaled.to_str()
		padded = pad_left(digits, decimal_places + 1, "0")
		len = padded.count_utf8_bytes()
		split_at = len - decimal_places
		before = take_bytes(padded, split_at)
		after = drop_bytes(padded, split_at)
		"${before}.${after}"
	}

pow10 : U64 -> F64
pow10 = |n|
	if n == 0 {
		1.0
	} else {
		10.0 * pow10(n - 1)
	}

pad_left : Str, U64, Str -> Str
pad_left = |s, target_len, pad|
	if s.count_utf8_bytes() >= target_len {
		s
	} else {
		pad_left(pad.concat(s), target_len, pad)
	}

take_bytes : Str, U64 -> Str
take_bytes = |s, n|
	match Str.from_utf8(s.to_utf8().take_first(n)) {
		Ok(out) => out
		Err(_) => ""
	}

drop_bytes : Str, U64 -> Str
drop_bytes = |s, n|
	match Str.from_utf8(s.to_utf8().drop_first(n)) {
		Ok(out) => out
		Err(_) => ""
	}

strip_trailing_zeros : Str -> Str
strip_trailing_zeros = |s|
	match s.find_first(".") {
		Err(NotFound) => s
		Ok({ before, after }) => {
			stripped = strip_zeros_from_end(after)
			if stripped.is_empty() {
				before
			} else {
				"${before}.${stripped}"
			}
		}
	}

strip_zeros_from_end : Str -> Str
strip_zeros_from_end = |s|
	if s.ends_with("0") {
		strip_zeros_from_end(take_bytes(s, s.count_utf8_bytes() - 1))
	} else {
		s
	}

apply_decimal_separator : Str, Str -> Str
apply_decimal_separator = |s, sep|
	if sep == "." {
		s
	} else {
		match s.find_first(".") {
			Err(NotFound) => s
			Ok({ before, after }) => "${before}${sep}${after}"
		}
	}

# --- Tests ---

expect FileSize.format(0) == "0 B"
expect FileSize.format(1) == "1 B"
expect FileSize.format(543) == "543 B"
expect FileSize.format(999) == "999 B"
expect FileSize.format(1000) == "1 kB"
expect FileSize.format(1234) == "1.23 kB"
expect FileSize.format(1500) == "1.5 kB"
expect FileSize.format(1239) == "1.23 kB"
expect FileSize.format(1_000_000) == "1 MB"
expect FileSize.format(238_674_052) == "238.67 MB"
expect FileSize.format(1_000_000_000) == "1 GB"
expect FileSize.format(1_000_000_000_000) == "1 TB"
expect FileSize.format(1_000_000_000_000_000) == "1 PB"
expect FileSize.format(1_000_000_000_000_000_000) == "1 EB"

expect FileSize.format(-543) == "-543 B"
expect FileSize.format(-1234) == "-1.23 kB"

expect FileSize.format_split(1234) == ("1.23", "kB")
expect FileSize.format_split(0) == ("0", "B")

expect FileSize.format_binary(0) == "0 B"
expect FileSize.format_binary(1) == "1 B"
expect FileSize.format_binary(1023) == "1023 B"
expect FileSize.format_binary(1024) == "1 KiB"
expect FileSize.format_binary(1536) == "1.5 KiB"
expect FileSize.format_binary(1_048_576) == "1 MiB"
expect FileSize.format_binary(1_073_741_824) == "1 GiB"
expect FileSize.format_binary(1_099_511_627_776) == "1 TiB"
expect FileSize.format_binary(1_125_899_906_842_624) == "1 PiB"

expect FileSize.format_binary_split(1024) == ("1", "KiB")

expect FileSize.format_with({ ..FileSize.defaults, decimal_places: 0 }, 1500) == "1 kB"
expect FileSize.format_with({ ..FileSize.defaults, decimal_places: 4 }, 1_234_567) == "1.2345 MB"
expect FileSize.format_with({ ..FileSize.defaults, decimal_separator: "," }, 1234) == "1,23 kB"
expect FileSize.format_with({ ..FileSize.defaults, units: Binary }, 1024) == "1 KiB"
expect {
	settings = { units: Binary, decimal_places: 1, decimal_separator: "," }
	FileSize.format_with(settings, 1536) == "1,5 KiB"
}
