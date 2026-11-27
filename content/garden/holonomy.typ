#import "/lib/note.typ": note
#import "/lib/links.typ": n

// An example draft: `draft: true` keeps this note off the public site. It
// shows up only on the password-protected drafts site. Delete or publish it
// (remove the draft line) whenever you like.
#show: note.with(
  title: [Holonomy],
  summary: "What a connection does to a vector carried around a loop.",
  status: "seedling",
  tags: ("geometry",),
  draft: true,
)

Carry a vector around a closed loop with a #n(<gauge-connection>)[connection]
and it comes back rotated. The #n(<berry-phase>)[Berry phase] is the abelian
case.
