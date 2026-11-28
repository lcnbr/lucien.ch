#import "/lib/thesis.typ": chapter, acr, timg, subfigs, xref
#import "/lib/links.typ": n
#import "/lib/figures.typ": svg-math

#show: chapter.with(thesis: "msc-thesis", number: 4, summary: "Numerical relativity, post-Newtonian and post-Minkowskian expansions, and effective one-body.")

The matched filtering approach introduced in the previous section motivates the development of tools for generating waveforms. The matched filtering technique is especially sensitive to the phase of the #acr("gw", form: "full") , necessitating precise determination of the waveform template's phase. These templates can be varied in physical content, but also in practicality. In all cases they need to be able to cover the set of parameters (the parameter space) that one is interested in exploring. Clearly, if the waveform has been generated purely heuristically, then the physical content of the detection is close to zero. From this approach, one can only deduce that a phenomenon producing a similar waveform was detected, but not much more. However, if the input parameters are physically meaningful, e.g.~the mass ratio of a binary compact inspiraling system, then the waveform constructed purely from this input, if matched to the signal, tells us that a compact binary inspiraling system with this mass ratio has been detected. This is called parameter estimation, and is key to maximizing the physics output of a detection.

Crucially, the waveform generation must be able to cover the whole parameter space (for example all feasible mass ratios) to be useful, as one does #emph[not] know in advance the parameters describing the system to be identified. Ideally waveform generation should be done in a way that is computationally efficient, as the number of parameters as well as their range to explore is large. In the end, waveform generation is currently performed in a hybrid way: some waveforms for specific parameter space points, are generated from first principles, while the rest of the parameter space waveforms are interpolated.

In this chapter we will describe the first-principles waveform generation tools currently being developed. More specifically we will explore techniques for compact binary waveforms. In this context waveforms may describe inspiralling or scattering binaries. Currently, only the inspiralling binaries have been detected, as these are the systems whose signal #acr("ligo", form: "full") and other detectors are most sensitive to (see #xref(<sec-ligo>)[Section 3.1.1]), other than being by far the most common emitters of high-intensity #acr("gw", plural: true). As discussed in #xref(<sec-compactbinaries>)[Section 2.4.1], orbiting and #acr("gw") emitting compact objects will necessarily inspiral and merge at some point.

For such inspiraling binaries, the waveform features 3 distinct phases shown in the figure below: a first #emph[inspiral phase], a #emph[merger phase] where a remnant compact body is produced as a result of the coalescence of the two objects, and a postmerger, or #emph[ringdown phase], where the remnant still emits gravitational radiation while settling to its new stable configuration. Each phase is characterized by different dynamical properties of the orbiting bodies and thus different frameworks are aimed at describing the corresponding features of the waveforms. Even the description of one phase involves different regimes, and thus more specific framework, additionally dependent on the type/initial state of the two orbiting bodies.

#figure(timg("compactbin.png"),
  caption: [
    The different phases of an inspiraling binary. Source #cite(<LIGOScientific:2016aoc>, form: "prose")
  ]
)

There is also hope to detect scattering binaries as argued in #cite(<Mukherjee:2020hnm>, form: "prose"), but they are currently mainly used as a testbed for new theories making use of particle physics knowledge. Additionally, one might be able to extend their validity to inspiraling binaries @Kalin:2019rwq.

Most of these techniques have two important parts. The first consists in the precise modelling of the evolution of the emitting system. In most cases, this boils down to obtaining the #acr("eom", form: "full", plural: true) for the interacting bodies. For scattering, this can just be the amplitude of the event. The second part is extracting the variation of the metric due to the source movement at the measurement point, far away from the source, i.e., the waveform. Of course, the metric at the source is tightly coupled to the dynamics of the system, and thus the approximations conducted at the source also effects the way one extracts the waveform.

The only full, first-principles waveform techniques are #acr("nr", form: "full") and #acr("eob", form: "full") #footnote[There are a whole family of phenomenological frameworks that we will not discuss]. #acr("nr") is quite unique when compared to other methods. Let us look at it before proceeding to #acr("eob") and all the inspiral waveform techniques.

