#import "/lib/thesis.typ": chapter, acr, timg, subfigs, xref
#import "/lib/links.typ": n
#import "/lib/figures.typ": svg-math

#show: chapter.with(thesis: "msc-thesis", number: 2, summary: "Gravitational waves from the linearised Einstein equations, and their astrophysical sources.")

We start by looking at where and how #acr("gw", form: "full", plural: true) are generated. We will see that #acr("gr", form: "full") predicts the existence of #acr("gw", plural: true), and we will explore under what conditions they are observable.

= #acr("gw", form: "long", plural: true)
To this day, the most fundamental theory of gravity is #acr("gr"), due to Einstein. It formulates spacetime as a Riemannian manifold with curvature, determined by mass distribution. This curvature is encoded in the metric $g zws_(mu nu)$. Objects then move in this deformed spacetime following #acr("eom", form: "full", plural: true) written in terms of $g zws_(mu nu)$. Interaction is thus caused by the dependence of $g zws_(mu nu)$ on mass distribution, which itself evolves through $g zws_(mu nu)$. The physical laws that governs the interaction between mass and curvature are manifested in Einstein's field equations,

$ #box(stroke: black, inset: 3pt, [$ R zws_(mu nu) - frac(g zws_(mu nu), 2) R + Lambda g zws_(mu nu) = - 8 pi G T zws_(mu nu) $]) . $ <eq-EFE>

The #acr("lhs", form: "full") of this equation contains several objects that only depend on the metric $g zws_(mu nu)$. $R zws_(mu nu)$ is the Ricci tensor#footnote[The Ricci Tensor is given by: $R zws_(mu nu) colon.eq R_(mu alpha nu)^alpha = g zws^(alpha beta) R zws^(alpha mu beta nu)$], a contraction of the Riemann curvature tensor $R_(mu nu rho)^beta$. The Riemann tensor#footnote[The Riemann Tensor is given by: $R_(mu nu rho)^beta = Gamma_(mu nu)^beta zws_(\, rho) - Gamma_(mu rho)^beta zws_(\, nu) - Gamma_(mu rho)^alpha Gamma_(alpha nu)^beta + Gamma_(mu nu)^alpha Gamma_(alpha rho)^beta .$] encodes the curvature of spacetime, in terms of the non-commutativity of covariant derivatives. When they do, it means that they have collapsed to regular derivatives, and thus the Levi-civita connection#footnote[The Levi-Civita Connection is given by: $Gamma_(mu nu)^alpha = 1 / 2 g zws^(alpha rho) \{ g zws_(rho nu) zws_(\, mu) + g zws_(rho mu) zws_(\, nu) - g zws_(mu nu) zws_(\, rho) \}$] must have vanished. This is only possible if the metric is flat, $g zws_(mu nu) = eta zws_(mu nu)$. The Riemann curvature tensor is exclusively composed of the metric, its first, second derivatives, and it is linear in the second derivative of the metric. In fact, it is the only possible tensor of this form. The second term on the #acr("lhs") is the Ricci scalar, a further contraction of the Ricci Tensor: $R = g zws^(mu nu) R zws_(mu nu)$. The final term on the #acr("lhs") is just a proportional constant factor of the metric, $Lambda$, called the cosmological constant. It can be measured and has a low known upper bound. It is in part responsible for the expansion of the universe.

The #acr("rhs", form: "full") of #ref(<eq-EFE>) encodes the distribution of mass and energy in the universe, through the stress-energy tensor $T zws_(mu nu)$, which depends on the dynamical properties of the system. It is further multiplied by the Gravitational constant $G$. In empty space, $T zws_(mu nu)$ is zero.

#ref(<eq-EFE>) can be recast in a form where the Ricci scalar has been substituted by the trace of the stress-energy tensor,

$ #box(stroke: black, inset: 3pt, [$ R zws_(mu nu) = - 8 pi G (T zws_(mu nu) - T_(alpha)^alpha frac(g zws_(mu nu), 2)) + Lambda g zws_(mu nu) $]) $ <eq-EFEwoR>

Both #ref(<eq-EFE>) & #ref(<eq-EFEwoR>) with $Lambda = 0$ admit wave solutions. In order to see this, let us look at these equations in the weak field approximation. We take the metric to be a small perturbation around the Minkowskian background,

$ g zws_(mu nu) = eta zws_(mu nu) + h zws_(mu nu) \, $ <eq-WeakFA>

where $h zws_(mu nu)$ is the expansion parameter (thus considered small). Note that if we restrict ourselves to first order in $h zws_(mu nu)$ then all raising and lowering of indices is done with $eta zws_(mu nu)$. Since the #acr("lhs") of #ref(<eq-EFE>) is composed of the Ricci tensor and scalar, let us see how these behave in the weak approximation. Both are in fact made up of Levi-Civita connections, which to first order in $h zws_(mu nu)$ is given by: $ Gamma_(mu nu)^alpha = 1 / 2 eta zws^(alpha rho) \{ h zws_(rho nu) zws_(\, mu) + h zws_(rho mu) zws_(\, nu) - h zws_(mu nu) zws_(\, rho) \} + cal(O) \( h^2 \) quad . $ <eq-weakaffine>

