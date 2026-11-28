// Curriculum vitae: the content in English and French, and the PDF layout.
//
// The web page (content/pages/cv.typ) and the PDFs (cv/cv-pdf.typ, built by
// `cargo site build` into /cv/lucien-huber-cv-en.pdf and -fr.pdf) both read
// `cv-data(lang)`, so a change here shows up in all three.

// Personal details. The repository is public, and so is the editor's copy of
// these sources, so phone, address and birthday are not written here: they
// only exist in a PDF you build yourself, passed as inputs, e.g.
//   typst compile --root . --font-path cv/fonts --input lang=fr \
//     --input phone="+41 …" --input address="…" --input birthday=YYYY-MM-DD \
//     cv/cv-pdf.typ cv-fr.pdf
// The site build passes none of them, so the page and the PDFs on the site
// show only what is in `public`.
#let private-input(key) = sys.inputs.at(key, default: none)
#let contact = (
  name: "Lucien Huber",
  email: "mail@lucien.ch",
  phone: private-input("phone"),
  address: private-input("address"),
  birthday: {
    let b = private-input("birthday")
    if b != none {
      let (y, m, d) = b.split("-").map(int)
      datetime(year: y, month: m, day: d)
    }
  },
  photo: "/assets/cv/headshot.jpg",
)
#let public = ("email", "photo") + ("phone", "address", "birthday").filter(k => contact.at(k) != none)

#let d(y, m, day: 1) = datetime(year: y, month: m, day: day)

