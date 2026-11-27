#import "/lib/page.typ": page
#import "/lib/cv.typ": cv-data, langs, pdf-url, date-range

#show: page.with(title: [CV], summary: "Curriculum vitae of Lucien Huber, in English and French.")

// The CV itself lives in /lib/cv.typ (shared with the PDFs). Both languages
// are on the page; the switch shows one (CSS, no JavaScript needed), and a
// small script picks French for #fr links or French-speaking browsers.

#let names = (en: "English", fr: "Français")

#let entry(e, present) = html.li(class: "cv-entry", {
  html.span(class: "cv-when", date-range(e, present))
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
    html.div(class: "cv-head", {
      if "photo" in c.public {
        html.img(class: "cv-photo", src: c.contact.photo, alt: c.contact.name, width: 96, height: 128)
      }
      html.div({
        html.p(class: "cv-name", c.contact.name)
        html.p(class: "cv-contact", {
          let parts = ()
          if "email" in c.public { parts.push(link("mailto:" + c.contact.email, c.contact.email)) }
          if "phone" in c.public { parts.push(link("tel:" + c.contact.phone.replace(" ", ""), c.contact.phone)) }
          if "address" in c.public { parts.push(c.contact.address) }
          if "birthday" in c.public { parts.push(c.contact.birthday.display("[day].[month].[year]")) }
          parts.join(html.br())
        })
        html.p(class: "cv-pdf", html.a(href: pdf-url(lang), download: "", l.pdf + " ↓"))
      })
    })
    html.h2(l.education)
    html.ol(class: "cv-list", c.education.map(e => entry(e, l.present)).join())
    html.h2(l.experience)
    html.ol(class: "cv-list", c.experience.map(e => entry(e, l.present)).join())
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

#html.div(class: "cv-switch", role: "radiogroup", aria-label: "Language / Langue", {
  for lang in langs {
    html.input(type: "radio", name: "cv-lang", id: "cv-" + lang, value: lang, checked: lang == "en")
    html.elem("label", attrs: ("for": "cv-" + lang, lang: lang), names.at(lang))
  }
})

#for lang in langs { one-cv(lang) }

#html.script("(function(){var h=location.hash.slice(1),fr=document.getElementById('cv-fr'),en=document.getElementById('cv-en');if(!fr)return;if(h==='fr'||(h!=='en'&&/^fr\\b/i.test(navigator.language||'')))fr.checked=true;[en,fr].forEach(function(r){r.addEventListener('change',function(){history.replaceState(null,'','#'+r.value)})})})();")