Plugging #ref(<eq-weakaffine>) into the definition of the Ricci tensor we see that the terms with products of the connection vanish, and we are left with the derivative terms:

$ R zws_(mu nu) = frac(eta zws^(alpha rho), 2) [h zws_(rho alpha) zws_(\, mu nu) + h zws_(mu nu) zws_(\, rho alpha) - h zws_(mu alpha) zws_(\, rho nu) - h zws_(nu rho) zws_(\, mu alpha)] + cal(O) \( h^2 \) = R^(\( 1 \)) zws_(mu nu) + cal(O) \( h^2 \) $ <eq-Ricciweak>

The linearized Ricci scalar is then just $R^(\( 1 \)) = eta zws^(mu nu) R^(\( 1 \)) zws_(mu nu)$. The symmetry of the #acr("efe", form: "full") under general diffeomorphisms implies the existence of gauge freedom. In particular, #ref(<eq-EFE>), admits an infinite number of solutions, and in fact we can map a solution into another by changing coordinates in such a way that the equation isn't affected. To fix this ambiguity we choose a coordinate system ('gauge choice') by imposing the harmonic coordinate conditions:

$ g zws^(alpha beta) Gamma_(alpha beta)^mu = 0 $ <eq-hcc>

The harmonic coordinate conditions demand the vanishing of the trace of the Levi-Civita connection. They have a simplified form in the weak approximation, which we can access by plugging #ref(<eq-weakaffine>) into #ref(<eq-hcc>), giving:

$ \( eta zws^(alpha beta) + h zws^(alpha beta) \) 1 / 2 \( eta zws^(mu rho) + h zws^(mu rho) \) [h zws_(alpha rho) zws_(\, beta) + h zws_(beta rho) zws_(\, alpha) - h zws_(alpha beta) zws_(\, rho)] & = 0\
eta zws^(mu rho) eta zws^(alpha beta) [2 h zws_(alpha rho) zws_(\, beta) - h zws_(alpha beta) zws_(\, rho)] + cal(O) \( h^2 \) & = 0\
eta zws^(alpha beta) h zws_(alpha rho) zws_(\, beta) & = 1 / 2 h zws_(alpha beta) zws_(\, rho) eta zws^(alpha beta) + cal(O) \( h^2 \) . $

The last equation, truncated to first order, is called the De-Donder gauge condition:

$ h zws_(mu nu) zws^(\, mu) = 1 / 2 h_(alpha)^alpha zws_(\, nu) $

In the de-Donder gauge we can simplify the terms in #ref(<eq-Ricciweak>) to:

$ eta zws^(alpha beta) h zws_(alpha mu) zws_(\, nu beta) = 1 / 2 eta zws^(alpha beta) h zws_(alpha beta) zws_(\, mu nu) \, $

and $ eta zws^(alpha beta) h zws_(beta nu) zws_(\, mu alpha) = 1 / 2 h zws_(alpha beta) zws_(\, mu nu) . $

With these two relations the expression for the linearized Ricci tensor #ref(<eq-Ricciweak>) simplifies to $ R^(\( 1 \)) zws_(mu nu) = 1 / 2 eta zws^(alpha beta) h zws_(mu nu) zws_(\, alpha beta) = 1 / 2 square.stroked_(S R) h zws_(mu nu) . $ <eq-Ricciweak2>

Where we have defined the #acr("sr", form: "full") D'Alembertian differential operator as: $square.stroked_(S R) = eta zws^(mu nu) partial_mu partial_nu$ We can plug #ref(<eq-Ricciweak2>) into #ref(<eq-EFEwoR>), with $Lambda = 0$ and up to first order in $h zws_(mu nu)$, we get the linearized Einstein field equations for a system of harmonic coordinates:

$ square.stroked.tiny_(S R) h zws_(mu nu) = - 16 pi G overbracket(\( T zws_(mu nu) - frac(eta zws_(mu nu), 2) T_(alpha)^alpha \), S zws_(mu nu)) \, $ <eq-linearized> $ h_(mu)^alpha zws_(\, alpha) = 1 / 2 h_(alpha)^alpha zws_(\, mu) . $ <eq-dedonder> Recall raising and lowering indices is done with the Minkowski metric. The tensor $S zws_(mu nu)$ encodes the behavior of the source of #acr("gw", plural: true). One could also plug #ref(<eq-Ricciweak2>) into #ref(<eq-EFE>), with $Lambda = 0$, and express it in terms of the trace reversed perturbation: $macron(h) zws_(mu nu) = h zws_(mu nu) - 1 / 2 h_(alpha)^alpha eta zws_(mu nu)$. Then, we obtain similar and simpler equations at the cost of a more complex perturbation: #footnote[Note that the inverse change of variables is just: $h zws_(mu nu) = macron(h) zws_(mu nu) - 1 / 2 macron(h)_(alpha)^alpha eta zws_(mu nu)$.] #footnote[We eliminate the trace of the stress-energy tensor by using: $R = 8 pi G T_(alpha)^alpha$. We can write $R^(\( 1 \)) = - 1 / 2 square.stroked_(S R) macron(h)_(alpha)^alpha$, in de Donder gauge, which is precisely the extra term dropping out of $square.stroked_(S R) h zws_(mu nu)$when we express it in terms of$macron(h) zws_(mu nu)$.]