// One entry: `title`, `location`, `start`, `end` (none = ongoing), `body`.
// Fields that differ by language are (en: ..., fr: ...).
#let education = (
  (
    title: (en: "PhD in Physics", fr: "Doctorat en Physique"),
    location: "Unibe",
    start: d(2023, 9), end: none,
    body: (
      en: [Currently doing a PhD in theoretical physics, automating high-precision predictions of cross-sections in Quantum Field Theory.],
      fr: [Actuellement en doctorat de physique théorique, en train d'automatiser les prédictions de haute précision des sections efficaces en Théorie des Champs Quantique.],
    ),
  ),
  (
    title: (en: "MSc in Physics", fr: "Msc. Physique"),
    location: "ETH Zurich",
    start: d(2020, 9), end: d(2022, 11),
    body: (
      en: [Overall average: 5.43/6. \ Master's thesis: "Gravitational waves from Feynman diagrams", available #link("https://lucien.ch/research/msc-thesis/")[here].],
      fr: [Moyenne générale : 5.43/6. \ Thèse de Master : « Gravitational waves from Feynman diagrams », disponible #link("https://lucien.ch/research/msc-thesis/")[ici].],
    ),
  ),
  (
    title: (en: "EPFL–McGill exchange year", fr: "Échange universitaire EPFL-McGill"),
    location: "McGill, Montréal, Canada",
    start: d(2019, 8), end: d(2020, 4),
    body: (
      en: [Courses: Geometry & Topology 1 and 2, Geometric Group Theory, Electromagnetic Theory, Advanced Statistical Mechanics, Quantum, Nuclear, Solid State, and Particle Physics.],
      fr: [Sujets : Geometry & Topology 1 and 2, Geometric Group Theory, Electromagnetic Theory, Advanced Statistical Mechanics, Quantum, Nuclear, Solid State, and Particle Physics.],
    ),
  ),
  (
    title: (en: "BSc in Physics", fr: "Bsc. Physique"),
    location: "EPFL",
    start: d(2017, 8), end: d(2020, 8),
    body: (en: [Overall average: 5.44/6.], fr: [Moyenne générale : 5.44/6.]),
  ),
  (
    title: (en: "Bilingual Maturité with distinction", fr: "Maturité Bilingue avec Mention"),
    location: "Collège André-Chavanne",
    start: d(2013, 8), end: d(2017, 8),
    body: (en: [Overall average: 5.71/6.], fr: [Moyenne générale : 5.71/6.]),
  ),
  (
    title: (en: "Euler Course", fr: "Cours Euler"),
    location: "EPFL",
    start: d(2012, 8), end: d(2017, 8),
    body: (
      en: [For five years I followed a mathematics course for motivated secondary and high-school students. It replaced my school mathematics classes and covered the Maturité syllabus as well as the first year of a BSc in Mathematics.],
      fr: [J'ai suivi pendant cinq ans un cours de mathématiques destiné à des élèves motivés de collège et de lycée. Ce cours a remplacé mes cours de mathématiques et a couvert la matière enseignée en maturité ainsi que la première année de Bsc en Mathématiques.],
    ),
  ),
)

#let experience = (
  (
    title: (en: "PhD in Physics", fr: "Doctorat en Physique"),
    location: "Unibe",
    start: d(2023, 9), end: none,
    body: (
      en: [Alongside my research in the group, I am a teaching assistant for several courses and look after the websites of the #link("https://itp.unibe.ch")[Institute for Theoretical Physics].],
      fr: [En plus de ma recherche au sein du groupe, je dois assurer l'assistanat de plusieurs cours, ainsi que gérer les différents sites web de l'#link("https://itp.unibe.ch")[Institut de Physique Théorique].],
    ),
  ),
  (
    title: (en: "Civilian service", fr: "Service Civil"),
    location: "Maison du Vélo, Lausanne VD",
    start: d(2023, 3, day: 20), end: d(2023, 9, day: 15),
    body: (
      en: [Activity leader at the Maison du Vélo, teaching asylum seekers to repair bicycles.],
      fr: [Animateur polyvalent à la Maison du Vélo, formation de requérants d'asile à la réparation des vélos.],
    ),
  ),
  (
    title: (en: "Civilian service", fr: "Service Civil"),
    location: "Domaine Wannaz, Chenaux VD",
    start: d(2023, 1, day: 9), end: d(2023, 2, day: 10),
    body: (
      en: [Upkeep of the cultivated landscape over the winter.],
      fr: [Entretien du paysage cultivé, hiver.],
    ),
  ),
  (
    title: (en: "Teaching assistant – 15 hours/week", fr: "Assistant - 15 heures/semaine"),
    location: "ETH Zurich",
    start: d(2021, 9), end: d(2021, 12),
    body: (
      en: [Student teaching assistant for Analysis I for physicists and mathematicians.],
      fr: [Assistant étudiant pour le cours d'Analyse I pour physiciens et mathématiciens.],
    ),
  ),
  (
    title: (en: "Teaching assistant – 14 hours/week", fr: "Assistant - 14 heures/semaine"),
    location: "ETH Zurich",
    start: d(2021, 3), end: d(2021, 7),
    body: (
      en: [Student teaching assistant for Mathematical Methods of Physics II (MMP II), a course on representation theory. I was also responsible for grading the exercise sheets.],
      fr: [Assistant étudiant pour le cours méthodes mathématiques pour physiciens (MMP II), un cours sur la théorie des représentations. J'ai été également responsable de la correction des feuilles d'exercices.],
    ),
  ),
  (
    title: (en: "Teaching assistant – 5 hours/week", fr: "Assistant - 5 heures/semaine"),
    location: "EPFL",
    start: d(2018, 7), end: d(2019, 8),
    body: (
      en: [Student teaching assistant for Programming for physicists and mathematicians (ICC). I spent 2 to 3 hours a week guiding students as they built an object-oriented particle-collision simulation, and led exercise sessions. I also helped grade the midterm and final exams of the autumn and spring semesters.],
      fr: [Assistant étudiant pour le cours de Programmation pour physiciens et mathématiciens (ICC). Plus précisément, j'ai accompagné les étudiants 2 à 3 heures par semaine dans la création d'une simulation de collision de particules orientée objet, et j'ai dirigé des séances d'exercices. J'ai également aidé à corriger les examens finaux et intermédiaires des semestres d'automne et d'été.],
    ),
  ),
  (
    title: (en: "Teaching assistant – 4 hours/week", fr: "Assistant - 4 heures/semaine"),
    location: "EPFL",
    start: d(2015, 8), end: d(2019, 8),
    body: (
      en: [Student teaching assistant for the Euler Course, with a class of young students from first to fourth year. Every Wednesday afternoon I supervised the students and taught them topics ranging from set theory to linear algebra and analysis.],
      fr: [Assistant étudiant pour le cours Euler pour une classe de jeunes étudiants de la première à la quatrième année. Tous les mercredis après-midi, je supervisais et donnais des cours aux étudiants sur des sujets allant de la théorie des ensembles à l'algèbre linéaire et l'analyse.],
    ),
  ),
)

#let languages = (
  en: ([*French, English* – full proficiency], [*German* – B2]),
  fr: ([*Français, Anglais* – maîtrise complète], [*Allemand* – B2]),
)

#let programming = ("Rust", "Julia", "C++", "Python", "R", "Typst", "Nix")

#let clubs = (
  (
    name: (en: "Swiss Alpine Club (CAS) Geneva", fr: "Club Alpin Suisse (CAS) Genève"),
    date: (en: [since 2020], fr: [depuis 2020]),
    body: (en: [Mountaineering, ski touring and climbing.], fr: [Alpinisme, ski de randonnée et escalade.]),
  ),
  (
    name: (en: "Club de Pontonniers de Genève", fr: "Club de Pontonniers de Genève"),
    date: (en: [since 2016], fr: [depuis 2016]),
    body: (en: [Stand-up rowing.], fr: [Rame debout.]),
  ),
  (
    name: (en: "McGill University rowing", fr: "Aviron universitaire de McGill"),
    date: (en: [autumn 2019], fr: [automne 2019]),
    body: (en: [Varsity-level rowing (every morning from 6 to 8 am).], fr: [Aviron de niveau universitaire (tous les matins de 6h à 8h).]),
  ),
)

#let hobbies = (
  en: [I like building things, whether woodworking, repairing bikes or tinkering with electronics. Design matters to me: I like drawing and sketching. I enjoy being outdoors, especially running, hiking and climbing.],
  fr: [J'aime construire des choses, que ce soit en travaillant le bois, en réparant des vélos ou en bricolant de l'électronique. Le design est important pour moi, j'aime dessiner et faire des croquis. J'aime les activités en plein air, notamment la course à pied, la randonnée et l'escalade.],
)

#let labels = (
  en: (
    title: "Curriculum Vitae", education: "Education", experience: "Experience",
    languages: "Languages", programming: "Programming", clubs: "Clubs", hobbies: "Hobbies",
    present: "present", pdf: "Download PDF", other: "Version française",
    summary: "Curriculum vitae of Lucien Huber, PhD student in theoretical physics.",
  ),
  fr: (
    title: "Curriculum Vitae", education: "Éducation", experience: "Expérience",
    languages: "Langues", programming: "Programmation", clubs: "Clubs", hobbies: "Hobbies",
    present: "aujourd'hui", pdf: "Télécharger le PDF", other: "English version",
    summary: "Curriculum vitae de Lucien Huber, doctorant en physique théorique.",
  ),
)

#let langs = ("en", "fr")
#let pdf-url(lang) = "/cv/lucien-huber-cv-" + lang + ".pdf"

// Everything for one language, with the (en:, fr:) fields resolved.
#let cv-data(lang) = {
  let pick(x) = if type(x) == dictionary and lang in x { x.at(lang) } else { x }
  let resolve(entry) = {
    let out = (:)
    for (k, v) in entry { out.insert(k, pick(v)) }
    out
  }
  (
    lang: lang,
    labels: labels.at(lang),
    contact: contact,
    public: public,
    education: education.map(resolve),
    experience: experience.map(resolve),
    languages: languages.at(lang),
    programming: programming,
    clubs: clubs.map(resolve),
    hobbies: hobbies.at(lang),
  )
}

#let month-year(date) = date.display("[month]/[year]")
#let date-range(e, present) = month-year(e.start) + " — " + if e.end == none { present } else { month-year(e.end) }


// ---------------------------------------------------------------------------
// PDF layout (A4), after the original Typst CV. Fonts in cv/fonts/; the body
// font is Reforma 2018 where it is installed, New Computer Modern otherwise.

#let heading-font = "Atkinson Hyperlegible"
#let body-font = ("Reforma 2018", "New Computer Modern")
#let size = 3mm

#let pdf-logo(unit: 4mm) = box(baseline: -0.5 * unit, {
  let bar = box(width: unit, height: 0.4 * unit, radius: 0.2 * unit, fill: black)
  let dot = box(width: 0.4 * unit, height: 0.4 * unit, radius: 50%, fill: black)
  let gap = h(0.6 * unit)
  bar + gap + dot + gap + dot + gap + bar + gap + dot + gap + dot
})

#let pdf-header(c) = {
  let c-contact = c.contact
  let show-it(key) = key in c.public
  set text(font: heading-font, size: 11pt)
  grid(
    gutter: 3mm,
    columns: (2fr, auto, 1fr, auto),
    align: (left, left, right),
    grid.cell(align: top, place(dy: 1mm, dx: 1mm, pdf-logo())),
    grid.cell(align: top, if show-it("phone") { link("tel:" + c-contact.phone.replace(" ", ""), c-contact.phone) }),
    grid.cell(align: top, if show-it("birthday") { c-contact.birthday.display("[month repr:short] [day], [year]") }),
    grid.cell(rowspan: 2, align: right + horizon, if show-it("photo") {
      box(image(c-contact.photo, width: 2cm, height: 2cm, fit: "contain"), height: 1.3cm, width: 2cm)
    }),
    grid.cell(align: bottom, text(size: 1.7em, c-contact.name)),
    grid.cell(align: bottom, if show-it("address") { c-contact.address }),
    grid.cell(align: bottom, if show-it("email") { link("mailto:" + c-contact.email, c-contact.email) }),
  )
}