= #acr("nr", form: "long")
The most precise, first-principles waveform-generation technique to date is numerical relativity (#acr("nr")). It was developed as early as the 1960s @hahn:1964. Initially and until relatively recently, these numerical methods were unusable because of numerical instabilities. The idea, however, is simple: the #acr("efe", form: "full") are a system of coupled partial differential equations (PDEs) (albeit nonlinear) that can be solved numerically by discretizing the metric. The causes of instability is three-fold. First, the aforementioned non-linearities make the discretization particularly sensitive to extreme variations, such as those close to a #acr("bh", form: "full"), which means that one needs a fine mesh to control error buildup. Second, the gauge freedom establishes limits on the type of discretization procedures, so that spurious modes are not introduced. Third, for #acr("bh", plural: true) one needs to consider what to do about the physical metric singularity, as infinity is not a number one can plug into a computer! On top of stability problems, when compact binary objects are considered, the scales involved further complicate things, as one needs enough resolution to resolve the objects, and the deformations on the metric, as well as a large enough volume to have reasonable orbits. This requires a huge amount of lattice nodes, meaning such simulations (even if stable) are extremely computationally expensive.

In 2005 @Pretorius:2005gq and a little later @Campanelli:2005dd made a breakthrough advance and were able to fully compute an inspiral-merger-ringdown sequence for a #acr("bbh", form: "full") . Pretorius made use of two techniques: #acr("amr", form: "full") and the #acr("gh", form: "full") formalism. #acr("amr") , like its name suggests, is a technique based on a dynamical discretization procedure . The #acr("gh") formalism, tackles the singularity problem validating the excision of the black hole, and crucially letting that region move. The combination of the procedures, were able to finally slay the proverbial numerical dragon.

These waveforms, such as the one in #ref(<fig-pretwave>), confirmed the predictions made in @Buonanno:2000ef that the merger phase of a #acr("bbh") would not be as complicated as previously thought. As numerical techniques evolved further, they were able to elucidate more and more complex behaviors.

#figure(timg("pretwave.png"),
  caption: [
    The first #acr("nr") waveform, as presented in #cite(<Pretorius:2005gq>, form: "prose")
  ]
)
<fig-pretwave>

Nowadays, it is the gold standard of waveform generation. Of course, it remains incredibly computationally expensive #footnote[A single waveform with 10 orbits can take a week and tens of thousands of CPU hours] and making any sizable bank of purely #acr("nr") waveforms is seen as a fools endeavor. To date, only a couple hundred parameter space points have been simulated. Consequently, #acr("nr") is used to complement, calibrate and extend the other waveform generation techniques. For example to detect the first signals #acr("ligo") and other detectors interpolated between #acr("nr")-generated parameter space points to reach the ones needed for detection. However, with the advent of #acr("lisa", form: "full") on the horizon, a further problem will arise. #acr("nr") results by nature only take into account the last few orbit cycles before merger. Any more than that and computational time becomes prohibitive. #acr("lisa"), with its low noise floor, should be able to detect inspiraling but not yet merging binaries. Doing so will require waveform templates with hundreds of orbits, well out of reach of any modern #acr("nr") package. Nonetheless, this technique has shown and will continue to show its worth, as no approximations other than discretization are made. The physical content of such waveforms is thus high.

= Inspiral methods
Before continuing to the #acr("eob") method, let us look at the techniques that focus on the inspiral part of the waveform. There are broadly speaking three methods that fall in this category. The first we have already encountered at 1st order: #acr("pn", form: "full") . It is a perturbative expansion in both relative velocity (slow moving limit) and the coupling constant $G$ (weak field limit) of the #acr("efe") . The second is the #acr("pm", form: "full") method, which is a perturbative expansion in #emph[only] the coupling constant $G$. At face value the #acr("pm") method contains the #acr("pn") one as a special case, however as at zeroth order, the #acr("pm") approximation captures straight line motion, and is generally more expressive of scattering. The final approximation can be applied when the mass ratio of the object in question is large. Here one can expand around a fixed but #emph[non-flat] metric, essentially considering one of the objects as a test-particle evolving on a background caused by the heavier object. This is called the #acr("gsf", form: "full") formalism.

== #acr("pn", form: "long")
The #acr("pn") expansion, is a perturbative expansion of #acr("efe") in the orbital regime, which at #acr("lo", form: "full") reproduces Newtonian gravity. Consider a system of orbiting bodies with typical values $macron(M) \, macron(R) \, macron(v)$ for masses, separations, and velocities. Then, the viral theorem states:

$ chevron.l T chevron.r_tau = - 1 / 2 chevron.l U chevron.r arrow.r.double.long quad macron(M) macron(v)^2 tilde.op frac(G macron(M)^2, macron(R)) $ <eq-virial>

thus we can consider the following equivalent small parameters:

$ macron(v)^2 tilde.op frac(G macron(M), macron(R)) $

We therefore expand in both velocities and coupling constant. This can be achieved either by a classical (albeit quite complicated) perturbative treatment @Blanchet:2013haa @Blanchet:1995fg, or a more contemporary #acr("eft", form: "full")-based approach coyly called #acr("nrgr", form: "full") @Goldberger:2004jt @Sturani:2021xpq, itself inspired by #acr("nrqcd", form: "full") . We call $n$#acr("pm") the expansion carried out to $cal(O) \( v^(2 n) \)$.

Regardless of method, there are a few shortcomings with this expansion. While it is well suited to describe the #emph[motion] of objects in an orbital regime, it is not equally effective at describing gravitational radiation far from the source, as it exhibits divergences for $r arrow.r oo$#footnote[In HEP speak this is called an infrared divergence]. This means that in the #acr("gw") context, the #acr("pn") expansion is in fact usually coupled to a weak-field approximation (see below), outside the near zone. This is the region surrounding the source, that is of small extent compared to the wavelength of the emitted radiation:

$ r lt.double lambda $ <eq-nearzone>

The #acr("pn") expansion can also be viewed as an expansion in small 'retardations'. To see this, consider a slowly moving source, such that the time derivatives of the metric generated by this source will be smaller than the spatial derivatives by a factor $cal(O) \( v^() \)$, $ frac(partial, partial t) = cal(O) \( v^() \) frac(partial, partial x^i) \, $ or $partial_0 = cal(O) \( epsilon.alt \)^() \) partial_i$. Thus, the d'Alembertian operator, applied to the metric is, to lowest order, a Laplacian operator $ - 1 / c^2 frac(partial^2, partial t^2) + nabla^2 = [1 + O (epsilon.alt^2)] nabla^2 . $

This means that retardation effects, due to the time derivative, are small corrections. In the #acr("pn") expansion we are consequently trying to compute some quantity $F \( t - r \)$, such as a component of the metric, which is intrinsically a function of the retarded time $t_r = t - r$, from its expansion for small retardation $r$, $ F \( t_r \) = F \( t \) - r dot(F) \( t \) + r^2 / 2 dot.double(F) \( t \) + dots.h $

Importantly, the derivatives should bring down factors proportional to frequency $Omega$ of the emitted radiation. Thus, this is in fact an expansion in $r Omega tilde.op r \/ lambda$, which is only valid in the near zone as defined by #ref(<eq-nearzone>), and breaks down outside this zone, in the so-called #emph[radiation zone]. A serious consequence of this fact is that the pure, naive #acr("pn") expansion is unable to account for outgoing or incoming radiation, and thus unable to describe isolated systems. This is where the #acr("pm") expansion comes in.

== #acr("pm", form: "long")
#figure(timg("pmpntrans.png"),
  caption: [
    Comparison of #acr("pm") and #acr("pm") expansions, with currently attained orders encircled, and highlighted in red is the result of #cite(<Bern:2019crd>, form: "prose"). Source #cite(<Bern:2019crd>, form: "prose")
  ]
)
<fig-pnpm>

The #acr("pm") expansion is a weak field expansion of #acr("efe"), in the coupling constant $G$. It thus covers all orders in velocity of the #acr("pn") expansion, at any fixed $G$ order, see #ref(<fig-pnpm>). We usually call $n P M$ the corresponding $cal(O) \( G^n \)$-truncated expansion. Historically, it was derived with the objective of being the radiation zone partner to the #acr("pn") expansion, as it provides a description of the propagation of the waves up to the observer. When used with the #acr("pn") expansion in such a way, the #acr("pm") expansion is used to solve the vacuum #acr("efe") . It is usually set up to compute a version of the metric perturbation that is exact:#footnote[We have used $h zws_(mu nu)$to denote the linear perturbation, whereas$sans("h") zws_(mu nu)$ is the all order metric perturbation.]

$ sans("h") zws_(mu nu) = sqrt(- g) g zws^(mu nu) - eta zws^(mu nu) . $

The #acr("pm") expansion is then given as

$ sqrt(- g) g zws^(mu nu) = eta zws^(mu nu) + G sans("h")_1 zws^(mu nu) + G^2 sans("h")_2 zws^(mu nu) + dots.h \, $

meaning that: $ sans("h") zws^(mu nu) = sum_(n = 1)^oo G^n sans("h")_n zws^(mu nu) . $

The #acr("efe") for this metric perturbation, when imposing De-Donder gauge conditions (#xref(<eq-dedonder>)[Eq. (2.9)]), is given by

$ square.stroked_(S R) sans("h") zws^(mu nu) = - 16 pi G sans("h") zws^(mu nu) tau zws^(mu nu) . $ <eq-relEFE>

where $tau zws^(mu nu)$ is the effective energy-momentum tensor given by:

$ tau zws^(mu nu) = \( - g \) T zws^(mu nu) - frac(1, 16 pi G) Lambda zws^(mu nu) . $

$Lambda zws^(mu nu)$ contains all non-linear terms of the Einstein tensor, and its definition can be obtained by comparing with #xref(<eq-EFE>)[Eq. (2.1)]. Thus, it depends on the metric and thus on $sans("h") zws_(mu nu)$ in a highly non-linearly fashion. We can write it as:

$ Lambda zws^(mu nu) = L zws^(mu nu) \[ sans("h") \, sans("h") \] + M zws^(mu nu) \[ sans("h") \, sans("h") \, sans("h") \] + N zws^(mu nu) \[ sans("h") \, sans("h") \, sans("h") \, sans("h") \] + cal(O) \( sans("h")^5 \) . $

Here the number of $sans("h")$'s in the argument of $L \, M$ and $N$ indicates the order of the non-linear term. In a vaccuum #ref(<eq-relEFE>) reduces to

$ square.stroked_(S R) sans("h") zws^(mu nu) = Lambda zws^(mu nu) \, $

which we can solve iteratively order by order:

$ square.stroked_(S R) sans("h")_1 zws^(mu nu) & = 0 \,\
square.stroked_(S R) sans("h")_2 zws^(mu nu) & = L zws^(mu nu) \[ sans("h")_1 \, sans("h")_1 \] \,\
square.stroked_(S R) sans("h")_3 zws^(mu nu) & = M zws^(mu nu) \[ sans("h")_1 \, sans("h")_1 \, sans("h")_1 \] + L zws^(mu nu) \[ sans("h")_1 \, sans("h")_2 \] + + L zws^(mu nu) \[ sans("h")_2 \, sans("h")_1 \]\
 $

This method can be supplemented by a multipolar expansion of the $sans("h")_n zws^(mu nu)$, truncated to the specific #acr("pm") order we are interested in. This combined expansion was pioneered by @Bonnor:1959, then formalised by @Thorne:1980ru, and finally applied in this present context by @Blanchet:1986.

In terms of source dynamics, it is more appropriate (and uniquely able) to describe inherently relativistic phenomena, such as gravitational scattering. Its wider scope of applicability comes at the cost of a higher computational complexity, as at higher orders one encounters intricate families of relativistic integrals. Note that we have in fact computed the 1 #acr("pm") approximation already in the #n(<msc-thesis-gw-detection>)[Chapter 3] when we linearized the #acr("efe"). Higher orders are far more difficult to obtain, especially for sources such as #acr("bbh").

With the rise of amplitude techniques from high energy physics, both #acr("eft") and full theory results have been successful in extracting previously unreachable orders. Such techniques are perfectly suited to compute relativistic scattering as they were developed for this specific task. We will see this in the next chapter.

