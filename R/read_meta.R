read_meta <- function(path) {
  if (!file.exists(path)) {
    stop("Meta file not found: ", path)
  }

  # yaml::read_yaml() reads the file via readLines(), whose handling of
  # multi-byte characters depends on the active locale (LC_CTYPE). Under a
  # non-UTF-8 locale (e.g. "C", common on minimal servers and CI runners),
  # non-ASCII bytes in the YAML (Norwegian "æøå" etc.) make the
  # read stop partway through the file -- silently dropping every field after
  # the first non-ASCII line, with no error. Reading the raw bytes ourselves
  # and decoding explicitly as UTF-8 sidesteps the locale dependency.
  raw <- readBin(path, "raw", n = file.info(path)$size)
  text <- iconv(rawToChar(raw), from = "UTF-8", to = "UTF-8")
  yaml::yaml.load(text)
}

# Local Variables:
# mode: R
# End:
