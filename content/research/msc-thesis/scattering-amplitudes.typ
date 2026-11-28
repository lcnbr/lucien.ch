#import "/lib/thesis.typ": chapter, acr, timg, subfigs, xref
#import "/lib/links.typ": n
#import "/lib/figures.typ": svg-math

#show: chapter.with(thesis: "msc-thesis", number: 5, summary: "From amplitudes to potentials, the KMOC formalism, and scalar QED amplitudes computed with QGRAF, Julia and FORM.")

Whilst we have almost no hope to detect any #acr("gw", form: "full") scattering events with current experimental apparatuses, the scattering formalism can still be very useful in the quest for orbital waveforms. Most importantly, while experimental data has not been driving #emph[gravitational] scattering theory, the interplay between #emph[particle] scattering experiment and theory have been an enormously fruitful endeavor for the understanding of fundamental interactions in #acr("hep", form: "full"). The back and forth between precise measurements (such as those conducted at the #acr("lhc", form: "full") ) and precise predictions for particle scattering, has pushed the boundaries of the calculations possible. It would be therefore very beneficial if one could apply the large knowledge acquired for small non-gravitationally interacting particles, to large compact orbiting bodies. We will see that it is indeed the case.

Such techniques including #acr("eft", form: "full"), double copy, generalized unitarity, #acr("ibp", form: "full") reduction, differential equations methods, developed in the context of perturbative computations of collider observables now find an application to the scattering problem in gravity. A key part of applying tools originally developed for quantum systems to problems in gravity is controlling the classical limit, a historically difficult endeavor. Once scattering data is obtained, one needs to extract the relevant observables. This may be in an effort to compare results from the different methods, in which case gauge and diffeomorphism, and Lorentz invariance are key, since different methods make different gauge and frame choices. It can also be to extract the relevant information for detection and data extraction, in which case the #acr("gw") waveform is the relevant observable. In the latter case one is mostly interested in the orbital waveform, and thus a map from unbound to bound orbits is necessary.

Multiple formalisms have arisen to map the scattering problem to an orbital one, and the quantum formalism to a classical one. One key way is to map scattering data to a potential (as present in a Hamiltonian for example). In fact this has been developped as early as the 1970s in @Hiida:1972xs @Iwasaki:1971vb. Further developments happened in @Neill:2013wsa @Bjerrum-Bohr:2013bxa @Vaidya:2014kza @Cachazo:2017jef @Guevara:2017csg @Damour:2016gwp. Here we will follow the treatment in @Cheung:2018wkq, where the conservative part of such scattering amplitudes is matched to an #acr("eft") and subsequently to mapped to a potential. Recent efforts to add dissipative effects have also been successful @Kalin:2022hph. This potential can then be used as input to the #acr("eob", form: "full") formalism. Furthermore, @Kalin:2019rwq @Kalin:2019inp, have shown a path forward in directly extending unbound data to bound orbits, obviating the need to use a potential and #acr("eob") at all.

Finally, as mentioned in the last chapter, scattering can stand on its own and still be useful without being extended to the orbital case. The #acr("pm", form: "full") approximation can be computed from scattering amplitudes in an #acr("eft") framework @Kalin:2020mvi. We can also explore the classical observables possible in scattering scenarios. This has been developed in #cite(<Kosower:2018adc>, form: "prose") and was extended to local observables #footnote[local as in not time integrated and thus presenting time dependent dynamics] such as waveforms in #cite(<Cristofoli:2021vyo>, form: "prose").

In this chapter we will first look at how to use amplitude data to extract orbital and scattering waveforms. We will then look at the #acr("kmoc", form: "full") formalism to directly extract observables. Finally, we will look at how to compute amplitudes, and comparing to results such as those in @Kosower:2018adc @Bern:2021xze.

= Scattering amplitudes
<sec-scatamp>
In #acr("qft", form: "full"), to date the only way to encode scattering data is through a scattering amplitude. Consider a process where one starts out with a set of particles described by a state $\| i chevron.r_(upright(""))$, that interact, and yield a final state $\| f chevron.r_(upright(""))$. The scattering amplitude is then defined as the probability amplitude for this process to occur. It is simply given by $ chevron.l i \| S - 1 \| f chevron.r = \( 2 pi \)^4 delta^(\( 4 \)) \( p_f - p_i \) circle(dotless.i) cal(A)_(f i)^() \, $

where $S$ is the S-matrix, encoding asymptotic time evolution, $S = U_t \( - oo \, + oo \)$. We subtract the identity from it, forming what some call the transfer matrix $T$, as we only are interested in processes where something happens (i.e.~not everything stays the same). In the above equation we also define the #emph[scattering matrix element] $cal(A)_(f i)^()$ @Srednicki:2007[p.~76] or #emph[invariant Feynman amplitude] @Coleman:2018a[p.214], by factoring out a normalized spacetime delta-function that impose the conservation of momentum on the external particles, and a complex unit. The computation of $cal(A)^()$ is made possible by the #acr("lsz", form: "full") @Lehmann:1954rq @Collins:2019ozc formalism, which relates $cal(A)_(f i)^()$ to time-ordered correlation functions (also known as Green's functions) of the given QFT. Green's functions, can be expanded as an infinite sum of diagrams, weighted by a small coupling. The diagrams encode integrals that are obtained by applying Feynman rules which can be readily extracted from an action describing the theory.

= From amplitude to potential
<sec-amp2pot>
Let us now look at how to map the amplitude to the gravitational potential within the #acr("eob") formalism. We will follow the treatment in #cite(<Cheung:2018wkq>, form: "prose"). We start by defining the effective theory that describes our problem: thi orbiting bodies are described by two scalar fields $f_1$ and $f_2$ with masses $m_1$ and $m_2$ interacting through a long range potential $V \( r \)$. It is the #acr("eft") for non-relativistic fields. This #acr("eft") is described by the following action

$ S = integral thin upright(d)^() t thin cal(L)_(upright("kin")) + cal(L)_(upright("int")) \, $

where the kinetic term is given by:

$ cal(L)_(upright("kin")) = & integral thin tilde(upright(d))^(D - 1) upright(bold(k))_() thin f zws^(*)_1 \( - upright(bold(k))_() \) \( circle(dotless.i) partial_t - sqrt(upright(bold(k))_()^2 + m_1) \) f_1 \( upright(bold(k))_() \) \,\
 & + integral thin tilde(upright(d))^(D - 1) upright(bold(k))_() thin f zws^(*)_2 \( - upright(bold(k))_() \) \( circle(dotless.i) partial_t - sqrt(upright(bold(k))_()^2 + m_2) \) f_2 \( upright(bold(k))_() \) \, $

and the interaction term is given by

$ cal(L)_(upright("int")) = - integral thin tilde(upright(d))^(D - 1) upright(bold(k))_() thin thin tilde(upright(d))^(D - 1) upright(bold(k'))_() thin V \( upright(bold(k))_() \, upright(bold(k'))_() \) f zws^(*)_1 \( upright(bold(k'))_() \) f zws^(*)_2 \( - upright(bold(k'))_() \) f_1 \( upright(bold(k))_() \) f_2 \( - upright(bold(k))_() \) . $

This theory is obtained from the full one by integrating out all the massless force carriers , which are consequently encoded in the potential $V \( upright(bold(k))_() \, upright(bold(k'))_() \)$ and taking the non-relativistic limit $\| upright(bold(k))_() \| \, \| upright(bold(k'))_() \| lt.double m_(1 \, 2)$. In a classical system we assume the particles to be separated by a minimum distance, called impact parameter $\| upright(bold(b))_() \|$, and consider that their Compton wavelength $ell_c tilde.op frac(1, \| upright(bold(k))_() \|) \, frac(1, \| upright(bold(k'))_() \|)$#footnote[Note the use of natural units.] is much smaller than this separation,

$ \| upright(bold(b))_() \| lt.double ell_c tilde.eq frac(1, \| upright(bold(k))_() \|) \, frac(1, \| upright(bold(k'))_() \|) . $

This ensures that the particles are not interacting quantum mechanically in any significant way. Interestingly this hierarchy of scales can be rewritten as:

$ upright(bold(J))_() tilde.op \| upright(bold(k))_() times upright(bold(b))_() \| gt.double 1 . $

Thus, any two body classical system has large angular momentum. We can extract the classical part of any quantity by taking the #acr("lo", form: "full") contribution in the inverse of the angular momentum, or equivalently:

$ 1 / J prop frac(1, \| b \|) tilde.op \| upright(bold(k))_() - upright(bold(k'))_() \| prop 1 / kappa \, $ <eq-invang>

where $kappa$ is the coupling constant, which in the case of gravity is $kappa = 4 pi G$. For the first relation we used that angular momentum is proportional to separation. We then applied the fact that in scattering scenarios the impact parameter is proportional to the inverse of the momentum transfer $tilde.op frac(1, \| upright(bold(q))_() \|)$ where :

$ q = \( 0 \, upright(bold(q))_() \) = \( 0 \, upright(bold(k))_() - upright(bold(k'))_() \) . $

The last relation in #ref(<eq-invang>) holds due to the virial theorem. Since the potential must encode the coulomb potential $kappa \/ \| upright(bold(k))_() - upright(bold(k'))_() \|^2 prop J^3$, it must scale similarly. We thus formulate the following ansatz for the potential: $ V \( upright(bold(k))_() \, upright(bold(k'))_() \) = sum_(n = 1)^oo frac(kappa^n, \| upright(bold(k))_() - upright(bold(k'))_() \|^(D - 1 - n)) c_n \( frac(upright(bold(k))_()^2 + upright(bold(k'))_()^2, 2) \) $ <eq-ansatzpot>

Note that higher order terms in the potential could be formed by any polynomial of momentum invariants $upright(bold(k))_()^2$, $upright(bold(k'))_()^2$, and $upright(bold(k))_() dot.op upright(bold(k'))_()$. However, not all combinations of these are independent. The ansatz is chosen such that only the variables $\| upright(bold(k))_() - upright(bold(k'))_() \|$ and $upright(bold(k))_()^2 + upright(bold(k'))_()^2$ are present, as the others can be reabsorbed by field redefinitions, or vanish on-shell, such as $upright(bold(k))_()^2 - upright(bold(k'))_()^2$. Note as-well that we work in $D = 4 - 2 epsilon.alt$ dimensions such that the integrals are dimensionally regulated @tHooft:1972tcz. In particular an $epsilon.alt$-power corresponds to a logarithm #footnote[The third term in the sum is given by $kappa^3 ln \( upright(bold(k))_() - upright(bold(k'))_() \)^2 c_3 \( 1 / 2 upright(bold(k))_()^2 + upright(bold(k'))_()^2 \)$.]. Finally, note that in gravity this is precisely a #acr("pm") expansion!

== EFT amplitude
The first step in establishing determining the potential from a generic scattering amplitude computed in the full theory is to compute the amplitude in the #acr("eft"). We first identify the Feynman rules from the action. The kinetic term encodes the propagator:

#figure(timg("propagator.svg"),
  caption: [
    Propagator rule
  ]
)
<fig-propagator>

where the $circle(dotless.i) 0$ is the Feynman prescription for avoiding the poles. The interaction term is encoded in the vertex

#figure(timg("vertex.svg"),
  caption: [
    Vertex rule
  ]
)
<fig-vertex>

The expression for the #acr("eft") amplitude will contain the coefficient functions from #ref(<eq-ansatzpot>) since they will be present as vertex terms. Particle number must be conserved in the non-relativistic limit #footnote[As pair production is kinematically forbidden.], so the amplitude is a sum of bubble diagrams:

#figure(timg("eftampl.svg"),
  caption: [
    EFT amplitude
  ]
)
<fig-eftampl>

We can consequently neatly organize the amplitude into a sum of terms with specific loop counts. We can also equivalently organize it into a sum of terms with specific $kappa$ powers. We write,

$ cal(A)_(upright("EFT"))^() = sum_(L = 0)^oo cal(A)_(upright("EFT"))^(L upright("loop")) = sum_(i = 1)^oo cal(A)_(upright("EFT"))^(\( i \)) . $

Notably, these partitions do not line up for the #acr("eft") since the vertex contains all powers of the coupling. This is in contrast to the full theory where in fact they yield the same partition. We will eventually want to partition over the coupling power to compare the full theory.

Since every cut of the diagrams contributing to $cal(A)_(upright("EFT"))^()$ contains two propagators, it is useful to define a 2-body propagator. We can integrate over the energy components of the loop momentum, since the vertex does not have an energy dependence:#footnote[The 4-momentum conservation at each vertex means that the energy components of the two propagating momenta must carry along the energy component of the initial state $E_() = E_1 + E_2$. This can be encoded by demanding that $omega_1 + omega_2 = E_()$. Taking the #acr("com", form: "full") frame for the initial momenta means that the 3 momenta of each propagator must cancel i.e.~$upright(bold(k))_1 + upright(bold(k))_2 = 0$]

$ circle(dotless.i) Delta_2 \( upright(bold(k))_() \) = integral thin tilde(upright(d))^() omega thin frac(circle(dotless.i), omega - sqrt(upright(bold(k))_()^2 + m_1^2)) frac(circle(dotless.i), E_() - omega - sqrt(upright(bold(k))_()^2 + m_2^2)) = frac(circle(dotless.i), E_() - sqrt(upright(bold(k))_()^2 + m_1^2) - sqrt(upright(bold(k))_()^2 + m_2^2)) \, $

where the integral is performed using the residue theorem, closing the contour in either half plane, where in either case a pole is present. We have define $E_() = E_1 + E_2$ to be the #acr("com") energy of the two initial states:#footnote[which is equal to the outgoing energy]

$ E_i = sqrt(upright(bold(p))_()^2 + m_i^2) = sqrt(upright(bold(p'))_()^2 + m_i^2) \, $

where $upright(bold(p))_()$ and $upright(bold(p'))_()$ are the initial and final three-momenta of the two states #footnote[For example in the initial state one scalar field will have 3-momentum $upright(bold(p))_()$, and the other $- upright(bold(p))_()$] in the #acr("com") frame. Finally, we can write the diagram at loop level $L > 0$ encodes:

$ cal(A)_(upright("EFT"))^(L upright("loop")) = integral product_(i = 1)^L thin tilde(upright(d))^(D - 1) upright(bold(k))_i thin V \( upright(bold(p))_() \, upright(bold(k))_1 \) Delta_2 \( upright(bold(k))_1 \) dots.h.c Delta_2 \( upright(bold(k))_L \) V \( upright(bold(k))_L \, upright(bold(p'))_() \) . $

This integral can be performed in the non-relativistic limit, as done by @Bern:2019crd up to 3#acr("pm"). Up to 2#acr("pm"), the amplitudes of the #acr("eft") is:#footnote[Here the re-partioning mentioned above has been applied and a change in loop momenta: $upright(bold(k))_i arrow.r upright(bold(p))_() + upright(bold(ell))_i$.]

$ cal(A)_(upright("EFT"))^(\( 1 \)) & = - frac(4 pi G c_1, upright(bold(q))_()^2) \,\
cal(A)_(upright("EFT"))^(\( 2 \)) & = pi^2 G^2 \( - frac(2 c_2, \| upright(bold(q))_() \|) + frac(1, E_() xi \| upright(bold(q))_() \|) \[ \( 1 - 3 xi \) c_1^2 + 4 xi^2 E_()^2 c_1 c'_1 \]\
 & integral thin tilde(upright(d))^(D - 1) upright(bold(ell))_() thin frac(32 E_() xi c_1^2, upright(bold(ell))_()^2 \( upright(bold(q))_() + upright(bold(ell))_() \)^2 \( upright(bold(ell))_()^2 + 2 upright(bold(p))_() upright(bold(ell))_() \)) \) \, $

where $xi = frac(E_1 E_2, \( E_1 + E_2 \)^2)$ is the reduced energy ratio. The arguments of the coefficient functions $c_1$ are kept implicit and a prime denotes a derivative with respect to $upright(bold(p_()))_()$.

The key point is that the matching procedure requires the EFT amplitude for two-to-two scattering to be equal to the full amplitude at every order in the coupling constant $kappa$, i.e.~provided we obtain the amplitude of the full theory, and carefully apply the same limiting procedures, we impose that

$ cal(A)_(upright("EFT"))^(\( i \)) = cal(A)_(upright("full"))^(\( i \)) quad forall i . $

which fixes the coefficients in the potential ansatz #ref(<eq-ansatzpot>), and fulfills the promised map from amplitude to potential. Importantly, we must apply the limiting procedure applied above, i.e., the classical and non-relativistic limit, which is summarized by the following hierarchy of scales:

$ m_1 \, m_2 gt.double J \| upright(bold(q))_() \| gt.double \| upright(bold(q))_() \| . $

In the full theory this hierarchy is equivalent to restricting to a specific kinematic regime, following the method of regions. We consider all the possible loop-momentum scalings, first due to the classical limit:

#figure(
  table(
    columns: 2,
    align: (right,center,),
    table.header([Region], [Momentum $ell = \( omega \, upright(bold(ell))_() \)$],),
    table.hline(),
    [hard], [$\( m \, m \)$],
    [soft], [$\( \| upright(bold(q_()))_() \| \, \| upright(bold(q_()))_() \| \)$],
  )
  , kind: table
  )

In this language, the soft region is responsible for the classical limit, since we consider a small $\| upright(bold(q_()))_() \|$ expansion. We will in fact explore this expansion in a different light in #ref(<sec-kmoc>). Taking the #acr("nr", form: "full") limit corresponds to a subregion of the soft region, the so-called potential region:

$ \( omega \, upright(bold(ell))_() \) tilde.op \( \| upright(bold(u_()))_() \| \| upright(bold(q_()))_() \| \, \| upright(bold(q_()))_() \| \) \, $

where we use that the #acr("nr") expansion is a given by $ \| upright(bold(p_()))_() \| lt.double m $ and thus equivalently #footnote[dividing by mass] by a small relative velocity:

$ \| upright(bold(u_()))_() \| lt.double 1 . $

To summarize, in order to obtain the form of the potential, we first compute the amplitude in an #acr("eft"), absorbing all force carrying particles into an effective vertex. Making an ansatz for the potential we can compute the amplitude in the non-relativistic limit in terms of unknown coefficients. This same amplitude can be computed in the full theory, which, as a consequence of the limiting procedure, has simplified kinematic dependence. The coefficients of the #acr("eft") amplitude are then determined by matching it order by order with the full amplitude.

Unfortunately, the procedure described above, and in fact #emph[any] procedure trying to make contact with #acr("eob") by expanding the gravitational potential, intrinsically does not capture the full physics. The crucial point that makes compact binaries interesting is that they are not isolated, energy conserving systems. The energy of the system is lost to the gravitational waves that enable us to detect them. Any conservative dynamics, by construction, cannot capture this loss of energy. In the context of #acr("eob"), this radiation reaction was added after the fact, through direct modifications of the #acr("eom", form: "full")s obtained from Hamilton's equations. It is not clear how to incorporate dissipative data from the amplitude in the #acr("eob") framework.

One way to not encounter this difficulty is to fully bypass the #acr("eob") framework and try to obtain observables directly from the amplitude. This is the subject of the following sections.

= #acr("kmoc", form: "long") framework
<sec-kmoc>
The #acr("kmoc") framework (#cite(<Kosower:2018adc>, form: "prose")) is very general, and is aimed at taking the classical limit of a scattering event in an unspecified theory. We will apply it later on to #acr("sqed", form: "full") and gravity.

== Conventions
First let us define our conventions. Throughout this section we use relativistically natural units, i.e.~we do #emph[not] set $planck = 1$. This will essentially be the small parameter that multiplies the soft momenta that defined the region in #ref(<sec-amp2pot>). In this section we will further motivate this classical limit in more detail by taking the generally accepted limit that makes quantum physics collapse to classical physics

$ planck arrow.r 0 . $

We still retain $c = 1$, meaning that, using dimensional analysis we have that $\[ L \] \[ T \]^(- 1) = 1$ i.e.~$\[ L \] = \[ T \]$, length and time are measured in the same units. Correspondingly, energy is measured in units of mass $ E_() = m c^2 arrow.r.double.long \[ E_() \] = \[ m \] = \[ M \] \, $

and $planck$ has the following units

$ E_() = planck omega arrow.r.double.long \[ M \] = \[ planck \] \[ T \]^(- 1) arrow.r.double.long \[ planck \] = \[ T \] \[ M \] . $

Thus, momentum $p_()$ has units of $\[ p_() \] = \[ M \]$ mass and wavenumber $\[ macron(p_()) \] = \[ p_() / planck \] = \[ T \]^(- 1)$ has units of inverse time. We will denote the Lorentz-invariant phase space measure by $thin upright(d) Phi_() \( p \) thin$#footnote[Repeated integration will be denoted $thin upright(d) Phi_n \( p_1 \, dots.h \, p_n \) thin$]:

$ integral thin upright(d) Phi_() \( p \) thin dots.h = integral frac(thin upright(d)^3 upright(bold(p))_() thin, 2 planck omega_(upright(bold(p))_()) \( 2 pi \)^3) dots.h = integral thin tilde(upright(d))^4 p thin tilde(delta)^(\( + \)) \( p^2 - m^2 \) dots.h \, $

where quantities denoted by bars absorb the relevant factors of $2 pi$, such that $thin tilde(upright(d))^n p thin = frac(thin upright(d)^n p thin, \( 2 pi \)^n)$. Additionally, we have defined $planck omega_(upright(bold(p))_()) = sqrt(upright(bold(p))_()^2 + m^2)$ to be the on-shell energy and $delta^(\( + \))$ is the normalized positive energy on-shell delta function:

$ tilde(delta)^(\( + \)) \( p^2 - m^2 \) = \( 2 pi \) delta^() \( p_()^2 - m^2 \) Theta^() \( p zws^0 \) = tilde(delta)^() \( p_()^2 - m^2 \) Theta^() \( p zws^0 \) $

== Intital State
With our conventions at hand, let us set the stage for the problem. Imagine we want to scatter two particles, be they massive black holes, or tiny electrons, into each other, with a constant particle number (i.e.~a classical two in two out scattering). As mentioned in #ref(<sec-scatamp>), in #acr("qft") the framework that formalizes scattering of definite particle number states is based on the #acr("lsz") reduction formula.

we work in the Heisenberg picture here

Let us look at it in more detail. The first step is to define the states we want to scatter. Suppose our theory has single particle states $\| p chevron.r_(upright(""))$, with mass $m_()$, eigenstates of the momentum:

$ bb(P) zws^mu \| p chevron.r_(upright("")) = p_() zws^mu \| p chevron.r_(upright("")) quad upright("with") quad p^0 = planck omega_(upright(bold(p))_()) = sqrt(upright(bold(p_()))_()^2 + m_()^2) . $

These states can be seen as special cases (the plane wave states) of wavepacket states:#footnote[A plane wave state $\| f chevron.r_(upright("")) = \| p chevron.r_(upright(""))$would be given by$breve(f) \( k \) = 2 planck omega_(upright(bold(k))_()) tilde(delta)^(\( 3 \)) \( upright(bold(k))_() - upright(bold(p))_() \)$]

$ \| f chevron.r_(upright("")) = integral thin upright(d) Phi_() \( k \) thin breve(f) \( k \) \| k chevron.r_(upright("")) \, $

where $breve(f) \( k \)$ is the momentum space wave-function or, more mathematically, the momentum distribution function. Note that it is almost a Fourier transform, but not quite, as it is performed on the mass shell. If the spacetime 'wave-function' #footnote[Note that the concept of coordinate space wave-function is ill-defined in interacting theories. However, for such asymptotic states, the wave-function outside the bulk (on the infinite time boundary) is that of a free wave-function.] is given by

$ f \( x \) = integral thin upright(d) Phi_() \( k \) thin breve(f) \( k \) upright(e)^(- circle(dotless.i) k_() dot.op x_()) \, $ <eq-spacetimewf>

so that $breve(f) \( k \)$ is consequently given by

$ chevron.l k \| f chevron.r = breve(f) \( k \) = 2 planck omega_(upright(bold(p))_()) integral thin upright(d)^3 upright(bold(x))_() thin f \( x \) upright(e)^(circle(dotless.i) k dot.op x) . $ <eq-momdist>

If we now define the following operators #footnote[$f arrow.l.r(partial_mu) g = f \( partial_mu g \) - \( partial_mu f \) g$] ^\[ Note that if we replace $f \( x \)$ by a plane wave state $upright(e)^(- circle(dotless.i) k dot.op x)$ we obtain and define the following:

$ a_(upright(bold(k))_())^dagger \( t \) = integral thin upright(d)^3 upright(bold(x))_() thin upright(e)^(- circle(dotless.i) k dot.op x) \[ planck omega_(upright(bold(k))_()) f_() \( x \) - circle(dotless.i) partial_0 f_() \( x \) \] \, $

$ a_(upright(bold(k))_()) \( t \) = integral thin upright(d)^3 upright(bold(x))_() thin upright(e)^(circle(dotless.i) k dot.op x) \[ planck omega_(upright(bold(k))_()) f_() \( x \) + circle(dotless.i) partial_0 f_() \( x \) \] \, $

\]

$ a_f^dagger \( t \) = - circle(dotless.i) integral thin upright(d)^3 upright(bold(x))_() thin f \( x \) arrow.l.r(partial_0) phi.alt_() \( x \) \, $

$ a_f \( t \) = circle(dotless.i) integral thin upright(d)^3 upright(bold(x))_() thin f zws^(*) \( x \) arrow.l.r(partial_0) phi.alt_() \( x \) \, $

where $phi.alt_() \( x \)$ is the Heisenberg field operator of our theory. While these operators are time dependent, this dependence is not obtained from applying the Heisenberg #acr("eom", plural: true) #footnote[$frac(upright(d)^() A_H \( t \), upright(d) t^()) = circle(dotless.i) \[ H_H \, A_H \( t \) \]$], instead it is present through the time dependence of the wave-function $f \( x \)$. It turns out that these operators, suggestively written are the true creation and annihilation operators in the interacting theory.

We can now define a general one particle state $\| f chevron.r_(upright(""))$ as the result of a creation operator acting on the physical vacuum. Crucially, this only makes sense in the boundary of the bulk, i.e.~at asymptotic times $t arrow.r plus.minus oo$#footnote[See #cite(<Coleman:2018a>, form: "prose") or #cite(<Collins:2019ozc>, form: "prose") for a more in depth discussion of this point]. Inside the bulk, any thusly created state would in fact not have definite particle number. This definitely makes sense in the scattering problem because if you consider the whole system as a state, it only has definite particle number at asymptotic times, and inside the bulk the scattering happens, and the particle number is not conserved (at least quantum mechanically).

Consequently, we only define asymptotic states, denoting them by an $upright("in")$ subscript if they were created at $t arrow.r - oo$ and $upright("out")$ if they were created at $t arrow.r + oo$:

$ \| f chevron.r_(upright("in")) =^(upright("def")) lim_(t arrow.r - oo) a_f^dagger \( t \) \| Omega chevron.r_(upright("")) = a_(f ; upright("in"))^dagger \| Omega chevron.r_(upright("")) = integral thin upright(d) Phi_() \( k \) thin breve(f) \( k \) underbrace(a_(upright(bold(k))_())^dagger \| Omega chevron.r_(upright("")), \| k chevron.r_(upright(""))) $

and the corresponding $t arrow.r + oo$ state where in is replaced with out. It turns out that the extension to multiparticle states is not much more complicated. The one thing to demand is that the momentum distributions say $breve(f_1) \, breve(f_2) \, dots.h$ have no common support, i.e., they are not overlapping. In this case an n-particle in state is defined as:

$ \| f_1 \, dots.h \, f_n chevron.r_(upright("in")) =^(upright("def")) a_(f_1 ; upright("in"))^dagger a_(f_2 ; upright("in"))^dagger dots.h a_(f_n ; upright("in"))^dagger \| Omega chevron.r_(upright("")) = integral thin upright(d) Phi_n \( k_1 \, dots.h \, k_n \) thin breve(f_1) \( k_1 \) dots.h breve(f_n) \( k_n \) \| k_1 \, dots.h \, k_n chevron.r_(upright("")) . $

We now have the definitions for asymptotic in and out states for any number of particles. Before defining the setup to scatter two particles, let us look at the meaning of the position space wave-function $f \( x \)$ as defined in #ref(<eq-spacetimewf>). Consider a sharply peaked, compactly supported momentum distribution $breve(f) \( k \)$ around a value $upright(bold(p))_0$ and a characteristic width $Delta p$. One such function could be:

$ f \( upright(bold(p))_() ; upright(bold(p))_0 \, Delta p \) = cases(delim: "{", N upright(e)^(- 1 \/ \( 1 - \| upright(bold(p))_() - upright(bold(p))_0 \|^2 \/ Delta p^2 \)) & upright(" if ") \| upright(bold(p))_0 - upright(bold(p))_() \| < Delta p, 0 & upright(" if ") \| upright(bold(p))_0 - upright(bold(p))_() \| gt.eq Delta p) \, $ <eq-peak>

where $N$ is a normalization constant. The integrand in #ref(<eq-spacetimewf>), at large $t$ or $upright(bold(x))_()$, will be dominated by the stationary phase point $upright(bold(p))_s$ which is given by:#footnote[This then means that $upright(bold(p))_s = frac(m_() upright(bold(x))_() upright("sign") \( t \), sqrt(t^2 - upright(bold(x))_()^2))$ thus $planck omega_(upright(bold(p))_s) = frac(m_() \| t \|, sqrt(t^2 - upright(bold(x))_()^2))$]

$ 0 = - frac(partial_()^(), partial_() upright(bold(p))_s^()) \( planck omega_(upright(bold(p))_s) t + upright(bold(p))_s dot.op upright(bold(x))_() \) = - frac(upright(bold(p))_s t, planck omega_(upright(bold(p))_s)) + upright(bold(x))_() . $ <eq-stationaryphase>

In the case of a sharply peaked momentum distribution, the coordinate space wave-function will be largest when the stationary phase point is the same as the peak of the momentum distribution, i.e., $upright(bold(p))_s = upright(bold(p))_0$ i.e., substituting $upright(bold(p))_s$ into #ref(<eq-stationaryphase>) gives: $ upright(bold(x))_() tilde.eq frac(upright(bold(p))_0 t, planck omega_(upright(bold(p))_0)) = upright(bold(v))_0 t . $

This is precisely the trajectory of the classical relativistic particle. Now consider the case of two particles with different peaked momentum distributions their trajectories will have different velocities, but the same positions at time $0$. Thus, we will shift one of these trajectories by a so called impact parameter $b zws^mu$#footnote[$f \( x \) = integral thin upright(d) Phi_() \( p_() \) thin breve(f) \( p_() \) upright(e)^(- circle(dotless.i) / planck p_()^mu x_mu)$. Then a shifted, i.e.~translated version of $f \( x \)$ can be written:$f \( x - x_0 \) & = integral thin upright(d) Phi_() \( p_() \) thin breve(f) \( p_() \) thin upright(e)^(- circle(dotless.i) / planck p_mu \( x^mu - x_0^mu \))\
 & = integral thin upright(d) Phi_() \( p_() \) thin breve(f) \( p_() \) thin upright(e)^(circle(dotless.i) / planck p_mu x_0^mu) thin upright(e)^(- circle(dotless.i) / planck p_mu x^mu)$ Thus the associated, translated state is:$\| f chevron.r_(upright("")) = integral thin upright(d) Phi_() \( p_() \) thin breve(f) \( p_() \) thin upright(e)^(circle(dotless.i) / planck p_mu x_0^mu) thin \| p_() chevron.r_(upright(""))$], parametrizing the relative separation of the two particles/wave-packets. This can be simply done by multiplying the momentum distribution $breve(f_1) \( p \)$ by a factor of $upright(e)^(circle(dotless.i) / planck b dot.op p)$. We take it to be perpendicular to the initial momenta $p_1 \, p_2$. We now can write down the initial state that we are going to study:

$ \| upright("in") chevron.r_(upright("")) = integral thin upright(d) Phi_2 \( p_1 \, p_2 \) thin breve(f_1) \( p_1 \) breve(f_2) \( p_2 \) upright(e)^(circle(dotless.i) / planck b zws_mu p_1 zws^mu) \| p_1 \, p_2 chevron.r_(upright("in")) . $ <eq-instate>

From now on we will drop the breve and infer from the arguments the type of $f_()$ we are dealing with. Observe that by extracting the impact parameter in this way, the wave-functions can be identical in form, and will still be separated as required.

== Change in observable
The #acr("kmoc") framework concerns itself with the change of an observable quantity during a scattering event encoded in an operator $bb(O)$. For such an observable quantity $O$ , its change is obtained by evaluating the difference of the expectation value of $bb(O)$, between in and out states $ Delta O = chevron.l upright("out") \| bb(O) \| upright("out") chevron.r - chevron.l upright("in") \| bb(O) \| upright("in") chevron.r . $

In quantum mechanics, the out states are related to the in states by the time evolution operator, i.e., the S-matrix, $\| upright("out") chevron.r_(upright("")) = S \| upright("in") chevron.r_(upright(""))$. Thus:#footnote[In order, we use the unitarity of the S-matrix, then express the S-matrix as the identity (no actual interaction) and the transfer matrix $T$. The commutators are then expanded and the part with the identity vanish (as $bb(1)$ commutes with everything).]

$ Delta O & = chevron.l upright("in") \| S^dagger bb(O) S \| upright("in") chevron.r - chevron.l upright("in") \| bb(O) \| upright("in") chevron.r\
 & =^(S^dagger S = bb(1)) chevron.l upright("in") \| S^dagger \[ bb(O) \, S \] \| upright("in") chevron.r\
 & =^(S = bb(1) + circle(dotless.i) T) chevron.l upright("in") \| \[ bb(O) \, bb(1) + circle(dotless.i) T \] \| upright("in") chevron.r - chevron.l upright("in") \| circle(dotless.i) T^dagger \[ bb(O) \, bb(1) + circle(dotless.i) T \] \| upright("in") chevron.r\
 & = chevron.l upright("in") \| circle(dotless.i) \[ bb(O) \, T \] \| upright("in") chevron.r + chevron.l upright("in") \| T^dagger \[ bb(O) \, T \] \| upright("in") chevron.r\
 & = Delta O_(upright("v")) thin + Delta O_(upright("r")) . $ <eq-DeltaO>

If we put in the definition of our in state (#ref(<eq-instate>)), we have

$ Delta O = integral thin upright(d) Phi_4 \( p_1 \, p_2 \, p'_1 \, p'_2 \) thin f_1 \( p_1 \) f_2 \( p_2 \) f zws^(*)_1 \( p'_1 \) f zws^(*)_2 \( p'_2 \) thin upright(e)^(circle(dotless.i) b zws_mu frac(p_1 zws^mu - p'_1 zws^mu, planck)) \[ cal(I)_(upright("v")) \( O \) - cal(I)_(upright("r")) \( O \) \] \, $

where we defined the real integrand $cal(I)_(upright("r")) \( O \)$ and the virtual integrand $cal(I)_(upright("v")) \( O \)$ as the following matrix elements #footnote[NB: the notation is slightly different in the #cite(<Bern:2021xze>, form: "prose") paper]

$ cal(I)_(upright("v")) \( O \) & = zws_(upright("in")) chevron.l p'_1 p'_2 \| circle(dotless.i) \[ bb(O) \, T \] \| p_1 p_2 chevron.r_(upright("in"))\
cal(I)_(upright("r")) \( O \) & = zws_(upright("in")) chevron.l p'_1 p'_2 \| T^dagger \[ bb(O) \, T \] \| p_1 p_2 chevron.r_(upright("in")) . $

Let us first look at the virtual integrand $cal(I)_(upright("v")) \( O \)$:#footnote[Here we define $O_(upright("in")) \| p_1 p_2 chevron.r_(upright("")) = bb(O) \| p_1 p_2 chevron.r_(upright(""))$ aswell as, $O'_(upright("in")) zws_(upright("")) chevron.l p'_1 p'_2 \| = zws_(upright("")) chevron.l p'_1 p'_2 \| bb(O)$ and finally $Delta_(p'_() - p_()) O thin = O'_(upright("in")) - O_(upright("in"))$]

$ cal(I)_(upright("v")) \( O \) & = zws_(upright("in")) chevron.l p'_1 p'_2 \| circle(dotless.i) \[ bb(O) \, T \] \| p_1 p_2 chevron.r_(upright("in"))\
 & = zws_(upright("in")) chevron.l p'_1 p'_2 \| circle(dotless.i) bb(O) T \| p_1 p_2 chevron.r_(upright("in")) - zws_(upright("in")) chevron.l p'_1 p'_2 \| circle(dotless.i) T bb(O) \| p_1 p_2 chevron.r_(upright("in"))\
 & = circle(dotless.i) O_(upright("in")') #h(0em) zws_(upright("in")) chevron.l p'_1 p'_2 \| T \| p_1 p_2 chevron.r_(upright("in")) - circle(dotless.i) O_(upright("in")) #h(0em) zws_(upright("in")) chevron.l p'_1 p'_2 \| T \| p_1 p_2 chevron.r_(upright("in"))\
 & = circle(dotless.i) Delta_(p'_() - p_()) O thin thin zws_(upright("in")) chevron.l p'_1 p'_2 \| T \| p_1 p_2 chevron.r_(upright("in"))\
 & = circle(dotless.i) Delta_(p'_() - p_()) O thin thin tilde(delta)^4 \( p_1 + p_2 - p'_1 - p'_2 \) cal(A)^() \( p_1 \, p_2 arrow.r p'_1 \, p'_2 \) . $ <eq-vInt>

Note that the amplitude is from in states to in states. In order to obtain the real integrand $cal(I)_(upright("r")) \( O \)$, we insert a complete set of states :#footnote[$1 = sum_X integral thin upright(d) Phi_(2 + \| X \|) \( r_1 \, r_2 \, X \) thin \| r_1 r_2 X chevron.r chevron.l r_1 r_2 X \|$Where we could consider the states$r_1 \, r_2 \, X$to be the final states after the scattering. Note that we always impose having two #acr("bh", form: "full", plural: true), at all times, as we have no pair annihilation, which is why the sum always has a two particle dyad. The additional states encoded in$X$ are all possible additional messenger states (we also have no #acr("bh") pair production).]

$ cal(I)_(upright("r")) \( O \) & = zws_(upright("in")) chevron.l p'_1 p'_2 \| T^dagger \[ bb(O) \, T \] \| p_1 p_2 chevron.r_(upright("in"))\
 & = sum_X integral thin upright(d) Phi_(2 + \| X \|) \( r_1 \, r_2 \, X \) thin zws_(upright("in")) chevron.l p'_1 p'_2 \| T^dagger \| r_1 r_2 X chevron.r chevron.l r_1 r_2 X \| \[ bb(O) \, T \] \| p_1 p_2 chevron.r_(upright("in"))\
 & = sum_X integral thin upright(d) Phi_(2 + \| X \|) \( r_1 \, r_2 \, X \) thin tilde(delta)^4 \( p_1 + p_2 - r_1 - r_2 - r_X \) thin cal(A)^() \( p_1 \, p_2 arrow.r r_1 \, r_2 \, r_X \)\
 & #h(2em) Delta_(r X - p_()) O thin thin tilde(delta)^4 \( p'_1 + p'_2 - r_1 - r_2 - r_X \) thin cal(A zws^(*))^() \( p'_1 \, p'_2 arrow.r r_1 \, r_2 \, r_X \) \, $ <eq-rInt>

where the $X$ encodes any number of additional messenger states, and $r_X$ is the sum of their momenta. For both integrands we can preform some variable changes and eliminate certain Dirac delta functions. We introduce momentum shifts $q_i = p'_i - p_i$ and then integrate over $q_2$, and finally relabel $q_1 arrow.r q_()$ #footnote[Introducing the momentum shifts modifies the measure in the following way: $thin upright(d) Phi_() \( p'_i \) thin & = thin upright(d) Phi_() \( p_i + q_i \) thin\
= & thin tilde(upright(d))^4 q_i thin thin tilde(delta)^() \( \( p_i + q_i \)^2 - m_i^2 \) Theta^() \( p_i^0 + q_i^0 \)$ Now since we also have the on-shell enforcing delta function from $thin upright(d) Phi_() \( p_i \) thin$we can rewrite the delta functions:$ thin upright(d) Phi_() \( p_i \) thin & thin tilde(delta)^() \( \( p_i + q_i \)^2 - m_i^2 \)\
 & = thin upright(d) Phi_() \( p_i \) thin tilde(delta)^() \( underbrace(\( p_i^2 - m_i^2 \), upright("redundant")) + 2 p_i dot.op q_i + q_i^2 \)\
 & = thin upright(d) Phi_() \( p_i \) thin tilde(delta)^() \( 2 p_i dot.op q_i + q_i^2 \) $Finally we integrate$q_2$by solving$tilde(delta)^(\( 4 \)) \( p_1 + p_2 - p'_1 - p'_2 \) = tilde(delta)^(\( 4 \)) \( q_1 + q_2 \)$and thus we just set$q_2 = - q_1$]. Thus, we have

$ Delta O_(upright("v")) thin = integral & thin upright(d) Phi_2 \( p_1 \, p_2 \) thin thin tilde(upright(d))^4 q_() thin tilde(delta)^() \( 2 p_1 dot.op q_() + q_()^2 \) Theta^() \( p_1 zws^0 + q_()^0 \) thin tilde(delta)^() \( 2 p_2 dot.op q_() - q_()^2 \) Theta^() \( p_2 zws^0 - q_()^0 \)\
 & times f_1 \( p_1 \) f_2 \( p_2 \) f zws^(*)_1 \( p_1 + q_() \) f zws^(*)_2 \( p_2 - q_() \) thin upright(e)^(- circle(dotless.i) / planck b zws_mu q_()^mu)\
 & times circle(dotless.i) Delta_(q_()) O thin cal(A)^() \( p_1 \, p_2 arrow.r p_1 + q_() \, p_2 - q_() \) \, $ <eq-DeltaOv>

$ Delta O_(upright("r")) thin = sum_X integral & thin upright(d) Phi_(2 + \| X \|) \( r_1 \, r_2 \, X \) thin thin upright(d) Phi_2 \( p_1 \, p_2 \) thin thin tilde(upright(d))^4 q_() thin tilde(delta)^() \( 2 p_1 dot.op q_() + q_()^2 \) Theta^() \( p_1 zws^0 + q_()^0 \)\
 & times tilde(delta)^() \( 2 p_2 dot.op q_() - q_()^2 \) Theta^() \( p_2 zws^0 - q_()^0 \)\
 & times f_1 \( p_1 \) f_2 \( p_2 \) f zws^(*)_1 \( p_1 + q_() \) f zws^(*)_2 \( p_2 - q_() \) thin upright(e)^(- circle(dotless.i) / planck b_mu q_()^mu)\
 & times Delta_(r X - p_()) O thin tilde(delta)^(\( 4 \)) \( p_1 + p_2 - r_1 - r_2 - r_X \)\
 & times cal(A)^() \( p_1 \, p_2 arrow.r r_1 \, r_2 \, r_X \) cal(A zws^(*))^() \( p_1 + q_() \, p_2 - q_() arrow.r r_1 \, r_2 \, r_X \) . $ <eq-DeltaOr>

We have arrived at an integral expression for the change in observable $Delta O$. Luckily for us, we will not need to perform these integrals in the classical limit. We will just have carefully chosen replacement rules for the integrated variables! Let us look at this in more detail now.

== Classical limit
Since we are concerned with classical observables, we need to explore the classical limit of #ref(<eq-DeltaO>), i.e.~the limit of $planck arrow.r 0$. We first discuss the classical limit of wave-functions. We impose multiple conditions on the wave-functions. The first are those imposed by #acr("lsz") reduction. That is,

- Compact support momentum space wave-function
- Peaked around one value of momenta

Furthermore, the classical limit of the wave-functions should make sense, i.e.~

+ as $planck arrow.r 0$ the position and momentum wave-function should approach Dirac delta functions, centered around their classical values.
+ The overlap between the wave-function and its conjugate should be nearly full, since they represent the same particle classically.

Consider for example a non-relativistic wave-function for a particle of mass $m_()$:

$ f \( upright(bold(p_()))_() \) = exp \( - frac(\| upright(bold(p_()))_() \|, 2 planck m ell_c \/ ell_omega^2) \) =^(planck = ell_c m) exp \( - frac(\| upright(bold(p_()))_() \|, 2 m^2 ell_c^2 \/ ell_omega^2) \) \, $

where $ell_c = planck / m$ is the compton wavelength of the particle and $ell_omega$ is a characteristic width. This wave-function, with the proper normalization, grows sharper in the $planck arrow.r 0$ limit. If we now take the Fourier transform of $f \( upright(bold(p_()))_() \)$ to obtain the position "probability density", we have:#footnote[$A$absorbs the various constants, with$A = sqrt(2) m ell_c / ell_omega$and$upright(bold(x))_0$] $ cal(F)_(upright(bold(p_()))_())^(- 1) [f] \( upright(bold(x))_() \) & = integral frac(thin upright(d)^() upright(bold(p_()))_() thin, 2 pi) exp \( - \( upright(bold(p_()))_() / A \)^2 \) exp \( - circle(dotless.i) / planck upright(bold(p_()))_() dot.op upright(bold(x))_() \)\
 & = frac(1, 2 pi) underbrace(integral thin upright(d)^() upright(bold(p_()))_() thin exp \( - \( upright(bold(p_()))_() / A - frac(circle(dotless.i) upright(bold(x))_() A, 2 planck) \)^2 \), sqrt(pi) A) exp \( - frac(upright(bold(x))_()^2 A^2, 4 planck^2) \)\
 & = frac(sqrt(2) A, 2 pi) exp \( - frac(upright(bold(x))_()^2, 2 ell_omega^2) \) . $

This elucidates more clearly the meaning of characteristic width, as $ell_omega$ is the standard deviation of the wave-function in position space. Thus, the position-space wave-function grows sharper in the $ell_omega^2 arrow.r 0$ limit. For both wave-functions to simultaneously grow sharper in the classical limit, we must then have that $xi = \( ell_c / ell_omega \)^2 arrow.r 0$ remembering that the $planck arrow.r 0$ limit is just given by the $ell_c arrow.r 0$ one. Finally the meaning of classical limit in this context is the $xi arrow.r 0$ limit.

Going back to the general conditions, we want a wave-function $f_i \( p_i \)$ such that in the classical limit the momentum reaches its classical value: $breve(p_i) = m_i breve(u_i)$, with $breve(u_i)$ the classical four-velocity of particle $i$, normalized to $breve(u_i)^2 = 1$. In other words,

$ chevron.l p_i zws^mu chevron.r = integral thin upright(d) Phi_() \( p_i \) thin p_i zws^mu \| f_i \( p_i \) \|^2 =^(!) m_i breve(u)_i^mu \( 1 + cal(O) \( xi^(beta') \) \) \, $

where $beta'$ encodes the speed at which the classical value is reached in the $xi arrow.r 0$ limit. The velocity normalization convergence is controlled by $beta''$ $ breve(u)_i dot.op u_i = 1 + cal(O) \( xi^(beta'') \) \, $

Finally wave-function's spread is controlled by $beta$, and must converge to 0: $ sigma^2 \( p_i \) \/ m_i^2 & = 1 / m_i^2 chevron.l \( p_i - chevron.l p_i chevron.r \)^2 chevron.r\
 & = 1 / m_i^2 \( chevron.l p_i^2 chevron.r - chevron.l p_i chevron.r^2 \)\
 & = 1 / m_i^2 \( m_i^2 - \( m_i breve(u_i) \( 1 + cal(O) \( xi^(beta') \) \) \)^2 \)\
 & prop xi^beta \, $

where $chevron.l p_i^2 chevron.r = m_i^2$ is enforced by the measure $thin upright(d) Phi_() \( p_() \) thin$.

Additionally, the wave-function should be Lorentz invariant, and naively we would have that $f_() \( p_i^mu \) = f'_() \( p_i^2 \)$. However the integration measure enforces an on-shell condition: $m_i^2 = p_i^2$. Thus the wave-function cannot depend on $p_i^2$, and we need to introduce at least one additional four vector parameter $u$. The simplest dimensionless combination of parameters it then $frac(p_() dot.op u, m)$. Of course the wave-function must also depend on $xi$ and the simplest form of argument will thus be $frac(p_() dot.op u, m xi)$ so that any $p_()$ not aligned with $u$ will be strongly suppressed in the $xi arrow.r 0$ limit.

We now have control over most of the conditions:

- The classical limit is well-defined
- The wave-function spread is controlled
- The arguments of the wave-function are clear

We can write a general wave-function that satisfies the above as:

$ f \( frac(p_() dot.op u, m) \| breve(u_i) ; m_i ; beta^(\( i \)) \) . $

This function can take the form of a Gaussian, or something similar to #ref(<eq-peak>). Now there is one final requirement, that concerns the overlap of $f_()$ and $f zws^(*)_()$ must be $cal(O) \( 1 \)$, equivalently and more precisely:

$ f zws^(*)_() \( p_() + q_() \) tilde.op f zws^(*)_() \( p_() \) arrow.r.double.long f zws^(*)_() \( p_() + q_() \) - f zws^(*)_() \( p_() \) lt.double 1 arrow.r.double.long q_() zws^mu frac(partial_()^(), partial_() p zws^mu^()) f zws^(*)_() \( p_() \) lt.double 1 . $ Making explicit the $frac(p_() dot.op u, m xi)$ dependence: $f_() \( p_() \) = phi \( frac(p_() dot.op u, m xi) \)$ for $phi \( x \)$ a scalar function. $ arrow.r.double.long frac(q_() zws^mu u_mu, m xi) frac(upright(d)^() phi^(*) \( x \), upright(d) x^()) \|_(frac(p_() dot.op u, m xi)) lt.double 1 . $

Thus we require that for a characteristic value of $q_() = q_() zws_0$ we have:

$ frac(q_() zws_0 dot.op u, m xi) = macron(q)_() zws_0 dot.op u ell_omega^2 / ell_c lt.double 1 arrow.l.r.double macron(q)_() zws_0 dot.op u thin ell_omega lt.double sqrt(xi) \, $

having we denoted by a bar any quantity that has been rescaled by $planck$. Thus, a momentum $p_()$, when divided by $planck$ will be written $macron(p_())$ and called wave-number. We will combine this inequality with ones we obtain from the specific cases of integrations required above.

We now want to examine the classical limit of the integrands of the form #ref(<eq-DeltaOv>). If we consider just the integration over the initial momenta $p_i$ and the initial wave-functions with $tilde(delta)^() \( 2 p_i dot.op q_() + q_()^2 \)$, the delta function will smear out to a sharply peaked function whose scale is of the same order as the original wave-functions. As $xi$ gets smaller, this function will turn back into a Dirac delta function imposed on the $q_()$ integration. Let us examine this statement more closely. We are interested in the classical limit of the integrals such as:

$ d \( m \, xi \, u \, q_() \) = integral thin upright(d) Phi_() \( p_() \) thin tilde(delta)^() \( 2 p_() dot.op q_() + q_()^2 \) Theta^() \( p_()^0 + q_()^0 \) phi \( frac(p_() dot.op u, m xi) \) phi^(*) \( frac(\( p_() + q_() \) dot.op u, m xi) \) . $ <eq-dfunct>

This integral must be Lorentz invariant and depends on $m \, xi \, u \, q_()$ thus it must manifestly only depend on the following Lorentz invariants: $u^2 \, q_()^2 \, u dot.op q_() \, xi$. One of these is not actually a variable as we will normalise $u^2 = 1$. The rest are not fully dimensionless, but we can render them dimensionless:

$ \[ q_()^2 \] & = \[ planck macron(q)_() \]^2 = \[ M \]^2 arrow.r.double.long \[ ell_c sqrt(- macron(q)_()^2) \] = \[ planck / m sqrt(- macron(q)_()^2) \] = frac(\[ M \], \[ M \]) = 1 \,\
\[ u dot.op q_() \] & = \[ M \] arrow.r.double.long \[ frac(u dot.op macron(q)_(), sqrt(- macron(q)_()^2)) \] = \[ frac(u dot.op q_(), sqrt(- q_()^2)) \] = frac(\[ M \], \[ M \]) = 1 \,\
\[ xi \] & = 1 . $

If we call $1 / sqrt(- macron(q)_()^2) = ell_s$ a scattering length#footnote[$\[ 1 / sqrt(- macron(q)_()^2) \] = \[ T \] = \[ L \] = \[ ell_s \]$] then our dimensionless ratios become :

$ ell_c / ell_s quad upright("and") quad ell_s thin macron(q)_() dot.op u . $

The Dirac delta function can then be rewritten as: $ tilde(delta)^() \( 2 p_() dot.op q_() + q_()^2 \) = tilde(delta)^() \( 2 planck m thin u dot.op macron(q)_() + planck^2 macron(q)_()^2 \) = frac(1, planck m) tilde(delta)^() \( 2 macron(q)_() dot.op u - ell_c / ell_s^2 \) = frac(ell_s, planck m) tilde(delta)^() \( 2 ell_s thin macron(q)_() dot.op u - ell_c / ell_s \) . $

Performing the integration over $p_()$ in #ref(<eq-dfunct>) we obtain symbolically:

$ d \( m \, xi \, u \, q_() \) = upright("peaked function imposing that ") 2 ell_s thin macron(q)_() dot.op u = ell_c / ell_s upright(" with width ") xi^beta . $

#figure(timg("fig-gaussian-output-1.svg"),
  caption: [
    Sharpening gaussian
  ]
)
<fig-gaussian>

Let us disucss the wave-function and the scales from a physical perspective. The characteristic width $ell_omega$ is the particle's position uncertainty, $planck / ell_omega$ is the associated momentum uncertainty. In the classical limit the position uncertainty is neglible with respect to minimum distance between the particles $ell_s$:

$ ell_omega lt.double ell_s \, $

and the momentum uncertainty is neglible with respect to the masses of the particles:

$ planck / ell_omega lt.double m arrow.r.double.long ell_c lt.double ell_omega . $

Putting these together we obtain the goldilocks inequality:

$ ell_c lt.double ell_omega lt.double ell_s . $

Looking back at the arguments of $d$ we see that

$ ell_s thin macron(q)_() dot.op u gt.double ell_omega macron(q)_() dot.op u tilde.op sqrt(xi) = ell_c / ell_omega gt.double ell_c / ell_s . $

Thus in the classical limit we have that $d$ collapses to:

$ d \( m \, xi \, u \, q_() \) prop tilde(delta)^() \( macron(q)_() dot.op u \) . $

Thus, the wave-function-weighted on-shell phase-space integration disappears in the classical limit. The resulting condition is that the integration momenta take on their physical values. The sequence that we have gone through should be done for all the integrands of type $d$. We will not do this explicitly every time but instead apply the following rules:

+ Just as for the massless transfer momentum any messenger momentum, be it transfer, virtual-loop or real emmission, shall become a wave-number: $k arrow.r planck macron(k)$.
+ Replace all couplings with their dimensionless counterparts: $kappa arrow.r kappa / sqrt(planck)$ (this is only precisely true for #acr("sqed") and gravity, which are the applications we are interested in).
+ Eliminate all on-shell integrations by approximating $f_() \( p_() + planck macron(q)_() \)$ by $f_() \( p_() \)$.
+ Laurent expand all the integrands in $planck$.
+ Make the integration momenta take on their physical values: $p_i arrow.r m_i breve(u_i)$.

To make this idea explicit we introduce the following notation, meaning that the steps above have been applied

$ chevron.l #h(-1em) chevron.l g \( p_1 \, p_2 \, dots.h \) chevron.r #h(-1em) chevron.r =^(upright("def")) integral thin upright(d) Phi_() \( p_1 \) thin thin upright(d) Phi_() \( p_2 \) thin \| f_1 \( p_1 \) \|^2 \| f_2 \( p_2 \) \|^2 thin g \( p_1 \, p_2 \, dots.h \) $

We can now rewrite #ref(<eq-DeltaO>)

$ Delta O thin = chevron.l #h(-1em) chevron.l integral overbracket(thin tilde(upright(d))^4 q_() thin tilde(delta)^() \( 2 p_1 dot.op q_() + q_()^2 \) Theta^() \( p_1 zws^0 + q_()^0 \) tilde(delta)^() \( 2 p_2 dot.op q_() - q_()^2 \) Theta^() \( p_2 zws^0 + q_()^0 \), thin upright(d) Psi_() \( q_() \) thin) upright(e)^(- circle(dotless.i) / planck q_()^mu b_mu) \( cal(I')_(upright("v")) \( O \) + cal(I')_(upright("r")) \( O \) \) chevron.r #h(-1em) chevron.r \, $ <eq-DeltaOclas>

where $ cal(I')_(upright("v")) \( O \) & = circle(dotless.i) thin Delta_(q_()) O thin cal(A)^() \( p_1 \, p_2 arrow.r p_1 + q_() \, p_2 - q_() \)\
cal(I')_(upright("r")) \( O \) & = sum_X integral thin upright(d) Phi_(2 + \| X \|) \( r_1 \, r_2 \, X \) thin Delta_(r X - p_()) O thin tilde(delta)^(\( 4 \)) \( p_1 + p_2 - r_1 - r_2 - r_X \)\
 & times cal(A)^() \( p_1 \, p_2 arrow.r r_1 \, r_2 \, r_X \) cal(A zws^(*))^() \( p_1 + q_() \, p_2 - q_() arrow.r r_1 \, r_2 \, r_X \) . $

Additionally, we make clear the dependence on $planck$ since we want to eventually take the $planck arrow.r 0$ limit. We apply step 1. above, and change integration variables to $macron(q)_() = q_() / planck$ and absorb the $planck$ dependence into the redefinition of the integrands and the measure:

#svg-math[$ thin upright(d) Psi_() \( q_() \) thin & = planck^2 thin upright(d) macron(Psi)_() \( macron(q)_() \) thin = planck^(cancel(4)) thin tilde(upright(d))^4 macron(q)_() thin cancel(1 / planck) tilde(delta)^() \( 2 p_1 dot.op macron(q)_() + planck macron(q)_()^2 \) Theta^() \( p_1 zws^0 + q_()^0 \) cancel(1 / planck) tilde(delta)^() \( 2 p_1 dot.op macron(q)_() + planck macron(q)_()^2 \) Theta^() \( p_2 zws^0 + q_()^0 \) \, $]

$ macron(cal(I)'_(upright("v"))) \( O \) & = planck^2 cal(I')_(upright("v")) \( O \) \,\
macron(cal(I)'_(upright("r"))) \( O \) & = planck^2 cal(I')_(upright("r")) \( O \) . $

We can finally neatly write:

$ Delta O = chevron.l #h(-1em) chevron.l integral thin upright(d) macron(Psi)_() \( macron(q)_() \) thin upright(e)^(- circle(dotless.i) macron(q)_()^mu b_mu) \( macron(cal(I)'_(upright("v"))) \( O \) + macron(cal(I)'_(upright("r"))) \( O \) \) chevron.r #h(-1em) chevron.r . $

The $planck$ dependence is now entirely contained in the integrands (ignoring the $planck macron(q)_()^2$ factors in the delta function). The classical limit of this observable is then simply,

$ Delta O_(upright("classical")) = lim_(planck arrow.r 0) planck^(beta_(L O)) \[ integral thin upright(d) macron(Psi)_() \( macron(q)_() \) thin \( macron(cal(I)'_(upright("v"))) \( O \) + macron(cal(I)'_(upright("r"))) \( O \) \) \] \, $

dropping the angle brackets, since these dissappear in the classical limit. Here $beta_(L O)$ is the #acr("lo") $planck$-dependence of the observable. This is so that $Delta O_(upright("classical")) tilde.op planck^0$ i.e.~classical scaling.

= Impulse in #acr("kmoc", form: "long")
We can now explore the integrands for a specific observable. Consider the change in momentum, or impulse of particle 1. The #acr("kmoc") formalisms gives us a way to write this as:

$ Delta p_1 zws^mu = chevron.l #h(-1em) chevron.l integral thin upright(d) macron(Psi)_() \( macron(q)_() \) thin exp \( - circle(dotless.i) macron(q)_()^mu b_mu \) \( macron(cal(I)'_(upright("v"))) \( p_1 zws^mu \) + macron(cal(I)'_(upright("r"))) \( p_1 zws^mu \) \) chevron.r #h(-1em) chevron.r . $

We then have:

$ macron(cal(I)'_(upright("v"))) \( p_1 zws^mu \) & = planck^2 circle(dotless.i) thin q_() thin cal(A)^() \( p_1 \, p_2 arrow.r p_1 + planck macron(q)_() \, p_2 - planck macron(q)_() \)\
macron(cal(I)'_(upright("r"))) \( p_1 zws^mu \) & = planck^2 integral sum thin upright(d) Phi_(2 + \| X \|) \( r_1 \, r_2 \, r_X \) thin \( r_1^mu - p_1^mu \) thin tilde(delta)^(\( 4 \)) \( p_1 + p_2 - r_1 - r_2 - r_X \)\
 & times cal(A)^() \( p_1 \, p_2 arrow.r r_1 \, r_2 \, r_X \) cal(A zws^(*))^() \( p_1 + planck macron(q)_() \, p_2 - planck macron(q)_() arrow.r r_1 \, r_2 \, r_X \) . $

We can extract $planck$ from $q_()$ and from the amplitude. In order to determine the $planck$ scaling of $cal(A)^()$ we extract each coupling constant $kappa$ along with an $1 / sqrt(planck)$, so that quartic vertices yield a factor of $kappa^2 / planck$ whereas cubic ones yield $kappa / sqrt(planck)$#footnote[as mentioned in the last section, this is true for gravity and #acr("sqed") and we will extend this fact to schematically rescale the vertex coupling by $planck^(-) frac(d - 2, 2)$, for $d$ the degree of the vertex in question.]. If we count the number $V_3$ of all cubic vertices, $V_4$ the number of quartic vertices, and so on, we have that the number of internal lines is $I = 1 / 2 \( sum_(d = 3) d V_d - E \)$. This is because we have $sum_(d = 3) d V_d$ lines to start with, out of which $E$ are chosen to be external. The remaining $\( sum_(d = 3) d V_d - E \)$ ones are contracted in pairs among themselves to form $I$ internal lines, yielding the factor of $1 / 2$. In our case we have $E = 4 + M$ where $M = \| X \|$ is the number of messenger particles. Using the argument from loop counting we have that the number of loops of our graph $L$ is given by: $ L = I - V + N = & 1 / 2 \( sum_(d = 3) d dot.op V_d - 4 - M \) - sum_(d = 3) V_d + 1\
= & 1 / 2 \( sum_(d = 3) \( d - 2 \) V_d \) - 1 - M / 2 \, $

where $N$ is the number of connected components ($= 1$ in our case) . Thus, we see that the amount of extracted $planck$s corresponds directly to the number of loops plus one plus the number of additional messenger particles. #footnote[The number of extracted couplings being twice that.] We can thus write the amplitude $cal(A)^()$ as a sum over reduced $L$-loop amplitudes $cal(macron(A))^(\( L \))$:

$ cal(A)^() \( p_1 \, p_2 arrow.r r_1 \, r_2 \, X \) = sum_(L = 0)^oo \( kappa^2 / planck \)^(\( L + 1 + frac(\| X \|, 2) \)) cal(macron(A))^(\( L \)) \( p_1 \, p_2 arrow.r r_1 \, r_2 \, X \) . $

Going back to the integrands we have:

$ macron(cal(I)'_(upright("v"))) \( p_1 zws^mu \) & = planck^3 circle(dotless.i) thin macron(q)_() thin sum_(L = 0)^oo \( kappa^2 / planck \)^(\( L + 1 \)) cal(macron(A))^(\( L \)) \( p_1 \, p_2 arrow.r p_1 + planck macron(q)_() \, p_2 - planck macron(q)_() \)\
 & = circle(dotless.i) thin planck macron(q)_() thin sum_(L = 0)^oo kappa^(2 \( L + 1 \)) planck^(\( 1 - L \)) cal(macron(A))^(\( L \)) \( p_1 \, p_2 arrow.r p_1 + planck macron(q)_() \, p_2 - planck macron(q)_() \) \, $ <eq-impulseIv>

as well as the real kernel:#footnote[We changed the integration variable from $r_i$to$w_i = r_i - p_i$ thus the measure changes:$thin upright(d) Phi_(2 + \| X \|) \( r_1 \, r_2 \, X \) thin = thin upright(d) Phi_(\| X \|) \( r_X \) thin product_(i = 1 \, 2) thin tilde(upright(d))^4 w_i thin tilde(delta)^() \( 2 p_i dot.op w_i + w_i^2 \) Theta^() \( p_i^0 + w_i^0 \)$ where we used the same reasoning as for the $q_i$ variable change.]

$ macron(cal(I)'_(upright("r"))) \( p_1 zws^mu \) & = planck^2 integral sum thin upright(d) Phi_(\| X \|) \( r_X \) thin \[ product_(i = 1 \, 2) thin tilde(upright(d))^4 w_i thin tilde(delta)^() \( 2 p_i dot.op w_i + w_i^2 \) Theta^() \( p_i^0 + w_i^0 \) \]\
 & times w_1^mu thin tilde(delta)^(\( 4 \)) \( w_1 + w_2 + r_X \)\
 & times cal(A)^() \( p_1 \, p_2 arrow.r p_1 + w_1 \, p_2 + w_2 \, r_X \) cal(A zws^(*))^() \( p_1 + planck macron(q)_() \, p_2 - planck macron(q)_() arrow.r p_1 + w_1 \, p_2 + w_2 \, r_X \)\
 $

$ = planck^2 integral sum & thin upright(d) Phi_(\| X \|) \( r_X \) thin \[ product_(i = 1 \, 2) planck^3 thin tilde(upright(d))^4 macron(w)_i thin tilde(delta)^() \( 2 p_i dot.op macron(w)_i + planck macron(w)_i^2 \) Theta^() \( p_i^0 + planck macron(w)_i^0 \) \]\
 & times planck macron(w)_1^mu thin planck^(- 4) tilde(delta)^(\( 4 \)) \( macron(w)_1 + macron(w)_2 + macron(r)_X \)\
 & times sum_(L = 0)^oo sum_(L' = 0)^oo \( kappa^2 / planck \)^(\( L + L' + 2 + \| X \| \)) cal(macron(A))^(\( L \)) \( p_1 \, p_2 arrow.r p_1 + planck macron(w)_1 \, p_2 + planck macron(w)_2 \, r_X \)\
 & times cal(macron(A) zws^(*))^(\( L' \)) \( p_1 + planck macron(q)_() \, p_2 - planck macron(q)_() arrow.r p_1 + planck macron(w)_1 \, p_2 + planck macron(w)_2 \, r_X \) $

$ = integral sum & thin upright(d) Phi_(\| X \|) \( r_X \) thin \[ product_(i = 1 \, 2) thin tilde(upright(d))^4 macron(w)_i thin tilde(delta)^() \( 2 p_i dot.op macron(w)_i + planck macron(w)_i^2 \) Theta^() \( p_i^0 + planck macron(w)_i^0 \) \]\
 & times planck macron(w)_1^mu thin tilde(delta)^(\( 4 \)) \( macron(w)_1 + macron(w)_2 + macron(r)_X \)\
 & times sum_(L = 0)^oo sum_(L' = 0)^oo kappa^(2 \( L + L' + 2 + \| X \| \)) planck^(2 - L - L' - \| X \|) cal(macron(A))^(\( L \)) \( p_1 \, p_2 arrow.r p_1 + planck macron(w)_1 \, p_2 + planck macron(w)_2 \, r_X \)\
 & times cal(macron(A) zws^(*))^(\( L' \)) \( p_1 + planck macron(q)_() \, p_2 - planck macron(q)_() arrow.r p_1 + planck macron(w)_1 \, p_2 + planck macron(w)_2 \, r_X \) .\
 $ <eq-impulseIr>

Schematically we have

$ macron(cal(I)'_(upright("v"))) \( p_1 zws^mu \) & = sum_(L = 0)^oo cal(O) \( kappa^(2 \( L + 1 \)) \) \,\
macron(cal(I)'_(upright("r"))) \( p_1 zws^mu \) & = sum_(L = 0)^oo sum_(L' = 0)^oo cal(O) \( kappa^(2 \( L + L' + 2 \) + 2 \| X \|) \) $

The contributions from the virtual kernel are lower order in the coupling $kappa$ for a given loop order. Both kernels contribute together provided that the following equation is verified:

$ L - 1 = tilde(L) + tilde(L)' + \| X \| . $ <eq-rvloopmatch>

where $L$ is the loop count for the virtual kernel, and $tilde(L)$,$tilde(L)'$ and $\| X \|$ are the real kernel loop count and messenger particle count respectively. Note that for a tree level virtual kernel, the real-kernel match does not exist. The real kernel is only present for $L > 0$. When taking the classical limit we will only retain contributions from graphs that cancel the $planck$ divergences in each corresponding kernel. Thus, at the $L$-loop level, the amplitude in the virtual kernel must cancel with terms of order

$ planck^(1 - L + O) \, $ <eq-hbarvirt>

where the $O$ term is the order of $planck$ that is present as a result of the observable. In the case of particle 1's momentum, $O = 1$. Similarly, the amplitudes in the real kernel must cancel with:

$ planck^(2 - tilde(L) + tilde(L)' - \| X \| + O) . $ <eq-hbarreal>

Now we see that the #acr("lo") contribution #footnote[Here the expansion is in powers of the coupling constant, so even though we want $planck$s to cancel, the loop order will still affect the order of the contribution through the coupling constant $kappa$and the #acr("lo") corresponds to$kappa$]to the impulse, which we denote $Delta p_1^(mu \, \( 0 \))$ can only be from the virtual kernel at tree level. Thus, we have the following equation,

$ Delta p_1^(mu \, \( 0 \)) = chevron.l #h(-1em) chevron.l integral thin upright(d) macron(Psi)_() \( macron(q)_() \) thin exp \( - circle(dotless.i) macron(q)_()^mu b_mu \) med macron(cal(I)'_(upright("v"))) \( p_1 zws^mu \)^(\( L = 0 \)) chevron.r #h(-1em) chevron.r . $ <eq-impulseLO>

And the integrand is given by the tree level 4 point amplitude.

$ macron(cal(I)'_(upright("v"))) \( p_1 zws^mu \)^(L = 0) = circle(dotless.i) thin macron(q)_()^mu thin kappa^2 planck^2 macron(cal(A))^(\( 0 \)) \( p_1 \, p_2 arrow.r p_1 + planck macron(q)_() \, p_2 - planck macron(q)_() \) . $

At #acr("nlo", form: "full"), i.e.~$kappa^4$ order, both integrands contribute, as #ref(<eq-rvloopmatch>) can be satisfied for $L = 1$, $L' = 0$ and $\| X \| = 2$. Thus we have the following equation:

$ Delta p_1^(mu \, \( 1 \)) = chevron.l #h(-1em) chevron.l integral thin upright(d) macron(Psi)_() \( macron(q)_() \) thin exp \( - circle(dotless.i) macron(q)_()^mu b_mu \) \( macron(cal(I)'_(upright("v"))) \( p_1 zws^mu \)^(\( L = 1 \)) + macron(cal(I)'_(upright("r"))) \( p_1 zws^mu \)^(\( L = 0 \, L' = 0 \)) \) chevron.r #h(-1em) chevron.r . $ <eq-impulseNLO>

The virtual integrand is now given by the 1-loop level amplitude, and the real integrand is given by the square of a the tree level amplitude. This process can go on indefinitely, and is independent of the type of observable and the theory. Here we considered the change of momentum a particle, which for a black hole very far away would be very difficult to measure. However, we can also consider an observable such as the four-momentum of the radiated particles, or more precisely its expectation value. Of course, the operator corresponding to this observable gives zero when acting on the initial momentum states, and only gives a non-zero result when acting on the messenger states. Thus, for this observable only the real integrand, starting with $\| X \| = 1$ will contribute, the #acr("lo") contribution being given by what is essentially the unitarity cut of a two loop amplitude. We see that regardless of observable, the objects that are needed are the amplitudes.

For each loop level, many diagrams can contribute, but the classical limit enforces that they must cancel the $planck$ orders given by #ref(<eq-hbarreal>) and #ref(<eq-hbarvirt>). The cancellation order is dependent on the considered observable and filters the contributing diagrams. It can also be reformulated in the language of the method of regions.

To see the whole machinery in action, let us take #acr("sqed") as an example theory, that shows the relevant subtleties of the formalism.

= #acr("sqed", form: "long") amplitudes
We want to couple a set of massive scalar fields to electromagnetism. We will use the minimal coupling prescription to ensure that the resulting Lagrangian exhibits the required gauge symmetry. The minimal coupling prescription works provided that our free mass Lagrangian admits a conserved current. Our free mass Lagrangian for two complex scalar fields with different masses is:

$ cal(L)_m = sum_(i = 1)^2 partial_mu phi.alt_i^dagger thin partial^mu phi.alt_i - m_i^2 phi.alt_i^dagger phi.alt_i . $

Notice that under the following transformation:

$ phi.alt_i \( x \) & arrow.r upright(e)^(- circle(dotless.i) Q_i lambda) phi.alt_i \( x \) \,\
phi.alt_i^dagger \( x \) & arrow.r upright(e)^(circle(dotless.i) Q_i lambda) phi.alt_i^dagger \( x \) \,\
 $

or infinitesimally:

$ delta phi.alt_i & = - circle(dotless.i) phi.alt_i Q_i delta lambda \,\
delta phi.alt_i^dagger & = circle(dotless.i) phi.alt_i^dagger Q_i delta lambda \,\
 $

the above Lagrangian is unchanged. We will identitfy $Q_i$ with the charge, in units of $e$, of each particle. If we upgrade the parameter $lambda$ to a spacetime function $lambda \( x \)$, the Lagrangian is not invariant anymore and invariance is restored if we replace all the derivatives $partial_mu$ with the gauge-covariant derivatives $D_mu$:

$ D_mu = partial_mu + circle(dotless.i) thin e thin Q_i thin A_mu \, $

i.e., if along with the transformation above, we perform a gauge transformation of the photon field:

$ A_mu arrow.r A_mu + 1 / e partial_mu lambda $

or infinitesimally

$ delta A_mu = 1 / e partial_mu delta lambda \, $

then the whole Lagrangian:

$ cal(L)_(E D) + cal(L)_m \( phi.alt_i \, partial_mu phi.alt_i \) arrow.r cal(L)_(E D) + cal(L)_m \( phi.alt_i \, D_mu phi.alt_i \) \, $

is invariant under the above defined gauge transformation. The final Lagrangian is:

$ cal(L) = - 1 / 4 F_(mu nu) F^(mu nu) + sum_(i = 1)^2 [(D_mu phi.alt_i)^dagger (D^mu phi.alt_i) - m_i^2 phi.alt_i^dagger phi.alt_i] \, $

with $F_(mu nu) equiv partial_mu A_nu - partial_nu A_mu$. Expanding and then integrating by parts:

$ cal(L) & = - 1 / 4 (partial_mu A_nu - partial_nu A_mu) (partial^mu A^nu - partial^nu A^mu) + sum_(i = 1)^2 [(partial_mu - circle(dotless.i) thin e thin Q_i thin A_mu) phi.alt_i^dagger (partial_mu + circle(dotless.i) thin e thin Q_i thin A_mu) phi.alt_i - m_i^2 phi.alt_i^dagger phi.alt_i]\
 & = underbrace(1 / 2 A_mu [eta^(mu nu) partial^2 - partial^mu partial^nu] A_nu + sum_(i = 1)^2 - phi.alt_i^dagger (partial^2 + m_i^2) phi.alt_i, cal(L)_0) + underbrace(sum_(i = 1)^2 q_i^2 thin e^2 A_mu A^mu thin phi.alt_i^dagger phi.alt_i - circle(dotless.i) thin e thin Q_i thin A_mu (phi.alt_i^dagger partial^mu phi.alt_i - (partial^mu phi.alt_i^dagger) phi.alt_i), cal(L)') . $

Since we have a massless photon, and still have gauge freedom we have to implement gauge fixing in the usual way:

$ cal(L)_(upright("eff")) & = cal(L) + overbracket(frac(- 1, 2 xi) \( partial_mu A^mu \)^2, cal(L_(upright("GF"))))\
 & = 1 / 2 A_mu underbrace(\[ g^(mu nu) partial^2 - \( 1 - 1 / xi \) partial^mu partial^nu \], arrow.r tilde(D)_xi^(mu nu) \( k \) = frac(- circle(dotless.i), k^2 + circle(dotless.i) epsilon) [g_(mu nu) - \( 1 - xi \) frac(k_mu k_nu, k^2)]) A_nu + sum_(i = 1)^2 - phi.alt_i^dagger underbrace(\( partial^2 + m_i^2 \), tilde(Delta)_F \( q^2 \) = frac(circle(dotless.i), p^2 - m^2 + circle(dotless.i) epsilon)) phi.alt_i\
 & + sum_(i = 1)^2 underbrace(Q_i^2 thin e^2 thin eta^(mu nu), times 2 circle(dotless.i) arrow.r upright(4 - v e r t e x)) A_mu A_nu thin phi.alt_i^dagger phi.alt_i underbrace(- circle(dotless.i) thin e thin Q_i thin A_mu (phi.alt_i^dagger partial^mu phi.alt_i - (partial^mu phi.alt_i^dagger) phi.alt_i), times circle(dotless.i) arrow.r upright(3 - v e r t e x)) . $

In the last lines we identify the terms contributing to the Feynman rules. They are given in #ref(<tbl-sqedfrules>)

#figure(
  table(
    columns: (37.5%, 20.83%, 40.83%),
    align: (left,left,left,),
    table.header([For every], [], [Write],),
    table.hline(),
    [#box(timg("photonprop.svg"))

    ], [internal photon line], [$tilde(D)_xi^(mu nu) \( ell \) = frac(- circle(dotless.i), ell^2 + circle(dotless.i) epsilon) [eta_(mu nu) - \( 1 - xi \) frac(ell_mu ell_nu, e l l^2)]$],
    [#box(timg("scalarprop.svg"))

    ], [internal scalar], [$tilde(Delta)_F \( k^2 \) = frac(circle(dotless.i), k^2 - m^2 + circle(dotless.i) epsilon)$],
    [#box(timg("seagull.svg"))

    ], [$phi.alt_i phi.alt_i^dagger A_mu A_nu$ vertex], [$2 circle(dotless.i) Q_i^2 thin e^2 thin eta^(mu nu)$],
    [#box(timg("cubic.svg"))

    ], [$phi.alt_i \( k_i \) phi.alt_i^dagger \( k'_i \) A_mu$ vertex], [$circle(dotless.i) e thin Q_i thin \( k_i^mu - k_i^(' mu) \)$],
    [#box(timg("extscalar.svg"))

    ], [External scalar], [$times 1$],
    [#box(timg("extphoton.svg"))

    ], [$mat(delim: "{", upright(" incoming "); upright(" outgoing "))$ photon], [$times mat(delim: "{", epsilon_mu; epsilon_mu^(*'))$, with $epsilon dot.op k = 0 \, epsilon' dot.op k' = 0$],
  )
  , caption: [Feynman rules for #acr("sqed")]
  , kind: table
  )
<tbl-sqedfrules>

where we consider only incoming momenta and the arrows denote incoming or outgoing particles. For the photon, we will take the Feynamn gauge, setting $xi = 1$ and thus $tilde(D)_1^(mu nu) \( ell \) = tilde(D)^(mu nu) \( ell \) = frac(- circle(dotless.i) eta^(mu nu), ell^2 + circle(dotless.i) epsilon)$.

== Expansions and simplifications
Notice that if we rescale all photon momenta (taking them to be the loop momenta) by $planck$ or equivalently take them to be in the soft region: $\| k \| tilde.op \| q \| lt.double \| p \|$, where $p$ is the external momenta, then the photon propagator scales homogeneously in $planck$, typically:

$ frac(1, \( ell - q_() \)^2) = 1 / planck^2 frac(1, \( macron(ell) - macron(q)_() \)^2) \, $ <eq-photonscale>

thus contributes $cal(O) \( planck^(- 2) \)$ to the overall diagram. The matter propagator on the other hand, has inhomogeneous $planck$ scaling, as we do not rescale the external momenta, (or equivalently the external momenta are not restricted by the regions). Note that we will not consider internal mass loops as the soft limit means that massive pair production is forbidden, thus massive propagators necessarily route an external momentum. We can nonetheless expand a generic massive propagator in the soft limit:

#svg-math[$ frac(1, \( ell - p_i \)^2 - m_i^2) & = frac(1, ell^2 - 2 ell dot.op p_i + cancel(p_i^2) - cancel(m_i^2)) = frac(1, planck^2 macron(ell)^2 - 2 planck macron(ell) dot.op p_i)\
 & = - 1 / planck frac(1, 2 macron(ell) dot.op p_i) \( 1 + planck frac(macron(ell)^2, 2 macron(ell) dot.op p_i) + planck^2 frac(macron(ell)^4, \( 2 macron(ell) dot.op p_i \)^2) + dots.h \) .\
 $ <eq-massiveScale>]

In other contexts one may say that the matter propagator has eikonalized (it is now linear in $ell$). Before we compute the amplitudes let us set up some useful kinematic identities and variables. If we consider the two-to-two particle scattering, taking an all outgoing momentum convention we have the following masses:

$ m_1^2 = p_4^2 = p_1^2 \, quad m_2^2 = p_2^2 = p_3^2 \, $ <eq-masses>

and Mandelstahm variables:

$ s = \( p_1 + p_2 \)^2 \, quad t = q_()^2 = \( p_1 + p_4 \)^2 \, quad u = \( p_1 + p_3 \)^2 \, $

subject to the usual equation:

$ s + t + u = 2 \( m_1^2 + m_2^2 \) . $

We can also change the external momentum variables to ones more amenable to the soft limit, namely:

$ p_1 = - \( tilde(p)_1 - q_() / 2 \) \, p_2 = - \( tilde(p)_2 + q_() / 2 \) \, p_3 = \( tilde(p)_2 - q_() / 2 \) \, p_4 = \( tilde(p)_1 + q_() / 2 \) . $ <eq-newmom>

The new momentum variables $tilde(p)_i$ are crucially orthogonal to momentum transfer $q_()$ :#footnote[we use #ref(<eq-masses>)]

$ tilde(p)_i dot.op q_() = 0 \, $ <eq-orthog>

and the physical scattering region, given by $s > \( m_1 + m_2 \)^2$ and $q_()^2 < 0$ is the given by the same formulas:

$ s = \( - \( tilde(p)_1 - q_() / 2 \) - \( tilde(p)_2 + q_() / 2 \) \)^2 = \( tilde(p)_1 + tilde(p)_2 \)^2 $

and

$ t = \( - \( tilde(p)_1 - q_() / 2 \) + tilde(p)_1 + q_() / 2 \)^2 = q_()^2 . $

With all the ingredients in place, we can now go on to compute the amplitudes.

== Tree level
We start with the tree level amplitude, the only #acr("lo") contribution in for example #ref(<eq-impulseLO>). The only possible diagram we can build with four external scalar legs, and vertices as defined in #ref(<tbl-sqedfrules>), is the following tree:

#figure(timg("treelevelsqed.svg"),
  caption: [
    Tree
  ]
)

The amplitude is read off diagram and using Feynman rules for SQED we have:

$ cal(macron(A))^(\( 0 \)) = circle(dotless.i) tilde(D)^(mu nu) \( q \) dot.op thin e^2 Q_1 Q_2 2 tilde(p)_1 zws^mu 2 tilde(p)_2 zws^nu = frac(4 e^2 Q_1 Q_2 tilde(p)_1 dot.op tilde(p)_2, q_()^2) \, $

using the Mandelstahm invariants described above we can write this as:

$ cal(macron(A))^(\( 0 \)) = e^2 Q_1 Q_2 frac(4 m_1 m_2 sigma, planck^2 macron(q)_()^2) \, $ <eq-treeampl>

where $sigma$ is the relativistic factor of particle 1 in the rest frame of particle 2:

$ sigma = frac(s - m_1^2 - m_2^2, 2 m_1 m_2) = frac(p_1 dot.op p_2, m_1 m_2) = frac(tilde(p)_1 dot.op tilde(p)_2, m_1 m_2) + cal(O) \( planck^() \) . $ <eq-relfact>

We now input the reduced version $cal(macron(A))^(\( 0 \)) e^2 = cal(A)^(\( 0 \))$ of the amplitude, and take the $planck arrow.r 0$ limit of #ref(<eq-impulseLO>). We can safely take the $planck arrow.r 0$ limit as the integrand contains no terms singular in $planck$ (the $1 / planck^2$ is cancelled by the $planck^2$ pre-factor). Notice that the integration measure #ref(<eq-DeltaOclas>) simplifies in the classical limit:#footnote[Compare to $thin upright(d) macron(Psi)_() \( macron(q)_() \) thin & = thin tilde(upright(d))^4 macron(q)_() thin tilde(delta)^() \( 2 p_1 dot.op macron(q)_() + planck macron(q)_()^2 \) Theta^() \( p_1 zws^0 + q_()^0 \)\
 & tilde(delta)^() \( 2 p_1 dot.op macron(q)_() + planck macron(q)_()^2 \) Theta^() \( p_2 zws^0 + q_()^0 \)$ The theta functions cancel as $q_()^0 arrow.r 0$and$p_i$ becomes classical.]

$ lim_(planck arrow.r 0) thin upright(d) macron(Psi)_() \( macron(q)_() \) thin = thin tilde(upright(d))^4 macron(q)_() thin tilde(delta)^() \( 2 m_1 breve(u_1) dot.op macron(q)_() \) tilde(delta)^() \( 2 m_2 breve(u_2) dot.op macron(q)_() \) . $

The integrand corresponding to the #acr("lo") contribution to the impulse is then:

#svg-math[$ Delta p_1^(mu \, \( 0 \)) = 4 e^2 Q_1 Q_2 m_1 m_2 sigma integral thin tilde(upright(d))^4 macron(q)_() thin upright(e)^(- circle(dotless.i) macron(q)_() dot.op b) macron(q)_()^mu frac(cancel(planck^2), cancel(planck^2) macron(q)_()^2) tilde(delta)^() \( 2 m_1 breve(u_1) dot.op macron(q)_() \) tilde(delta)^() \( 2 m_2 breve(u_2) dot.op macron(q)_() \) . $]

This can be analytically computed to find a closed form for the #acr("lo") impulse.

$ Delta p_1^(mu \, \( 0 \)) = - frac(e^2 Q_1 Q_2, 2 pi) gamma / sqrt(gamma^2 - 1) b^mu / b^2 $

== One loop
Already at one loop the number of possible diagrams increases dramatically from 1 to 13. One can nonetheless enumerate them. As we increase loop count, the number of diagrams increases exponentially. It is therefore useful to have a systematic, programmatic way to handle these diagrams, and while we are at it, also to compute the amplitudes. Note that all the code needed to do these computations can be found on the repository for this book: #link("https://github.com/lcnhb/GWAmplitudes").

The first tool we will use is `QGRAF` #cite(<Nogueira:1993a>, form: "prose"), a Fortran based program that can generate Feynman diagrams for a given set of vertices and external legs. The first step is to define the theory we want to derive the diagrams from. This is essentially writing down the Feynman rules, without actually specifying what the graphical objects are. For #acr("sqed") the model file is short:

```default
* propagators
 [Phi1,Phi1c,+]
 [Phi2,Phi2c,+]
 [Photon,Photon,+]

* vertices
 [Phi1c,Photon,Phi1]
 [Phi2c,Photon,Phi2]
 [Phi1c,Photon,Photon,Phi1]
 [Phi2c,Photon,Photon,Phi2]
```

This file also defines the names of the fields in question. We can then give `QGRAF` additional options, such as the number of external legs, and the number of loops, written in a `qgraf.dat` file that can look like this:

```default
output= '{{output filename}}' ;
style= './styles/julia.sty' ; 

model= './qgraf/SQEDmodel';

in= Phi1,  Phi2;
out= Phi1,Phi2;
loops= 1;
loop_momentum= k;

options=  notadpole,nosnail,onshell ;
```

where we specify what process we are interested in (two-to-two scattering). We also specify that we want to compute the one loop amplitude, and that we want to use the `julia.sty` style file. The `julia.sty` file is a style file that is used to generate the output in a format that can be read by a `Julia` @Bezanson:2015 package built to process and visualise the outputted graphs. This package is called (maybe too broadly) `QFT.jl`, and is hosted on #link("https://github.com/lcnhb/QFT.jl")[github] . Let us see it in action. We can run `QGRAF` from the command line, and it will generate a file called `{{output filename}}` that contains the output of the program. We can then use this in a `Julia` file to visualize the diagrams.

````julia
using Images
using QFT
using QFT.Diagrams
using QFT.FieldGraphs
using QFT.Fields
import  Catlab.Graphics.Graphviz: pprint
include("SQED.jl")
diags=include("QGRAFout/julia/1lSQED.jl")


qDiags=[qDiagram(;diag...) for diag in diags]
grafs=(x -> x.g).(qDiags)
println("::: {#fig-oneloopsqed  layout-ncol=4 .column-body-right }")
for (i,graf) in enumerate(grafs)
println("```dot")
println("//| fig-width: 1.5")
    pprint(stdout,to_graphviz(graf,graph_attrs=Dict("layout"=>"neato")))
    println("```")
end
println("all one loop graphs in #acr("sqed")")
println(":::")
nothing
````

#figure(subfigs(columns: 4, timg("feynman-graph-1.svg"), timg("feynman-graph-2.svg"), timg("feynman-graph-3.svg"), timg("feynman-graph-4.svg"), timg("feynman-graph-5.svg"), timg("feynman-graph-6.svg"), timg("feynman-graph-7.svg"), timg("feynman-graph-8.svg"), timg("feynman-graph-9.svg"), timg("feynman-graph-10.svg"), timg("feynman-graph-11.svg"), timg("feynman-graph-12.svg"), timg("feynman-graph-13.svg")), caption: [all one loop graphs in #acr("sqed")]) <fig-oneloopsqed>
We notice a few things about the diagrams in #ref(<fig-oneloopsqed>) above. Not all the diagrams contribute to the classical limit. Clearly the diagrams with internal matter loops cannot be allowed when the momenta incoming to the loop is soft #footnote[scales like $planck$]. In the classical limit this momentum will go to 0, and since the scalars are massive, they need momentum greater than their mass to be pair-produced, thus these diagrams do not contribute. Another class of diagrams that does not contribute to the classical limit are the ones with photon loops that start and end on the same matter line. These do not contribute because they are scaleless. An integral is scaleless when its integrand $cal(I)_(upright("scaleless")) \( { ell_i } \)$ scales homogeneously under any rescaling of the loop momentum $ell_i$:

$ cal(I)_(upright("scaleless")) \( { ell_i } \) arrow.r^(ell_j arrow.r lambda ell_j) lambda^eta cal(I)_(upright("scaleless")) \( { ell_i } \) $

Thus, any diagram that has a basis of loops that does not contain both scalar fields (i.e.~does not cross over) cannot have its scale set by the momentum transfer, and is thus scaleless. Dimensionally regularized scaleless integrals vanish, thus we can also discard these diagrams. We can easily implement such a filter programmatically, by checking that if cycles are present they touch either both types of scalars, or neither. To compute the cycle basis we use an algorithm derived from #cite(<Paton:1969>, form: "prose"), implemented in the #link("https://github.com/lcnhb/DirectedHalfEdgeGraphs.jl")[DirectedHalfEdgeGraphs.jl] package.

````julia
using Logging
Logging.disable_logging(Logging.Info)
function scaleless(g::AbstractFieldGraph)
  cycles =cycle_basis(g)
  isscaleless=false
  for c in cycles
    hs= collect(Iterators.flatten(half_edges.(Ref(g),c)))
    fields=unique!(typeof.(field.(Ref(g),hs)))
    if Bool(Phi1 in fields) ⊻  Bool(Phi2 in fields)
      isscaleless=true
    end
  end
  return isscaleless
end

noscalelessdiags=qDiags[.!scaleless.(grafs)]
classicaldiags=noscalelessdiags[2:end]
for (i,d) in enumerate(classicaldiags)
  d.ID=i
end

println("::: {#fig-onefilterloopsqed  layout-ncol=5 .column-body-right }")
for (i,graf) in enumerate(grafs[.!scaleless.(grafs)])
println("```dot")
println("//| fig-width: 1")
    pprint(stdout,to_graphviz(graf,graph_attrs=Dict("layout"=>"neato")))
    println("```")
end
println("one loop graphs that contribute to the classical limit in #acr("sqed")")
println(":::")
nothing
````

#figure(subfigs(columns: 5, timg("feynman-graph-14.svg"), timg("feynman-graph-15.svg"), timg("feynman-graph-16.svg"), timg("feynman-graph-17.svg"), timg("feynman-graph-18.svg")), caption: [one loop graphs that contribute to the classical limit in #acr("sqed")]) <fig-onefilterloopsqed>
There is one final simplification we can do. The first diagram in #ref(<fig-onefilterloopsqed>) has two photon propagators, and two quartic vertices, which give it the name: "double-seagull". The photon propagators have homogeneous $planck^(- 2)$ scaling (see #ref(<eq-photonscale>)), the vertices only bring constants, and the loop integration has $planck^4$ scaling. Collecting all scalings this means that the reduced amplitude has $planck^0$ scaling. However, in the virtual integrand the reduced amplitude has to cancel with the transfer momentum's $planck$ scale (see #ref(<eq-impulseIr>)). Thus, the double seagull diagram vanishes in the classical limit.

We are left with only 4 diagrams, the two triangle diagrams, the box, and cross box, which we can now compute. At this point, we can do this manually, but again, putting in place a programmatic framework means that subsequent loops can be treated systematically #footnote[at least at the un-integrated level]. We will also extract one of these integrands by hand, for completeness and comparison.

The first step is to define the Feynman rules in a computer readable format. We will use `Julia` to apply these rules at every vertex and every edge, but for the actual computation we will use `FORM` @Vermaseren:2000nd @Kuipers:2012rf, which can automatically contract indices and performs expression manipulations in an optimized way. The Feynman rules implementation in the package developed for this thesis make use of `Julia`s defining paradigm of multiple dispatch. This allows us to define the rules for each vertex and each edge in a very compact way. We can define the rules for #acr("sqed") as follows:

```julia
function feynmanRule(mime::MIME"text/FORM",p,f1::Photon,f2::Photon)
  momen = repr(mime,p.symbol)
  indx1 = repr(mime,index(f1))
  indx2 = repr(mime,index(f2))
  "_i* prop(-1,0,$momen)*d_($indx1,$indx2)"
end

@symmetric function feynmanRule(mime::MIME"text/FORM",p,[f1::Phi1,f2::Phi1c])
  momen = repr(mime,p.symbol)
  "_i* prop(-1,1,$momen)"
end

@symmetric function feynmanRule(mime::MIME"text/FORM",p,[f1::Phi2,f2::Phi2c])
  momen = repr(mime,p.symbol)

  "_i* prop(-1,2,$momen)"
end

@symmetric function feynmanRule(mime::MIME"text/FORM",[(pᵩ₁,a)::Tuple{Any,ScalarField{S}},
            (pᵩ₂,b)::Tuple{Any,AdjointField{ScalarField{S}}},
            (pᵧ,γ)::Tuple{Any,Photon}]) where {S}
  p1 = repr(mime,pᵩ₁(index(γ)))
  p2 = repr(mime,pᵩ₂(index(γ)))
  q = repr(mime,charge(a))
  "_i*e*$q*($p2-$p1)"
end

@symmetric function feynmanRule(mime::MIME"text/FORM",[(pᵧ₁,γ₁)::Tuple{Any,Photon},
            (pᵧ₂,γ₂)::Tuple{Any,Photon},(pᵩ₂,b)::Tuple{Any,AdjointField{ScalarField{S}}},
            (pᵩ₁,a)::Tuple{Any,ScalarField{S}}]) where {S}    
  mu = repr(mime,index(γ₁))
  nu = repr(mime,index(γ₂)) 
  q = repr(mime,charge(a))
  "2*_i*$q^2*e^2*d_($mu,$nu)"
end 
```

where we define `prop(n,i,p)` as representing a generic Feynman propagator, which we will denote:

$ D_(-) \( n \, i \, p \) = mono(p r o p \( n \, i \, p \)) = \( p^2 - m_i^2 + i epsilon.alt \)^n quad upright("thus") quad mono(p r o p \( - 1 \, i \, p \)) = frac(1, p^2 - m_i^2 + i epsilon.alt) . $

We can now apply these Feynman rules to the graphs we have left, obtaining `FORM` readable integrands. For example, the box diagram gives:

````julia
```{{julia}}
toform(stdout,classicaldiags[3])
```
````

```
*--#[d3l1:
```

```
L [d3l1|o.3.4|i.3.4|i|o|] = 1*i_* prop(-1,0,q1)*d_(nu1,nu2)*i_* prop(-1,1,q2)*i_* prop(-1,2,q3)*i_* prop(-1,0,q4)*d_(nu7,nu8)*i_*e*qch1*(q2(nu1)-p4(nu1))*i_*e*qch2*(q3(nu2)-p2(nu2))*i_*e*qch1*(p3(nu7)-q2(nu7))*i_*e*qch2*(p1(nu8)-q3(nu8));
#procedure momentumRouting
```

```
Id q2 = p3 + -q4;
Id p1 = p2 + p4 + -p3;
Id q1 = p3 + -p4 + -q4;
Id q3 = p2 + p4 + q4 + -p3;

Id q4= l1;
#endprocedure
*--#]d3l1:
```

Notice that we also define the momentum routing by imposing the replacement rules, one per vertex. This can be done in many ways but to ensure proper scaling we set the loop momenta to be homogeneous on the massless lines. This is done by the `Julia` program, using Kruskal's algorithm @Kruskal:1956 to find the maximal-mass spanning tree of the graph, and then setting the loop momenta to be those internal edges that are missing from the tree. The maximal mass spanning tree of the box is visualised in #ref(<fig-kruskalbox>) .Using `FORM`, we can contract indices and apply the momentum conservation rules. Finally, we also apply the relabeling rules described in #ref(<eq-newmom>). The `FORM` version of the box integrand is then given in #ref(<lst-formBox>).

#figure(timg("kruskalbox.png"),
  caption: [
    The maximal mass spanning tree of the box diagram in blue. The loop momenta are the edges that are missing from the tree.
  ]
)
<fig-kruskalbox>

#figure([```default

     [d3l1|o.3.4|i.3.4|i|o|] =
           ( prop(-1,0,q - l1) )
         * ( prop(-1,0,l1) )
         * ( prop(-1,1,1/2*q - l1 + pb1) )
         * ( prop(-1,2, - 1/2*q + l1 + pb2) )
         * ( dot(q,q) - 2*dot(q,l1) - 2*dot(q,pb2) + 2*dot(q,pb1) + dot(l1,l1)
            + 2*dot(l1,pb2) - 2*dot(l1,pb1) - 4*dot(pb2,pb1) )
         * ( dot(l1,l1) + 2*dot(l1,pb2) - 2*dot(l1,pb1) - 4*dot(pb2,pb1) )
         * ( qch2 ) * ( qch2 ) * ( qch1 ) * ( qch1 )
         * ( e ) * ( e ) * ( e ) * ( e );
  ```

  ],
  caption: [
    Box integrand in FORM
  ]
)
<lst-formBox>

When applied to all 4 diagrams, we obtain precisely the same integrands as those in #cite(<Kosower:2018adc>, form: "prose"). Additionally, we notice that the two triangles and the box diagram have overlapping propagators. In fact the denominators of the integrands for all three can be written as:

$ square.stroked_(i_1 \, i_2 \, i_3 \, i_4) = frac(1, rho_1^(i_1) rho_2^(i_2) rho_3^(i_3) rho_4^(i_4)) \, $ <eq-boxfam>

for powers ${ i } in { 0 \, 1 }^4$, where the inverse propagators $rho_i$ are:

$ rho_1 = ell^2 + circle(dotless.i) epsilon.alt \, quad rho_2 = \( ell - q \)^2 + circle(dotless.i) epsilon.alt \, quad rho_3 = \( q / 2 - ell + tilde(p)_1 \)^2 - m_1^2 + circle(dotless.i) epsilon.alt \, quad rho_4 = \( - q / 2 + ell + tilde(p)_2 \)^2 - m_2^2 + circle(dotless.i) epsilon.alt $

Note that in the classical limit we can expand the massive propagators as shown in #ref(<eq-massiveScale>) and obtain, to first order in $planck$,

$ rho_3 = 2 ell dot.op tilde(p)_1 + circle(dotless.i) epsilon.alt \, quad rho_4 = - 2 ell dot.op tilde(p)_2 + circle(dotless.i) epsilon.alt \, $

where we used #ref(<eq-orthog>). The cross box can in fact extend this family, by adding just one more inverse propagator. We now have the complete description of the denominators of all 1-loop contributing diagrams. The numerators in fact do not complicate things much. They are all composed of scalar products of momenta. If these do not contain loop-momenta they are just constant factors in front of the integral. The scalar products that do contain loop momenta can be written as inverse powers of the propagators. This is the case for any Feynman like integrand. Consider the following general integrand:

$ cal(I) = cal(N) / cal(D) = frac(product_(S') N_(S'), product_S D_S) = frac(product_(S') sum_(i gt.eq j) S'_(i j) p_i dot.op p_j, product_S sum_(i gt.eq j) S_(i j) p_i dot.op p_j) \, $

where $S$ and $S'$ are sets of coefficient matrices for all possible dot products. If we have a quadruplet ${ A \, B \, a \, b }$ such that $A_(a \, b) eq.not 0$ and $B_(a \, b) n e q 0$ and $p_a$or $p_b$ is a loop momentum $ell$, say $p_a = ell$,then it is useful to write this component of the integrand as:

$ N_B / D_A = frac(tilde(N)_B + B_(a b) ell dot.op p_b, A_(a b) ell dot.op p_b + sum_(i gt.eq j\
i \, j eq.not a \, b) A_(i j) p_i dot.op p_j) = tilde(N)_B / D_A + B_(a b) / A_(a b) \( 1 - tilde(D)_A / D_A \) \, $ <eq-scalarred>

where the tilde means that we have remove the $a b$ contribution. Thus, we see that we obtain a sum of objects in the numerator, none of which contains the dot product: $ell dot.op p_b$. We can do this for every quadruplet ${ A \, B \, a \, b }$, after every replacement, and obtain an integrand containing only so called #emph[irreducible] loop-momenta scalar products. In the cases we have here, they all disappear, leaving us truly with a family of integrands like #ref(<eq-boxfam>). This can be readily fed into a IBP solver, such as `AIR` @Anastasiou:2004, `FIRE` @Smirnov:2020 or `Kira` @Maierhofer:2018.

With such a solver we can obtain a complete family of integrals, which can be evaluated. We are thus able to obtain the integrated integrands at #acr("nlo") that are then used in #ref(<eq-impulseIr>) and #ref(<eq-impulseIv>). The algorithm described above was implemented in `FORM` and is able to rapidly process the 1-loop diagrams. The code is available in the repository for this thesis.

Importantly, we still need to take the classical limit. At this point a problem shows up. The box and cross box integrals are divergent in the classical limit (some authors call this super classical). Let us see this for the box integral. We have from #ref(<lst-formBox>) that the integral for the box diagram $B$ is:

$ circle(dotless.i) B = e^4 Q_1 Q_2 integral thin tilde(upright(d))^D ell thin \( 4 tilde(p)_1 dot.op tilde(p)_2 + 2 ell dot.op \( tilde(p)_2 - tilde(p)_1 \) - \( q_() - ell \)^2 \) \( 4 tilde(p)_1 dot.op tilde(p)_2 + 2 ell dot.op \( tilde(p)_2 - tilde(p)_1 \) - \( ell \)^2 \) B o x_(1 \, 1 \, 1 \, 1) $

we can apply the procedure described above, turning messenger momenta into wave-numbers:

$ circle(dotless.i) B = e^4 Q_1 Q_2 integral thin tilde(upright(d))^D macron(ell) thin planck^D / planck^6 \( 4 tilde(p)_1 dot.op tilde(p)_2 + planck 2 macron(ell) dot.op \( tilde(p)_2 - tilde(p)_1 \) - planck^2 \( macron(q)_() - macron(ell) \)^2 \) \( 4 tilde(p)_1 dot.op tilde(p)_2 + planck 2 macron(ell) dot.op \( tilde(p)_2 - tilde(p)_1 \) - planck^2 \( macron(ell) \)^2 \) square.stroked_(macron(1) \, macron(1) \, macron(1) \, macron(1)) \, $

where $square.stroked_(macron(i)_1 \, macron(i)_2 \, macron(i)_3 \, macron(i)_4) = 1 / planck^(2 \( i_1 + i_2 \) + i_3 + i_4) square.stroked_(i_1 \, i_2 \, i_3 \, i_4)$ is the box family with wave-number instead of messenger momenta, and $planck$s extracted. We notice that if we apply the scalar product reduction #ref(<eq-scalarred>), we will necessarily still have an integral of the form #footnote[along with ones that are of the form $square.stroked_(1 \, 1 \, 1 \, 0)$and other permutations. These are not divergent in the classical limit, as they have one less propagator, thus one less$planck$, just enough to cancel what is left of the $planck$in the numerator, and have an overall$cal(O) \( planck^0 \)$ scaling.]:

$ e^4 Q_1 Q_2 16 \( tilde(p)_1 dot.op tilde(p)_2 \)^2 integral thin tilde(upright(d))^D ell thin square.stroked_(1 \, 1 \, 1 \, 1) = cal(O) \( planck^(D - 6) \) . $

We need to cancel with the $planck$ in the classical limit (#ref(<eq-hbarvirt>)), here we have one too many orders in the denominator (if D=4). Thus, we would get a divergent ($1 / planck$) contribution when taking the classical $planck arrow.r 0$ limit. If we consider now the cross box, which is the same family as above but with an extra minus sign:

$ tilde(rho)_4 = \( q / 2 - ell + tilde(p)_2 \)^2 - m_2^2 + circle(dotless.i) epsilon.alt tilde.eq 2 ell dot.op tilde(p)_2 + circle(dotless.i) epsilon.alt . $

If we write that $square.stroked_(i_1^(+) \, i_2^(+) \, i_3^(+) \, i_4^(+)) = square.stroked_(i_1 \, i_2 \, i_3 \, i_4)$ where the sign is the sign of the $circle(dotless.i) epsilon.alt$ prescription, then we can write the cross box integral as: $ integral thin tilde(upright(d))^D ell thin - square.stroked_(1 \, 1 \, 1 \, 1^(-)) $

thus summing up the two divergent contributions from the box and cross box we have:

$ square.stroked_(1 \, 1 \, 1 \, 1) - square.stroked_(1 \, 1 \, 1 \, 1^(-)) = square.stroked_(1 \, 1 \, 1 \, 0) \( frac(1, - 2 ell dot.op tilde(p)_2 + circle(dotless.i) epsilon.alt) - frac(1, 2 ell dot.op tilde(p)_2 + circle(dotless.i) epsilon.alt) \) = - circle(dotless.i) square.stroked_(1 \, 1 \, 1 \, 0) tilde(delta)^() \( 2 ell dot.op tilde(p)_2 \) \, $ <eq-boxcross>

where in the equation line we used #emph[reverse unitarity] @Anastasiou:2002yz @Anastasiou:2002qz @Anastasiou:2003yy. This idea was developed in the context of cross-section calculations in the for collider physics. It enables to set on equal footing real contributions #footnote[such as ones in the real integrand #ref(<eq-rInt>)] where we integrate over on shell momenta #footnote[thus three dimensional momentum space] and virtual integrals, where the integration is over all possible four-momentum #footnote[as virtual particles can be off shell]. The idea is to trade the on-shell delta functions and their $n$-th derivatives for differences of (powers of) propagators with alternating $circle(dotless.i) epsilon.alt$:

$ frac(circle(dotless.i), \( - 1 \)^n n !) frac(upright(d)^n, upright(d) z^n) tilde(delta)^() \( z \) = frac(1, \( z - circle(dotless.i) epsilon.alt \)^(\( n + 1 \))) - frac(1, \( z + circle(dotless.i) epsilon.alt \)^(\( n + 1 \))) . $ <eq-reverseunitarity>

In our case #ref(<eq-reverseunitarity>) implies the following identities:

$ tilde(delta)^() \( - 2 ell dot.op tilde(p)_2 \) = circle(dotless.i) \( square.stroked_(0 \, 0 \, 0 \, 1) - square.stroked_(0 \, 0 \, 0 \, 1^(-)) \) $ <eq-revone>

$ tilde(delta)^() \( 2 ell dot.op tilde(p)_1 \) = circle(dotless.i) \( square.stroked_(0 \, 0 \, 1 \, 0) - square.stroked_(0 \, 0 \, 1^(-) \, 0) \) $ <eq-revtwo>

Since we were able to write this difference of propagators as a sort of cut, we could further compare the divergent part of the box and cross box with the corresponding real contribution, which is at tree level, with no cut messengers: $L' = 0$ and $\| X \| = 0$ such that #ref(<eq-rvloopmatch>) is satisfied. We have:

$ integral & thin tilde(upright(d))^4 macron(w) thin tilde(delta)^() \( 2 tilde(p)_1 dot.op macron(w) - planck macron(q)_() / 2 dot.op macron(w) + planck macron(w)^2 \) tilde(delta)^() \( - 2 tilde(p)_2 dot.op macron(w) + planck macron(q)_() / 2 dot.op macron(w) + planck macron(w)^2 \)\
 & times planck macron(w)^mu\
 & times kappa^4 planck^2 cal(macron(A))^(\( 0 \)) \( tilde(p)_1 - planck macron(q)_() / 2 \, tilde(p)_2 + planck macron(q)_() / 2 arrow.r tilde(p)_1 + planck macron(q)_() / 2 + planck macron(w) \, tilde(p)_2 - planck macron(q)_() / 2 - planck macron(w)_2 \)\
 & times cal(macron(A) zws^(*))^(\( 0 \)) \( tilde(p)_1 + planck macron(q)_() / 2 \, tilde(p)_2 + planck macron(q)_() / 2 - planck macron(q)_() arrow.r tilde(p)_1 - planck macron(q)_() / 2 + planck macron(w) \, tilde(p)_2 + planck macron(q)_() / 2 - planck macron(w)_2 \) . $

where the $cal(macron(A))^(\( 0 \))$ we already computed in #ref(<eq-treeampl>), and we have eliminated the theta functions in preparation of taking the classical limit. Thus, it is essentially a cut of a one-loop box. Notice that in the classical limit we must cancel with $planck^3$ (#ref(<eq-hbarreal>)) which at leading order is again overdone. The $tilde(p)_1 dot.op tilde(p)_2$ contribution from each tree scales like $1 / planck^4$, and is thus classically divergent as the box and cross box before it. We also notice it has the following form:

$ e^4 Q_1 Q_2 16 \( tilde(p)_1 dot.op tilde(p)_2 \)^2 1 / planck integral thin tilde(upright(d))^4 macron(ell) thin macron(ell)^mu tilde(delta)^() \( 2 tilde(p)_1 dot.op macron(ell) \) tilde(delta)^() \( - 2 tilde(p)_2 dot.op macron(ell) \) square.stroked_(macron(1) \, macron(1) \, macron(0) \, macron(0)) \, $

where we have changed variables from $macron(w)$ to $macron(ell)$ and removed the $planck \( macron(q)_() / 2 dot.op macron(ell) plus.minus macron(ell)^2 \)$ term in the delta functions, in preparation for the classical limit. We can now apply reverse unitarity (#ref(<eq-revone>),#ref(<eq-revtwo>)) and focus on the integral without the pre-factors:

$ integral thin tilde(upright(d))^4 macron(ell) thin macron(ell)^mu & tilde(delta)^() \( 2 tilde(p)_1 dot.op macron(ell) \) tilde(delta)^() \( - 2 tilde(p)_2 dot.op macron(ell) \) square.stroked_(macron(1) \, macron(1) \, macron(0) \, macron(0)) = integral thin tilde(upright(d))^4 macron(ell) thin macron(ell)^mu tilde(delta)^() \( 2 tilde(p)_1 dot.op macron(ell) \) circle(dotless.i) \( square.stroked_(0 \, 0 \, 0 \, 1) - square.stroked_(0 \, 0 \, 0 \, 1^(-)) \) square.stroked_(macron(1) \, macron(1) \, macron(0) \, macron(0))\
 & = - integral thin tilde(upright(d))^4 macron(ell) thin macron(ell)^mu \( square.stroked_(0 \, 0 \, 1 \, 0) - square.stroked_(0 \, 0 \, 1^(-) \, 0) \) \( square.stroked_(1 \, 1 \, 0 \, 1) - square.stroked_(1 \, 1 \, 0 \, 1^(-)) \) \,\
 & = integral thin tilde(upright(d))^4 macron(ell) thin macron(ell)^mu \[ \( square.stroked_(1 \, 1 \, 1 \, 1^(-)) - square.stroked_(1 \, 1 \, 1 \, 1) \) + \( square.stroked_(1 \, 1 \, 1^(-) \, 1) - square.stroked_(1 \, 1 \, 1^(-) \, 1^(-)) \) \] . $

We now notice something interesting, this cut integral has a sort of horizontal flip symmetry, i.e., if we average over the existing 'loop' momentum labelling and a new $ell' = q - ell$ we eliminate the $ell zws^mu$ dependence in the numerator:

$ 1 / 2 \[ ell zws^mu + \( q zws^mu - ell zws^mu \) \] = q zws^mu $

since the box families transform as:

$ square.stroked'_(i \, j \, m \, n) = \( - 1 \)^m \( - 1 \)^n square.stroked_(j \, i \, - m \, - n) . $ <eq-boxtrans>

Thus we have that the cut integral with the $macron(q)_() zws^mu$ factored out:

$ integral thin tilde(upright(d))^4 macron(ell) thin 1 / 2 \[ \( square.stroked_(1 \, 1 \, 1 \, 1^(-)) - square.stroked_(1 \, 1 \, 1 \, 1) \) + \( square.stroked_(1 \, 1 \, 1^(-) \, 1) - square.stroked_(1 \, 1 \, 1^(-) \, 1^(-)) \) \] . $

We can apply the relabeling only this time only for the last two integrands, and the integral becomes, applying #ref(<eq-boxtrans>):

$ integral thin tilde(upright(d))^4 macron(ell) thin 1 / 2 \[ \( square.stroked_(1 \, 1 \, 1 \, 1^(-)) - square.stroked_(1 \, 1 \, 1 \, 1) \) + \( square.stroked'_(1 \, 1 \, 1^(-) \, 1) - square.stroked'_(1 \, 1 \, 1^(-) \, 1^(-)) \) \] = integral thin tilde(upright(d))^4 macron(ell) thin \( square.stroked_(1 \, 1 \, 1 \, 1^(-)) - square.stroked_(1 \, 1 \, 1 \, 1) \) . $

If we now add the box and cross box contributions from #ref(<eq-boxcross>) we get:

#svg-math[$ integral thin tilde(upright(d))^4 macron(ell) thin \( cancel(square.stroked_(1 \, 1 \, 1 \, 1^(-)), inverted: #true) - cancel(square.stroked_(1 \, 1 \, 1 \, 1)) \) + cancel(square.stroked_(1 \, 1 \, 1 \, 1)) - cancel(square.stroked_(1 \, 1 \, 1 \, 1^(-)), inverted: #true) = 0 . $]

The classically divergent terms have cancelled leaving us with only the finite terms. We now have full control over the classical limit of the one loop contribution to the real and virtual parts of the amplitude.

== Higher order and gravity
The code provided is fully general in loop number and can be extended readily to higher loops, at the un-integrated level. The number of contributing diagrams quickly increases however. At two loops, we go from 5 non-scaleless diagrams to 34 (see #ref(<fig-2lSQEDclassical>)), and at three loops we have 470 diagrams (see #ref(<fig-3lSQEDclassical>)).

#figure(timg("feynman-graph-19.svg"), caption: [All scaleful diagrams, in the classical limit at two loops in SQED]) <fig-2lSQEDclassical>
#figure(timg("3lsqedclass.webp"),
  caption: [
    All scaleful diagrams, in the classical limit at three loops in SQED
  ]
)
<fig-3lSQEDclassical>

The classically divergent term cancelations, have been explicitly derived above for the one loop case, however it is not immediately extendable to higher loops. Arguments using Cutkosky rules have been used in @Herrmann:2021tct to show this at two loops.

We have up to now only considered the toy model of scalar QED, however the same techniques can be applied to gravity. In this case one considers the same scalars minimally coupled to gravity, using the Einstein-Hilbert action. Going through the same procedures as above, with more algebra, one can also obtain Feynman rules. One key difference is that the gravitons self interact, and do so for any vertex degree. Additionally, the graviton-scalar vertex can also involve any number of gravitons. Of course the highest degree vertex is always limited by the number of loops, such that in practice, one only needs to consider truncated Feynman rules. We implemented these rules in `QGRAF` and `Julia`, and we can see the resulting diagrams at one loop in #ref(<fig-1lGRclassical>) only contains one new diagram, and two loops #ref(<fig-2lGRclassical>), there are substantially more new diagrams.

#figure(timg("feynman-graph-20.svg"), caption: [All scaleful diagrams, in the classical limit at 1 loop in GR]) <fig-1lGRclassical>
#figure(timg("feynman-graph-21.svg"), caption: [All scaleful diagrams, in the classical limit at 2 loops in GR]) <fig-2lGRclassical>