$ square.stroked.tiny_(S R) macron(h) zws_(mu nu) = - 16 pi G T zws_(mu nu) $ <eq-linearizedTR> $ macron(h) zws_(mu nu) zws^(\, nu) = 0 . $ <eq-dedonderTR>

We can easily recover the conservation equation for the stress-energy tensor. We take the divergence of #ref(<eq-linearizedTR>) and use #ref(<eq-dedonderTR>) to get:

$ T zws_(mu nu) zws^(\, nu) = 0 . $ <eq-SEcons>

Let us look at what sorts of solutions come out of these

= Homogeneous solutions
The first step is to consider the homogeneous solution, as all solutions will involve these terms. Setting $T zws_(mu nu) = 0$ or $S zws_(mu nu) = 0$ yields the wave equation in the absence of sources, $ square.stroked_(S R) h zws_(mu nu) = 0 . $ <eq-homogenous>

The De-Donder gauge (#ref(<eq-dedonder>)) and the remaining gauge freedom #footnote[Associated to changes in coordinates of the form $x zws^mu arrow.r x zws^mu + xi zws^mu$with$square.stroked_(S R) xi zws^mu = 0$.] restricts the possible forms of this solution to having only helicity $plus.minus 2$ physically significant components (see #cite(<Weinberg:1972>, form: "prose")). Let us look at generic forms of the solution. The metric $h zws_(mu nu)$ ought to be real-valued, thus we seek real solutions of the form

$ h zws_(mu nu) = epsilon zws_(mu nu) upright(e)^(circle(dotless.i) k dot.op x) + epsilon zws^(*) zws_(mu nu) upright(e)^(- circle(dotless.i) k dot.op x) \, $ <eq-solutiongeneric>

where $epsilon zws_(mu nu)$ is the polarization tensor, $k$ is the wave vector and we define: $k dot.op x equiv eta zws_(mu nu) k zws^mu k zws^nu = k zws_mu x zws^mu$. The polarization tensor is a symmetric rank-2 tensor, since $h zws_(mu nu)$ is. Substituting #ref(<eq-solutiongeneric>) into $square.stroked_(S R) h zws_(mu nu) = 0$ gives $k zws_mu k zws^mu equiv k^2 = 0$.#footnote[Assuming non-zero perturbation $h zws_(mu nu)$ of course.] #footnote[This is saying that the wavevector for the wave is null, thus that the wave propagates at the speed of light.] From #ref(<eq-dedonder>) we have $ epsilon_(nu)^mu k zws_mu = 1 / 2 epsilon_(alpha)^alpha k_nu . $ <eq-polk> As said at the beginning of this subsection, we still have some remaining gauge freedom, which we now fix, choosing the following coordinate change $x zws^mu arrow.r x zws^mu + zeta zws^mu$ where: $ zeta zws^mu = circle(dotless.i) A zws^mu upright(e)^(circle(dotless.i) k dot.op x) = - circle(dotless.i) A zws^(*) zws^mu upright(e)^(- circle(dotless.i) k dot.op x) $

In the new coordinates, the tensor perturbation takes the form:

$ h'_(mu nu) = h zws_(mu nu) - frac(partial_()^() zeta zws_mu, partial_() x zws^nu^()) - frac(partial_()^() zeta zws_nu, partial_() x zws^mu^()) = epsilon'_(mu nu) upright(e)^(circle(dotless.i) k dot.op x) + epsilon^(' *) zws_(mu nu) upright(e)^(- circle(dotless.i) k dot.op x) . $

with

$ epsilon'_(mu nu) = epsilon zws_(mu nu) + k zws_mu A zws_nu + k zws_nu A zws_mu $ <eq-polTprime>

Equations (#ref(<eq-polk>, supplement: none)) and (#ref(<eq-polTprime>, supplement: none)) reduce the free components in the polarisation tensor to just two. Additionally, these equations conspire to yield a traceless polarisation tensor $epsilon_(alpha)^alpha = 0$, with $epsilon zws_(0 mu) = 0$ (see #cite(<Carroll:2019>, form: "prose")). This in turn implies that the metric perturbation itself is traceless, and thus becomes equal to its trace-reversed counterpart. This is the so-called transverse traceless gauge:

$ h zws_(0 mu) = 0 \, quad h_(alpha)^alpha = 0 \, quad h zws_(mu nu) zws^(\, nu) = 0 . $

The metric perturbation in this gauge is written as: $h^(T T) zws_(i j)$. In emtpy space we can write the two independent components of the metric perturbation as:

$ h^(T T) zws_(a b) \( t \, upright(bold(x))_() \) = mat(delim: "(", h_(+), h_times; h_times, - h_(+))_(a b) cos \[ omega t - upright(bold(k))_() dot.op upright(bold(x))_() \] \, $

where $h_(+)$ and $h_times$ are the so-called plus and cross polarisations.

= Inhomogeneous solutions
With the homogeneous part of #ref(<eq-linearized>) accounted for, we are now ready to derive the inhomogeneous part. The solution of #ref(<eq-linearized>) in the presence of a source term will be heavily inspired by the analogous problem in electromagnetism, where one learns that any linear differential equation:

$ cal(hat(L)) phi.alt = J $

is solved using green's functions. If we define the following retarded Green's function

$ cal(G)_(upright(r e t)) \( x zws^mu - x' zws^mu \) = - 2 pi thin delta^() \( \( x - x' \)^2 \) Theta^() \( t > t' \) \, $

which satisfies,

$ square.stroked_(S R) cal(G)_(upright(r e t)) \( x zws^mu - x' zws^mu \) = - 2 pi delta^4 \( x zws^mu - x' zws^mu \) . $

Then, the solution to

$ square.stroked_(S R) h zws_(mu nu) = - 16 pi G S zws_(mu nu) $ <eq-EFEwave>

is given by

$ h zws_(mu nu) \( x \) = 8 G integral thin upright(d)^4 x' thin thin cal(G)_(upright(r e t)) \( x zws^mu - x' zws^mu \) S zws_(mu nu) \( x' \) . $ <eq-hsolInhom>#footnote[One gets the parallel solution to the trace reversed equation #ref(<eq-linearizedTR>) by swapping $S$with$T$and all$h$with$macron(h)$.]

Indeed, plugging in #ref(<eq-hsolInhom>) into #ref(<eq-EFEwave>), $ square.stroked_x h zws_(mu nu) = 8 G integral thin upright(d)^4 x' thin \( \( underbrace(square.stroked_x cal(G)_(upright(r e t)) \( x zws^mu - x' zws^mu \), = - 2 pi thin delta^() \( x zws^mu - x' zws^mu \)) \) S zws_(mu nu) \( x' \) = - 16 pi G S zws_(mu nu) \( x \) . $ We can perform the $x^(' 0) = t'$ integration in #ref(<eq-hsolInhom>), with the Dirac delta function, which sets $t'$ to be the retarded time, $t' = t - \| x zws^mu - x' zws^mu \| = t_r$, i.e: $ h zws_(mu nu) \( x \) = 8 G integral thin upright(d)^3 upright(bold(y))_() thin S zws_(mu nu) \( t \, upright(bold(y))_() \) thin upright(d)^() t' thin frac(delta \( t' - \( t - \| upright(bold(x))_() - upright(bold(y))_() \| \) \), 2 \| upright(bold(x))_() - upright(bold(y))_() \|) $

$ h zws_(mu nu) \( upright(bold(x))_() \, t \) = 4 G integral thin upright(d)^3 upright(bold(y))_() thin frac(S zws_(mu nu) \( t - \| upright(bold(x))_() - upright(bold(y))_() \| \, upright(bold(y))_() \), \| upright(bold(x))_() - upright(bold(y))_() \|) . $ <eq-solInhomt>

We can interpret $h zws_(mu nu) \( upright(bold(x))_() \, t \)$, as the perturbation obtained by summing up all the radiation from point-sources located at $\( upright(bold(x))_() - upright(bold(y))_() \, t_r \)$ on the past light cone. Put differently $h zws_(mu nu) \( upright(bold(x))_() \, t \)$ is the gravitational radiation produced by the source $S zws_(mu nu)$. Additionally, the form of the time argument of the source tensor, imposed by the definition of the Green's function, shows that the radiation propagates with velocity $= 1 = c$. The solution given by #ref(<eq-solInhomt>) satisfies the harmonic coordinate condition of #ref(<eq-linearized>), since

$ T zws_(mu nu) zws_(; mu) = 0 med arrow.r.double med T zws_(mu nu) zws_(\, mu) + underbrace(Gamma thin Gamma thin, upright(n o n - l i n e a r)) = 0 med arrow.r.double med T zws_(mu nu) zws_(\, mu) = 0 \, $

where we have ignored the non-linear terms encoded in the Levi-Civita connections. Then,

$ S zws^(mu nu) zws_(\, mu) = partial_mu (T zws_(mu nu) - frac(eta zws^(mu nu), 2) T_(alpha)^alpha) = - frac(eta zws^(mu nu), 2) T_(alpha)^alpha zws_(\, mu) . $

Also

$ S_(mu)^mu = T_(mu)^mu - delta_mu^mu / 2 T_(alpha)^alpha = - T_(alpha)^alpha . $

Thus

$ S zws^(mu nu) zws_(\, mu) & = 1 / 2 S_(alpha)^alpha zws_(\, mu) eta zws^(mu nu)\
S_(nu)^mu zws_(\, mu) & = 1 / 2 S_(alpha)^alpha zws_(\, nu) . $

Then

$ h_(nu)^mu zws_(\, mu) & = 8 G frac(partial_()^(), partial_() x zws^mu^()) integral thin upright(d)^4 x' thin cal(G)_(upright(r e t)) \( x zws^mu - x' zws^mu \) S_(nu)^mu \( x' \)\
 & = 8 G integral thin upright(d)^4 x' thin thin frac(partial_()^() cal(G)_(upright(r e t)) \( x zws^mu - x' zws^mu \), partial_() x zws^mu^()) S_(nu)^mu \( x' \)\
 & = - 8 G integral thin upright(d)^4 x' thin frac(partial_()^() cal(G)_(upright(r e t)) \( x zws^mu - x' zws^mu \), partial_() x' zws^mu^()) S_(nu)^mu \( x' \)\
 & = underbrace(8 G cal(G)_(upright(r e t)) \( x zws^mu - x' zws^mu \) S_(nu)^mu \( x' \), = 0 med upright(a t t h e b o u n d a r y)) + 8 G integral thin upright(d)^4 x' thin thin cal(G)_(upright(r e t)) \( x zws^mu - x' zws^mu \) frac(partial_()^() S_(nu)^mu \( x' \), partial_() x' zws^mu^())\
 & = 8 G integral thin upright(d)^4 x' thin thin cal(G)_(upright(r e t)) \( x zws^mu - x' zws^mu \) 1 / 2 frac(partial_()^() S_(alpha)^alpha \( x' \), partial_() x' zws^mu^())\
 & = quad dots.h quad upright("repeat in reverse")\
 & = frac(partial_()^(), partial_() x zws^mu^()) \{ 8 G integral thin upright(d)^4 x' thin thin cal(G)_(upright(r e t)) \( x zws^mu - x' zws^mu \) 1 / 2 S_(alpha)^alpha \( x' \) \}\
 & = 1 / 2 h_(alpha)^alpha zws_(\, mu) . checkmark $

= Gravitational Wave Sources
Now that we have the general form of the solutions to the linearized Einstein equations, we can proceed to the analysis of sources of #acr("gw", plural: true). The first step is to analyse the equations in the frequency domain. We will use the following notation:

$ cal(F)_t [phi.alt] \( omega \, upright(bold(x))_() \) = integral thin upright(d)^() t thin phi.alt \( t \, upright(bold(x))_() \) upright(e)^(circle(dotless.i) omega t) $ $ cal(F)_omega^(- 1) [phi.alt] \( t \, upright(bold(x))_() \) = integral frac(thin upright(d)^() omega thin, 2 pi) cal(F)_t [phi.alt] \( omega \, upright(bold(x))_() \) upright(e)^(- circle(dotless.i) omega t) $

Let us look at frequency domain of the solution given in #ref(<eq-solInhomt>). We have $ cal(F)_t [h zws_(mu nu)] \( omega \, upright(bold(x))_() \) & = integral thin upright(d)^() t thin h zws_(mu nu) \( t \, upright(bold(x))_() \) upright(e)^(circle(dotless.i) omega t)\
 & = 4 G integral thin upright(d)^3 upright(bold(y))_() thin thin upright(d)^() t thin frac(S zws_(mu nu) \( t - \| upright(bold(x))_() - upright(bold(y))_() \| \, upright(bold(y))_() \), \| upright(bold(x))_() - upright(bold(y))_() \|) upright(e)^(circle(dotless.i) omega t)\
 & = 4 G integral thin upright(d)^3 upright(bold(y))_() thin thin upright(d)^() t_r thin frac(S zws_(mu nu) \( t_r \, upright(bold(y))_() \), \| upright(bold(x))_() - upright(bold(y))_() \|) upright(e)^(circle(dotless.i) omega t_r) upright(e)^(circle(dotless.i) omega \| upright(bold(x))_() - upright(bold(y))_() \|)\
 & = 4 G integral thin upright(d)^3 upright(bold(y))_() thin frac(cal(F)_(t_r) [S zws_(mu nu)] \( omega \, upright(bold(y))_() \), \| upright(bold(x))_() - upright(bold(y))_() \|) upright(e)^(circle(dotless.i) omega \| upright(bold(x))_() - upright(bold(y))_() \|) . $ <eq-FTweakmet>

We can now apply various approximations to this form of the perturbation:

+ Consider a compact source, centered on the origin of our coordinate system. This implies that $S zws_(mu nu)$ is peaked and compactly supported in a region around the origin. We look at the radiation only in the so called #emph[wave zone], at a distance $r = \| upright(bold(x))_() \|$ much larger than the dimensions of the source $R = \| upright(bold(y))_() \|_(upright("max"))$.
+ We assume that $r gt.double 1 / omega$, i.e long wavelengths don't dominate.
+ We assume that $r gt.double omega R^2$, i.e.~the ratio of $R$ to the wavelength is not comparable to the ratio of $r$ to $R$. Using this approximation we can write:

$ \| upright(bold(x))_() - upright(bold(y))_() \| & = r (1 - 2 hat(upright(bold(x))_()) dot.op upright(bold(y))_() + upright(bold(x))_()^(' 2) / r^2)^(1 \/ 2) \,\
\| upright(bold(x))_() - upright(bold(y))_() \| & approx r (1 - frac(hat(upright(bold(x))_()) dot.op upright(bold(y))_(), r)) quad upright("with: ") hat(upright(bold(x))_()) = upright(bold(x))_() / r . $

If we additionally further separate the scales in the following way #footnote[We just add the condition that $1 / omega gt.double R$, that is the source radius is much smaller than the wavelength.]

$ r gt.double \[ 1 / omega \, omega R^2 \] gt.double R \, $

Then #ref(<eq-FTweakmet>) becomes much simpler#footnote[The approximations all conspire to be able to neglect the $upright(bold(y))_()$dependence of$frac(upright(e)^(circle(dotless.i) omega \| upright(bold(x))_() - upright(bold(y))_() \|), \| x - y \|)$ in the integral.]:

$ cal(F)_t [h zws_(mu nu)] \( omega \, upright(bold(x))_() \) = 4 G upright(e)^(circle(dotless.i) omega r) / r integral thin upright(d)^3 upright(bold(y))_() thin cal(F)_t [S zws_(mu nu)] \( omega \, upright(bold(y))_() \) . $ <eq-FTweakmet2>

Now, let us look at the Fourier transform of the source term. By definition, we have

$ cal(F)_t [S zws_(mu nu)] \( omega \, upright(bold(y))_() \) = cal(F)_t [T zws_(mu nu)] \( omega \, upright(bold(y))_() \) + 1 / 2 eta zws_(mu nu) cal(F)_t [T_(alpha)^alpha] \( omega \, upright(bold(y))_() \) $

Thus, we can study the Fourier transform of $T zws_(mu nu)$, $cal(F)_t [T zws_(mu nu)]$ instead. Using the conservation equation #ref(<eq-SEcons>) in Fourier $t$-space, we obtain:

$ - cal(F)_t [T zws_(i mu)] zws^(\, i) = circle(dotless.i) omega cal(F)_t [T zws_(0 mu)] $ <eq-FTSEcons>

This equation becomes algebraic when we further Fourier transform in $upright(bold(x))_()$-space:

$ hat(T)_(mu nu) \( k zws^alpha \) = hat(T)_(mu nu) \( omega \, upright(bold(k))_() \) = integral thin upright(d)^3 upright(bold(y))_() thin cal(F)_t [T zws_(mu nu)] \( omega \, upright(bold(y))_() \) upright(e)^(circle(dotless.i) upright(bold(k))_() dot.op upright(bold(y))_()) $ Then the conservation equation becomes: $ k zws^mu T zws_(mu nu) \( omega \, upright(bold(k))_() \) = 0 $

These four equations relate the time components of $hat(T)_(mu nu)$ to the spatial ones. We now apply #ref(<eq-FTSEcons>) to itself to obtain:

$ cal(F)_t [T zws_(i j)] zws^(\, i j) = - omega^2 cal(F)_t [T zws_00] $ which, when multiplied by $x zws_m x zws_n$, and integrated over $upright(bold(x))_()$ gives#footnote[Two integrations by parts cancel the $x zws_m x zws_n$term in the #acr("lhs") and since boundary terms are 0 (the source is finite) we have$ integral thin upright(d)^() x thin x zws_m x zws_n cal(F)_t [T zws_(i j)] zws^(\, i j) = integral thin upright(d)^() x thin x zws_m x zws_n zws^(\, i j) cal(F)_t [T zws_(i j)] $The hessian of$x zws_m x zws_n$is$\( delta_m^i + delta_n^i \) \( delta_n^j + delta_m^j \)$, but since $T zws_(mu nu)$is symmetric the integral is$ integral thin upright(d)^() upright(bold(y))_() thin 2 cal(F)_t [T zws_(m n)] \( omega \, upright(bold(y))_() \) $] $ integral thin upright(d)^() upright(bold(x))_() thin cal(F)_t [T zws_(m n)] \( omega \, upright(bold(x))_() \) = - omega^2 / 2 integral thin upright(d)^() upright(bold(x))_() thin x zws_m x zws_n cal(F)_t [T zws_00] \( omega \, upright(bold(x))_() \) . $

Notice that the integral on the #acr("rhs") is in fact the Fourier transform of the quadrupole moment tensor of the energy density:

$ I_(m n) = integral x zws_m x zws_n T zws_00 \( t \, upright(bold(x))_() \) thin upright(d)^3 x thin . $ <eq-quadmom>

We call its Fourier transform $hat(I_())_(m n) \( omega \)$ and we can finally rewrite #ref(<eq-FTweakmet2>) as:

$ cal(F)_t [h zws_(mu nu)] \( omega \, upright(bold(x))_() \) = - 2 G omega^2 upright(e)^(circle(dotless.i) omega r) / r \( hat(I_())_(m n) \( omega \) + 1 / 2 eta zws_(mu nu) hat(I_())^n zws_n \( omega \) \) $

Going back $t$-space we have:

$ h zws_(mu nu) \( t \, upright(bold(x))_() \) & = - frac(G, pi r) integral thin upright(d)^() omega thin upright(e)^(- circle(dotless.i) omega \( t - r \)) omega^2 \( hat(I_())_(m n) \( omega \) + 1 / 2 eta zws_(mu nu) hat(I_())^n zws_n \( omega \) \)\
 & = frac(G, pi r) frac(upright(d)^2, upright(d) t^2) integral thin upright(d)^() omega thin upright(e)^(- circle(dotless.i) omega \( t_r \)) \( hat(I_())_(m n) \( omega \) + 1 / 2 eta zws_(mu nu) hat(I_())^n zws_n \( omega \) \)\
 & = frac(2 G, r) frac(upright(d)^2, upright(d) t^2) \( I_(m n) \( t_r \) + 1 / 2 eta zws_(mu nu) I_()^n zws_n \( t_r \) \) $ <eq-metricquadmom>

This equation has a nice physical interpretation. The gravitational wave produced by a non-relativistic source is proportional to the second derivative of the quadrupole moment of the energy density at the time $t_r$ where the past light cone of the observer intersects the source. The nature of gravitational radiation is in stark contrast to the leading electromagnetic contribution which is due the change in the #emph[dipole] moment of the charge density. The change of the dipole moment can be attributed to the change in center of charge (for #acr("em", form: "full")), or mass (for #acr("gr")). While a center of charge is free to move around, the center of mass (of an isolated source) is fixed by the conservation of momentum, so the dipole moment is zero.

The quadrupole moment, on the other hand, is sensitive to the shape of the source, which a gravitational system can modify. We observe that the quadrupole radiation is sub-leading when compared to dipole radiation. Thus, on top of the much smaller coupling constant, gravitational radiation is also weakened by this fact, and thus is usually orders of magnitude weaker than electromagnetic radiation.

In summary, any object that is modifying its shape is a source of #acr("gw", plural: true). All orbiting systems therefore are sources of #acr("gw", plural: true) . However, as outlined above, only significant 'changes in shape' have a chance to be detectable. We will now explore these phenomena.

== Compact binaries
<sec-compactbinaries>
How could one construct a very powerful source of #acr("gw", plural: true) ? An example would be that of two highly-massive bodies (such that $T zws_00$ is large) that orbit each other. Furthermore, in order for the #acr("gw", plural: true) emitted by the system to be detectable they must orbit close enough to each other that their quadrupole moment is large. For these very massive objects to be close enough for a small orbit, they have to be very compact. Assuming that is the case, a funny thing happens, as these objects orbit each other, they emit #acr("gw", plural: true) , and in doing so they lose energy #footnote[Of course this happens in every orbiting system just on a timescale that is negligible. Only systems which are massive enough to produce large amounts of radiation actually lose enough energy for it to matter.]. Thus, they slow down, and their orbit shrinks. This continues until the orbit is so small that the objects merge into a single object. Of course this is a significant change of shape, and thus we have a constructed (if not all on purpose) a very powerful source of #acr("gw", plural: true) . Such objects are called compact binaries.

Let us consider two massive bodies orbiting each other. The mass of each body is $m_1$ and $m_2$ respectively. The distance to the observer is $r$ and the separation between the object is given by $R$. The setup is shown in #ref(<fig-compact-binaries>)

#figure(timg("compact-binaries.webp"),
  caption: [
    Compact binary setup
  ]
)
<fig-compact-binaries>

To #acr("lo", form: "full") in $G$ the motion of the binary is described by a Newtonian circular orbit. In barycentric coordinates, such a system is in fact equivalent to effective one body #footnote[This choice of wording is not a coincidence as we shall see] of reduced mass $mu = frac(m_1 m_2, M)$ orbiting in a gravitational potential of mass $M = m_1 + m_2$, at a distance $R$ equal to the distance between the two bodies forming the binary. The orbit is characterized by a balancing act between the gravitational attraction due to the potential and the centripetal force due to the motion of the reduced mass:#footnote[Or equivalently between conserved angular momentum and the derivative of the potential energy.]

$ frac(G M mu, \( R \)^2) = frac(mu u_()^2, R) \, $ <eq-newtongrav>

where $u_()$ is the norm of tangential velocity, and $R$ is the distance between the two objects. #ref(<eq-newtongrav>) gives us the the norm of the velocity

$ u_() = sqrt(frac(G M, R)) . $

Thus, the orbital period is simply, in the case of

$ T = frac(2 pi R, u_()) = 2 pi sqrt(frac(R^3, G M)) . $

This also gives us angular frequency:

$ Omega = frac(2 pi, T) = sqrt(frac(G M, R^3)) . $ <eq-omega>

Thus the #acr("eom") $upright(bold(r))_() \( t \)$ of the reduced mass is described by a circular orbit in the $x - y$ plane i.e.:

$ upright(bold(r))_(x y) \( t \) = vec(R cos \( Omega t \), R sin \( Omega t \)) . $ <eq-eomred>

We have not written the third $z$ component of the trajectory as that can be set to zero, for a well-chosen set of inertial coordinates. The corresponding trajectory for both masses is simply given by applying the following scaling:

$ mu upright(bold(r))_() \( t \) = m_1 upright(bold(r))_1 \( t \) = m_2 upright(bold(r))_2 \( t \) . $

We can straightforwardly obtain the $00$ component of the energy-momentum tensor of the system #footnote[The energy density is the same for the effective one body system and the two body system.] by using the #acr("eom") of the reduced mass (#ref(<eq-eomred>)):

$ T zws_00 \( t \, upright(bold(x))_() \) = mu delta^() \( x_3 \) delta^() \( x_1 - R cos \( Omega t \) \) delta^() \( x_2 - R sin \( Omega t \) \) \, $

which when plugged into #ref(<eq-quadmom>), gives us the quadrupole moment of the rotating system:

$ I_11 & = mu R^2 cos^2 \( Omega t \) = mu R^2 \( 1 + cos \( 2 Omega t \) \)\
I_22 & = mu R^2 sin^2 \( Omega t \) = mu R^2 \( 1 - cos \( 2 Omega t \) \)\
I_12 = I_21 & = 2 mu R^2 \( cos Omega t \) \( sin Omega t \) = mu R^2 sin \( 2 Omega t \)\
I_(i 3) & = 0 . $

Thus, we have roughly:

$ I_() tilde.op mu R^2 cos \( 2 Omega t \) tilde.op mu R^2 tilde.op mu \( frac(G M, Omega^2) \)^(2 / 3) = frac(G m_1 m_2, \( m_1 + m_2 \)^(1 / 3)) Omega^(- 4 / 3) \, $

where we have expanded in small $R$ in the second relation. The metric perturbation is then given by #ref(<eq-metricquadmom>) and has norm proportional to:

$ h prop dot.double(I_()) / r prop 1 / r frac(G m_1 m_2, \( m_1 + m_2 \)^(1 / 3)) Omega^(2 / 3) . $ <eq-hnorm>

== #acr("bh", form: "long") Binaries
Taking the process described above to the limit of more massive and more compact objects one could imagine asking for the most dense objects possible to orbit each other. In #acr("gr") this object is called a black hole (#acr("bh", form: "full")). It is a possible solution to the full fat #acr("efe") (#ref(<eq-EFE>)), in a static and isotropic universe, with point like mass at its center. Then the solutions to the equations #ref(<eq-EFE>) have a unique form @Birkhoff:1923, called the Schwarzschild solution.

The solution is given by, in spherical coordinates:

$ thin upright(d)^() tau^2 thin = [1 - R_S / r] thin upright(d)^() t^2 thin - frac(thin upright(d)^() r^2 thin, 1 - R_S / r) - r^2 (thin upright(d)^() theta^2 thin + sin^2 theta thin upright(d)^() phi^2 thin) $ <eq-Schwarzschild>

where $R_S$ is the Schwarzschild radius, given by:#footnote[we reinstate the speed of light, as we want to compute orders of magnitudes]

$ R_S = frac(2 G M, c^2) . $

For stellar masses we have $R_S = 2954 #h(0em) upright(m)$, quite a lot smaller than the radius of the sun $tilde.op 7 dot.op 10^8 #h(0em) upright(m)$. Note that the metric given in #ref(<eq-Schwarzschild>) exhibits singularities at both $r = R_S$ and $r = 0$. The former is spurious, as it is an artefact of the coordinate choice, while the latter is real, in the sense that coordinate independent scalars formed from the metric (such as the ricci scalar) do in fact blow up as $r arrow.r 0$. This encodes the non-spurious mass singularity that gives rise to the #acr("bh") phenomena.

If we consider a comparable stellar mass #acr("bbh", form: "full") system, we can use the calculations of the previous section to compute the order of magnitude of the perturbation. #ref(<eq-omega>) in terms of the Schwarzschild radius gives us the orbital frequency

$ f = frac(Omega, 2 pi) = frac(c, 2 pi) sqrt(R_S / R^3) \, $

and the metric perturbation is given by #ref(<eq-hnorm>):

$ h = R_S^2 / R . $

Thus, if we consider #acr("bh", plural: true) separated by ten times their Schwarzschild radius, observed at cosmological distances $tilde.op 100 #h(0em) upright(M p c)$, we obtain the values for the scales characterizing the binary system:

$ R_S & approx 10^3 #h(0em) upright(m) \,\
R & approx 10^4 #h(0em) upright(m) \,\
r & approx 10^23 #h(0em) upright(m) . $

Such a system would have an orbital frequency of:

$ f approx 10^2 #h(0em) upright(H z) \, $

and would perturb the metric on earth by:

$ h approx 10^(- 21) . $

To have any hope of detecting such systems, one would need to have detectors sensitive to frequency spectra up to hundreds of Hertz, with a strain sensitivity of $10^(- 21)$. This has been achieved at #acr("ligo", form: "full") and other detectors, and has enabled the detection of such systems.

Non-spinning black holes orbiting around each other are the simplest binary system to model. However, they are extremely unlikely to occur in nature (realistic physical scenarios). The nature of #acr("bh") formation implies that they necessarily also spin. Spinning black holes, also referred to as Kerr black holes, are characterized by a different metric tensor defining the spacetime surrounding them. The modelling of spinning black holes is still in its infancy and will not be treated it here.

There are many other binary systems that could feasibly be detected. Finite-size binaries such as #acr("ns", form: "full", plural: true) result in tidal phenomena that are not present in the #acr("bh") case. Also, non-binary systems, such as Cosmic strings, corresponding to early universe topological defects, could produce a detectable stochastic #acr("gw") background.