= #acr("eob", form: "long")
The second full-waveform generation technique is the #acr("eob") formalism. It was initially developed by @Buonanno:1998gg, as a non-perturbative re-summing of the #acr("pn") expansion. It was later extended to include the merger and ringdown effects in @Buonanno:2000ef and one can see the produced waveform in \@. Thus, it became the first full waveform generating technique to actually produce a waveform. It has gotten progressively more powerful, as the #acr("pn") expansions have gotten better. More recently #acr("pm") results have also been included #cite(<Damour:2016gwp>, form: "prose"). Additionally, #acr("eob") can be combined with #acr("nr") to produce a very accurate waveform, with less computational overhead than #acr("nr") alone.

#figure(timg("firsteob.png"),
  caption: [
    First full #acr("eob") waveform, from #cite(<Buonanno:2000ef>, form: "prose")
  ]
)
<fig-firsteob>

As its name suggests, the #acr("eob") framework combines all the #acr("pn"), #acr("pm") and #acr("nr") data into a Hamiltonian describing the motion of a single body. It is inspired by solutions of two-body problems in Newtonian gravity which make use of barycentric coordinates to turn it into a one body problem. Further inspiration came from the two body problem in #acr("qed", form: "full") @Brezin:1970zr .

Consider two bodies, with masses $m_1$ and $m_2$, positions $upright(bold(q))_1$, $upright(bold(q))_1$ and momenta $upright(bold(p_1))_()$ and $upright(bold(p_2))_()$ respectively. The system can be described by the following Hamiltonian:

$ cal(H)_(upright("newton")) \( upright(bold(q))_1 \, upright(bold(q))_1 \, upright(bold(p_1))_() \, upright(bold(p_2))_() \) = frac(upright(bold(p_1))_()^2, 2 m_1) + frac(upright(bold(p_2))_()^2, 2 m_2) - frac(G m_1 m_2, \| upright(bold(q))_1 - upright(bold(q))_1 \|) $

One then transforms this Hamiltonian into one describing the relative motion $upright(bold(q))_() = upright(bold(q))_1 - upright(bold(q))_1$. One can formalize this by defining a new set of generalized coordinates, through a canonical transformation. We can go even further and employ a generating function for the transformation, ensuring that Hamilton's equations remain unchanged in form (see #cite(<Goldstein:2002>, form: "prose")). To describe relative motion, we use Jacobi coordinates $\( upright(bold(Q))_() \, upright(bold(q))_() \)$: $ vec(upright(bold(q))_1, upright(bold(q))_2) arrow.r underbrace(mat(delim: "(", m_1 / M, m_2 / M; 1, - 1), = A) vec(upright(bold(q))_1, upright(bold(q))_2) = vec(upright(bold(Q))_(), upright(bold(q))_()) $ <eq-jacobi2>

If we now define the following generating function for the transformation, depending on the old positions coordinates $upright(bold(q))_i$ and the new momenta $upright(bold(P))_i$: Note the use of Einstein summation

$ f_(I I) \( upright(bold(q))_i \, upright(bold(P))_i \) = upright(bold(P))_i A^(i j) upright(bold(q))_j \, $ <eq-genfunc>

then the old momenta are given by

$ upright(bold(p_i))_() = frac(partial_()^() f_(I I), partial_() upright(bold(q))_i^()) = upright(bold(P))_i A^(i j) arrow.l.r.double upright(bold(P))_i = \[ A^(- 1) \] zws^(i j) upright(bold(p_j))_() . $ <eq-momtrans>

Where we can directly invert this equation and obtain the new momenta as:

$ vec(upright(bold(P))_(), upright(bold(p))_()) = vec(upright(bold(P))_1, upright(bold(P))_2) = mat(delim: "(", 1, 1; m_2 / M, - m_1 / M) vec(upright(bold(p_1))_(), upright(bold(p_2))_()) $

