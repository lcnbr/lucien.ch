// Small helpers.

// Best-effort plain text of a content value (for <title>, RSS, JSON).
#let plain(it) = {
  if it == none { "" }
  else if type(it) == str { it }
  else if it.has("text") { it.text }
  else if it.has("children") { it.children.map(plain).join() }
  else if it.has("body") { plain(it.body) }
  else if it.func() == math.equation { "[math]" }
  else if it == [ ] { " " }
  else { "" }
}

// Parse "YYYY-MM-DD" (or a full ISO timestamp) into a datetime.
#let parse-date(s) = {
  if s == none { return none }
  let p = s.slice(0, 10).split("-").map(int)
  datetime(year: p.at(0), month: p.at(1), day: p.at(2))
}

#let fmt-date(d) = if d == none { "" } else { d.display("[day] [month repr:long] [year]") }
#let iso-date(d) = if d == none { "" } else { d.display("[year]-[month]-[day]") }
