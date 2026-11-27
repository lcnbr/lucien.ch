#import "/lib/note.typ": note
#import "/lib/links.typ": n

#set math.equation(numbering: "(1)")
#show: note.with(
  title: [Berry phase],
  summary: "The geometric phase of an adiabatically transported eigenstate.",
  status: "budding",
  tags: ("geometry", "quantum"),
)

Transport an eigenstate $|n(bold(R))chevron.r$ of $H(bold(R))$ slowly around a
closed loop $C$ in parameter space. Besides the dynamical phase it picks up

$ gamma_n (C) = i integral.cont_C chevron.l n(bold(R)) | nabla_bold(R) n(bold(R)) chevron.r dot dif bold(R) $ <eq-berry>

The integrand is a #n(<gauge-connection>)[connection] on the bundle of
eigenstates, so $gamma_n$ is the holonomy of that connection, the abelian
version of a #n(<wilson-loop>)[Wilson loop]. By Stokes,

$ gamma_n (C) = integral_S bold(Omega)_n dot dif bold(S), quad
  bold(Omega)_n = nabla_bold(R) times bold(A)_n $ <eq-curvature>

@eq-curvature turns the line integral @eq-berry into a flux of the
Berry curvature through any surface bounded by $C$.