As expected, we obtain that one of the momenta describes the center of mass momentum $upright(bold(P))_() = upright(bold(p_1))_() + upright(bold(p_2))_()$. The other positions are by construction given by $frac(partial_()^() f_(I I), partial_() upright(bold(q))_1^()) = upright(bold(Q))_()$ and $frac(partial_()^() f_(I I), partial_() upright(bold(q))_2^()) = upright(bold(q))_()$ i.e the same as equation #ref(<eq-jacobi2>). Finally the new Hamiltonian $cal(H)_(upright("rel")) \( upright(bold(Q))_() \, upright(bold(q))_() \, upright(bold(P))_() \, upright(bold(p))_() \)$ can be directly obtained from the generating function:#footnote[We just plug in the definition of the old momenta in terms of the new (#ref(<eq-momtrans>)): $upright(bold(p_1))_() = m_1 / M upright(bold(P))_() + upright(bold(p))_() \,$ $upright(bold(p_2))_() = m_2 / M upright(bold(P))_() - upright(bold(p))_() .$]

#svg-math[$ cal(H)_(upright("rel")) \( upright(bold(Q))_() \, upright(bold(q))_() \, upright(bold(P))_() \, upright(bold(p))_() \) = cal(H)_(upright("newton")) \( upright(bold(Q))_() \, upright(bold(q))_() \, upright(bold(P))_() \, upright(bold(p))_() \) + cancel(frac(partial_()^() f_(I I), partial_() t^())) = frac(upright(bold(P))_()^2, 2 M) + frac(upright(bold(p))_()^2, 2 mu) - frac(G m_1 m_2, \| upright(bold(q))_() \|) \, $]

where $M = m_1 + m_2$ is the total mass, and $mu = frac(m_1 m_2, M)$ is the reduced mass. If we change coordinates to a frame where the $upright(bold(Q))_()$ is at rest, i.e.~$upright(bold(P))_() = 0$, the Hamiltonian collapses to a one body Hamiltonian. The two-body problem we started with can now be though of as the one body problem of a test-particle of mass $mu$ orbiting an external mass $M$.

In Newtonian gravity, a small change of coordinates makes the two body problem exactly solvable. In much the same way, #acr("eob") generalizes this framework to general relativity. The defining trick used above is to transform to 'better' coordinates. A first step is to demand that for straight line motion the #acr("com", form: "full") energy $E_(upright("COM")) = P zws^0$, where $P$ it the 4-momentum of the entire-system, is equal to the Hamiltonian. We then have:#footnote[In the #acr("com") frame, the spatial part of the total momentum is zero (by definition), and thus we have: $P zws_0^2 = P^2 = \( p_1 + p_2 \)^2 = p_1^2 + p_2^2 + 2 p_1 dot.op p_2 .$]

$ cal(H) = sqrt(M^2 \( 1 + 2 nu \( gamma - 1 \) \)) \, $

where $nu = mu / M$ is the symmetric mass ratio, and $gamma = 1 / sqrt(1 - v^2) = frac(p_1 zws^mu p_2 zws_mu, m_1 m_2)$ is the relative Lorentz-factor. Note that for non-interacting systems we have $p_() zws_mu p_() zws^mu = mu^2$ and we can define the effective Hamiltonian:

$ cal(H)_(upright("eff")) = p_() zws^0 = sqrt(mu^2 + upright(bold(p_()))_()^2) = mu gamma . $ <eq-straightheff>

We can substitute this into the Hamiltonian above, and add back a generic system momentum $upright(bold(P))_()$ and obtain

$ cal(H)_(upright("eob")) = sqrt(M^2 \( 1 + 2 nu \( cal(H)_(upright("eff")) / mu - 1 \) \) + upright(bold(P))_()^2) $

