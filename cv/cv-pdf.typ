// PDF version of the CV, one per language:
//   typst compile --root . --font-path cv/fonts --input lang=fr cv/cv-pdf.typ cv-fr.pdf
// scripts/build.py builds both into dist/cv/. Content and layout: lib/cv.typ.
#import "/lib/cv.typ": cv-pdf
#cv-pdf(sys.inputs.at("lang", default: "en"))
