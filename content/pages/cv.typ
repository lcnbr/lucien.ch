#import "/lib/page.typ": page
#import "/lib/cv.typ": cv-data, langs, pdf-url

// The CV itself lives in /lib/cv.typ (shared with the PDFs). Both languages
// are on the page; the switch beside the meta line under the name shows one
// (CSS, no JavaScript needed), and a small script picks French for #fr links
// or French-speaking browsers.

#let names = (en: "EN", fr: "FR")
#let long-names = (en: "English", fr: "Français")

#let switch = html.span(class: "lang-switch", role: "radiogroup", aria-label: "Language / Langue", {
  for lang in langs {
    html.input(type: "radio", name: "cv-lang", id: "cv-" + lang, value: lang, checked: lang == "en")
    html.elem("label", attrs: ("for": "cv-" + lang, lang: lang, title: long-names.at(lang)), names.at(lang))
  }
})

// Download icon for the PDF button.
#let download-icon = html.elem("svg", attrs: (viewBox: "0 0 24 24", "aria-hidden": "true"),
  html.elem("path", attrs: (d: "M12 4v11m-5-5 5 5 5-5M5 20h14")))

#show: page.with(
  title: [CV],
  heading: cv-data("en").contact.name,
  summary: "Curriculum vitae of Lucien Huber, in English and French.",
  meta: {
    let c = cv-data("en")
    [Curriculum vitae]
    if "email" in c.public { [ · ]; link("mailto:" + c.contact.email, c.contact.email) }
  },
  // The language switch, and the PDF in the chosen language.
  actions: {
    switch
    for lang in langs {
      html.a(class: "button cv-pdf", lang: lang, href: pdf-url(lang), download: "", title: cv-data(lang).labels.pdf, { download-icon; [PDF] })
    }
  },
)

#let months = (
  en: ("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"),
  fr: ("janv.", "févr.", "mars", "avr.", "mai", "juin", "juil.", "août", "sept.", "oct.", "nov.", "déc."),
)
#let when(e, lang, present) = {
  let month(d) = months.at(lang).at(d.month() - 1)
  let both(d) = month(d) + "\u{a0}" + str(d.year())
  // The dash stays with the start, so a long range breaks after it.
  let dash = "\u{a0}– "
  if e.end == none { both(e.start) + dash + present }
  else if e.end.year() == e.start.year() { month(e.start) + dash + both(e.end) }
  else { both(e.start) + dash + both(e.end) }
}

#let entry(e, lang, present) = html.li(class: "cv-entry", {
  html.span(class: "cv-when", when(e, lang, present))
  html.div(class: "cv-what", {
    html.p(class: "cv-title", { html.strong(e.title); html.span(class: "cv-where", e.location) })
    html.p(e.body)
  })
})

#let club(c) = html.li(class: "cv-entry", {
  html.span(class: "cv-when", c.date)
  html.div(class: "cv-what", {
    html.p(class: "cv-title", html.strong(c.name))
    html.p(c.body)
  })
})

#let one-cv(lang) = {
  let c = cv-data(lang)
  let l = c.labels
  html.div(class: "cv", lang: lang, {
    let extra = ()
    if "phone" in c.public { extra.push(link("tel:" + c.contact.phone.replace(" ", ""), c.contact.phone)) }
    if "address" in c.public { extra.push(c.contact.address) }
    if "birthday" in c.public { extra.push(c.contact.birthday.display("[day].[month].[year]")) }
    if extra.len() > 0 { html.p(class: "cv-contact", extra.join(html.br())) }
    html.h2(l.education)
    html.ol(class: "cv-list", c.education.map(e => entry(e, lang, l.present)).join())
    html.h2(l.experience)
    html.ol(class: "cv-list", c.experience.map(e => entry(e, lang, l.present)).join())
    html.h2(l.languages)
    html.p(c.languages.join(", "))
    html.h2(l.programming)
    html.p(c.programming.join(", "))
    html.h2(l.clubs)
    html.ol(class: "cv-list", c.clubs.map(club).join())
    html.h2(l.hobbies)
    html.p(c.hobbies)
  })
}

// The headshot sits beside the CV: in the right margin on wide screens,
// floated beside the first section on narrow ones.
#{
  let c = cv-data("en")
  if "photo" in c.public {
    html.img(class: "cv-photo", src: c.contact.photo, alt: c.contact.name, width: 96, height: 128)
  }
}

#for lang in langs { one-cv(lang) }

// #en / #fr pick the language, on load and when a link changes the hash;
// with neither, a French browser gets French.
#html.script("(function(){var fr=document.getElementById('cv-fr'),en=document.getElementById('cv-en');if(!fr)return;function pick(){var h=location.hash.slice(1);if(h==='fr')fr.checked=true;else if(h==='en')en.checked=true;}pick();if(!location.hash&&/^fr\\b/i.test(navigator.language||''))fr.checked=true;addEventListener('hashchange',pick);[en,fr].forEach(function(r){r.addEventListener('change',function(){history.replaceState(null,'','#'+r.value)})})})();")