#let pdf-step(e, present) = grid(
  columns: (3cm, auto),
  gutter: 2mm,
  date-range(e, present),
  grid(columns: (1fr, 1fr), align: (left, right), text(size: 1.03em, strong(e.title)), emph(e.location)),
  [],
  { set par(justify: true); set text(font: body-font); e.body },
)

#let pdf-section(name, steps, present) = {
  heading(name)
  grid(gutter: 3mm, columns: 1, ..steps.map(e => pdf-step(e, present)))
}

#let pdf-club(c) = grid(
  gutter: 1.4mm, columns: (2fr, 1fr), align: (left, right),
  text(size: 1.03em, strong(c.name)), emph(c.date),
  grid.cell(colspan: 2, { set par(justify: true); set text(font: body-font); c.body }),
)

#let cv-pdf(lang) = {
  let c = cv-data(lang)
  let l = c.labels
  set document(title: c.contact.name + " – " + l.title, author: c.contact.name)
  set page(paper: "a4")
  set text(lang: lang, font: heading-font, size: size)
  pdf-header(c)
  pdf-section(l.education, c.education, l.present)
  pdf-section(l.experience, c.experience, l.present)
  grid(
    columns: (1fr, 1fr),
    gutter: 2mm,
    column-gutter: 5mm,
    [= #l.languages
      #grid(columns: 3, gutter: 2mm, c.languages.join(", "))],
    grid(gutter: 2mm, heading(l.programming), c.programming.join(", ")),
    grid(gutter: 2mm, heading(l.clubs), ..c.clubs.map(pdf-club)),
    grid(gutter: 2mm, heading(l.hobbies), { set par(justify: true); c.hobbies }),
  )
}