This Hamiltonian (with $cal(H)_(upright("eff"))$ given by #ref(<eq-straightheff>)) now describes straight line motion in a relativistic framework. The key point is that we can take $cal(H)_(upright("eff"))$ to be a gravitational test mass Hamiltonian, with some specific deformations and this will match the #acr("pn") result. Consider a test mass in a Schwarzschild background #xref(<eq-Schwarzschild>)[Eq. (2.29)], i.e.~we consider the case of non-spinning black holes. We can start from the reduced-mass shell expression:

$ g zws^(mu nu) p_() zws^mu p_() zws^nu = - mu^2 $ <eq-schwarzmassshell>

where $g zws^(mu nu)$ is given by #xref(<eq-Schwarzschild>)[Eq. (2.29)], where we can set $theta = 1 / 2 pi$ to fix the orientation #footnote[This is always possible through a change of variables.]. Just as before, the effective Hamiltonian is the 0th component of the momentum, which is implicitly given by #ref(<eq-schwarzmassshell>):

$ cal(H)_S = sqrt(A_S \( mu^2 + A_S p_r^2 + L^2 / r^2 \)) \, $

where $A_S = frac(1, 1 - R_S \/ r)$, $p_r$ and $L = p_phi.alt$ are the radial and angular momentum respectively. We then allow deformations from this Hamiltonian defining

$ cal(H)_(upright("eff")) \( r \, p_r \, phi.alt \, L \) = sqrt(A \( mu^2 + A macron(D) p_r^2 + L^2 / r^2 \) + Q) \, $

where $A \, macron(D) \, Q$ are the so-called #acr("eob") potentials. $A \, macron(D)$ correspond to the radial potentials of the effective metric, while $Q$ contains terms quadratic in the momentum. We can then match these to #acr("pn") results, by matching observables.

This is more than a neat trick as this Hamiltonian, when well-matched, fits the gold standard #acr("nr") result up to the merger, well out of the #acr("pn") regime. Crucially, this Hamiltonian framework does not take into account radiation reaction by construction since it is based on conserved energy. These dissipative effects are included after the fact, as friction terms in the #acr("eom"). The usual conservative #acr("eom") is straightforwardly obtained through Hamilton's equations:

#svg-math[$ dot(r) & = frac(partial_()^() cal(H)_(upright("eff")), partial_() p_r^()) \, quad dot(p_r) = - frac(partial_()^() cal(H)_(upright("eff")), partial_() r^())\
omega = dot(phi.alt) & = frac(partial_()^() cal(H)_(upright("eff")), partial_() L^()) \, quad dot(L) = cancel(- frac(partial_()^() cal(H)_(upright("eff")), partial_() phi.alt^())) . $]

Note that, as expected, the angular momentum is conserved. We will now spoil this conservation, by adding friction forces, also called radiation reaction forces to the #acr("eom", plural: true) governing radial and angular momentum dynamics:

$ dot(p_r) & = - frac(partial_()^() cal(H)_(upright("eff")), partial_() r^()) + f_r \,\
dot(L) & = f_phi.alt . $

We can now express the energy loss:

$ dot(E) = frac(upright(d)^() cal(H)_(upright("eff")), upright(d) t^()) = frac(partial_()^() cal(H)_(upright("eff")), partial_() r^()) dot(r) + frac(partial_()^() cal(H)_(upright("eff")), partial_() p_r^()) dot(p_r) + frac(partial_()^() cal(H)_(upright("eff")), partial_() L^()) dot(L) = f_r dot(r) + f_phi.alt omega . $

Such dissipative effects are accounted for by matching to #acr("pn") results for the angular momentum and energy fluxes, which are given by the so called balance laws:

$ chevron.l cal(F)_L chevron.r & = - chevron.l dot(L) chevron.r = - chevron.l f_phi.alt chevron.r \,\
chevron.l cal(F)_E chevron.r & = - chevron.l dot(E) chevron.r = - chevron.l f_r dot(r) + f_phi.alt omega chevron.r . $

We have denoted averaging with angle brackets. With this we obtain as full of a picture of the inspiral as possible given the inputs, namely #acr("pn") . The matching can also be done with #acr("pm") and #acr("nr") results, further increasing the validity and precision of #acr("eob") . Of course, we are still missing the merger and ringdown phases. The merger, or plunge was predicted in #cite(<Buonanno:2000ef>, form: "prose") to be simply the peak in the waveform. This waveform is connected smoothly to a ringdown waveform, defined by a sum of quasi-normal modes of the remnant after merger. Thus, one obtains a sort of Frankenstein waveform, pooling resources from #acr("pn") , #acr("pm") , #acr("nr") and #acr("bh") perturbation theory. Importantly, when well-matched, this waveform is almost as accurate as #acr("nr") results, but with the added benefit of being able to be computed in a reasonable amount of time. Of course, it is still only as powerful as the inputs to which we match, namely the #acr("pn") or #acr("pm") results. We will explore how to compute #acr("pm") results using amplitudes in the next section.
