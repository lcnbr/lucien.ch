// PDF version of the CV, one per language:
//   typst compile --root . --font-path cv/fonts --input lang=fr cv/cv-pdf.typ cv-fr.pdf
// scripts/build.py builds both into dist/cv/. Content and layout: lib/cv.typ,
// which also says how to add your phone, address and birthday to a PDF you
// build yourself (they are not in the repository).
#import "/lib/cv.typ": cv-pdf
#cv-pdf(sys.inputs.at("lang", default: "en"))
