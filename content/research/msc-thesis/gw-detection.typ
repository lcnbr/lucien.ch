#import "/lib/thesis.typ": chapter, acr, timg, subfigs, xref
#import "/lib/links.typ": n
#import "/lib/figures.typ": svg-math

#show: chapter.with(thesis: "msc-thesis", number: 3, summary: "Laser interferometers, matched filtering and pulsar timing arrays.")

Gravitational waves were first theorized by Einstein, accompanying his theory of general relativity. However, at the time it was not even clear whether they were an artifact of the theory or an observable phenomenon. Of course, as we have seen, #acr("gw", form: "full", plural: true) are predicted to be extremely weak, and thus there was initially little hope of ever detecting them. As evidence mounted that #acr("gr", form: "full") was indeed an incredibly accurate theory of gravity, the interest in #acr("gw") detection grew. The first detectors, resonant antennas, failed in successfully detecting #acr("gw", plural: true), as they were simply not sensitive enough. The more modern laser based detectors were the finally able to claim detection, by being extremely sensitive (the modern measurement precision at #acr("ligo", form: "full") is equivalent to measuring the distance to Alpha Centauri 4.367 light-years, to the width of a human hair $tilde.op 40 med upright(µ m)$). The first detection was made in 2015 @LIGOScientific:2016aoc, marking the beginning of a new era in astronomy, and maybe even physics itself.

= Laser interferometers
Laser-interferometer-based #acr("gw") detectors are essentially scaled-up versions of the Michelson interferometer. The device, shown in #ref(<fig-interfertrans>), splits a beam of colimated coherent photons (laser) into two, letting them propagate along two axes in an L configuration, before being reflected back to the beam splitter. The two beams, when recombined, interfere with each other, constructively or destructively, depending on the nature of the medium they have traveled through and the length of each arm.

#figure(timg("interfertrans.png"),
  caption: [
    Principles of laser interferometer #acr("gw") detectors
  ]
)
<fig-interfertrans>

For a gravitational wave to produce a measurable effect on such an apparatus, all the optical equipment should be free to move and be isolated from external vibrations. This is achieved by hanging the mirror on precisely-tuned penduli. When the gravitational wave propagates through the apparatus, it induces a relative movement between the masses, changing the difference $L_x - L_y$ in length of the detectors arms, by an amount $Delta L$. This effect is exacerbated as the length of the arms $L_x tilde.op L_y tilde.op L$ is increased. It follows that the strain is the normalized difference:

$ frac(Delta L, L) = [\( 1 \/ 2 \) (1 + cos^2 \( theta \)) cos \( 2 phi.alt \)] h_(+) + \[ cos \( theta \) sin \( 2 phi.alt \) \] h_times equiv h \, $

where $theta$ and $phi.alt$ are the polar and azimuthal angles of the direction of propagation of the #acr("gw") . The strain is decomposed into components, $h_(+)$ and $h_times$, which are the plus and cross polarisations of the wave. The strain sensitivity can be further increased by bouncing the light back and forth multiple times along the arms of the interferometer. In current implementations this is achieved using Fabry - Perot cavities spanning the whole length of the arms.

== #acr("ligo", form: "long") and ground based observatories
<sec-ligo>
#acr("ligo") implements the measurement apparatus described in the past section, and a schematic is shown in #ref(<fig-ligo>). It consists of two detectors, both in the USA, one in Livingston Louisiana and one in Hanford Washington, a separation of $3000 upright(" km")$. Each #acr("ligo") detector has two $4 upright(" km")$ long arms made up of $1.2 upright(" m")$-wide vacuum tubes, each operating as Fabry-Perot cavities. The light from an effective $750 upright(" kW")$ laser bounces back and forth inside these arms around 300 times. Thus, the effective arm length becomes $1200 upright(" km")$, drastically improving sensitivity.

#figure(timg("ligoconcepttrans.png"),
  caption: [
    Schematic of #acr("ligo") detector
  ]
)
<fig-ligo>

While #acr("ligo") was the first to provide detection data, it does not live in a vacuum. In fact for the first published detection, the data analysis teams from #acr("ligo") joined forces with those for Virgo, the European gravitational wave detector. The Virgo detector is located in Cascina, Italy, and is similar to #acr("ligo") . It has $3 upright(" km")$ long arms and a different suspension system. It joined data collection with #acr("ligo") in the second observing run in 2017. Finally, there are two other detectors that are now part of the collaboration, KAGRA in Japan and GEO600 in Germany. KAGRA is a similar detector to Virgo in scale, but is built underground further isolating it from seismic activity .GEO600 is a smaller detector, with $600 upright(" m")$ long arms, built with the objective of being a test bed for future detectors.

Although they exhibit impressive sensitivity, ground based detectors are limited, since they are subject to seismic activity, which can cause vibrations that limits the lower bound of the frequency sensitivity of the detectors. The optics and other higher frequency noise imposes an upper bound to the frequency. In particular ground based detectors are only sensitive to frequencies in the following rough range:

$ \[ 10^0 \, 10^4 \] upright(" Hz") . $

In turn this implies that they are sensitive to the comparable, stellar mass #footnote[and a bit bigger $tilde.op 1 - 10^3 M_dot.o$] compact binaries, which are currently believed to be the most common type of binary systems in the universe. Of course this is not an accident, as these detectors were purpose built for providing evidence of #acr("gw") in general. In fact, they have been quite successful in this regard, with upwards of 90 detections of #acr("gw") to date.

#figure(timg("masses-of-dead-stars-ligo-virgo-kagra.png"),
  caption: [
    Mass distribution of Detected #acr("gw") emiting binaries. Credit: Visualization: LIGO-Virgo-KAGRA / Aaron Geller / Northwestern
  ]
)
<fig-masses>

#ref(<fig-masses>) shows the current library of compact binary systems detected by #acr("ligo") -Virg-Kagra, along with those detected through non-#acr("gw") means. The highlighted band denotes the assumed mass gap that should exist between the neutron star and black hole mass distributions. Note that most of the detections are compatible with the presence of such a gap. However, there are a few detections that are not, and these are particularly interesting. These are binaries with masses too light to be black holes, but too heavy to be neutron stars. A lot of research is ongoing to try and understand what these objects are, and if they are not just measurement artefacts.

== #acr("lisa", form: "long")
There are many planned next generation #acr("gw") detectors, from the Einstein telescope to Cosmic explorer. The most interesting one however is #acr("lisa", form: "full"), the first genuine space based #acr("gw") observatory. It is a joint project between ESA and NASA, and is scheduled to launch in 2037. In #ref(<fig-lisa>) we see it will consist of three satellites, in triangular formation, at a distance of 2.5 million kilometers of each other. Each of the three #acr("lisa") spacecraft contains a test mass free-falling within its body. Each spacecraft then measures the distance to its neighboring test mass thus forming a space based laser interferometer.

#figure(timg("lisatrans.png"),
  caption: [
    Schematic of #acr("lisa") detector
  ]
)
<fig-lisa>

There are a few key differences with ground based detectors. The first is the size of the arms means it will be sensitive to frequency ranges such as:

$ \[ 10^(- 4) \, 10^0 \] upright(" Hz") . $

This means that it will be sensitive to the most massive binaries in the universe, supermassive black holes, such as those found at the centers of galaxies.

The second is that it will be completely isolated from seismic activity, and thus has a much lower noise floor. This combined with the arm length means that #acr("lisa") is also predicted to be able to observe #acr("emri", form: "full", plural: true), where stellar compact objects ($< 60 M_dot.o$) orbit around a massive black hole of around $10^5 M_dot.o$ or more. In this configuration the small mass is in a slowly decaying orbit, and thus can spend around $10^5$ orbits and between a few months and a few years in the LISA sensitivity band before merging. This will provide us with a very interesting new source of #acr("gw") , that also allows us to test new approximations, such as those based on mass ratio expansions: #acr("gsf", form: "full") .

= Matched filtering
The signals measured by the laser interferometers such as #acr("ligo") , provide a measurement of strain over time. This waveform essentially measures the deformation of spacetime when a #acr("gw") passes through a detector. While some #acr("gw") signals observed in laser interferometers are clearly identified as such, mainly due to their extraordinary power output, weaker signals are harder to identify. In fact, most of the detections have happened under the noise floor of the detectors. How is this possible? Matched filtering and waveform generation.

Consider some detector output signal $s$ consisting of noise $n$ and a possible true #acr("gw") signal $h_i$ (or signals, making up a family ${ h_i }$). The nature of the noise is unpredictable and necessarily probabilistic in nature. We can, however, model the noise as a random variable $n$ that follows a probability distribution $P_n$ dependent on variables that we consider and have measured to be significantly impactful.

In such a probabilistic setup one could try to find the probability that the signal $h_i in { h_i }$ has been detected, conditional on the actual data $s$. This however is impractical as it requires #emph[a priori] knowledge on the family of possible signals, information that is inaccessible. Instead, we devise a functional $cal(F) \[ s \, h_i \]$, (a statistic) dependent on both the data and the supposedly present #acr("gw") signal. We can then choose a threshold $rho^(*)$ above which we claim detection of the signal $h_i$, i.e.~if $cal(F) \[ s \, h_i \] > rho^(*)$.

The functional that is used is defined in terms of the symmetric inner product $chevron.l s \, h_i chevron.r$, that correlates the data $s$ with the template $h_i$, weighting by detector frequency sensitivity $S_n \( f \)$:

$ chevron.l g \, h chevron.r = 2 integral_(- oo)^oo frac(hat(g) zws^(*) \( f \) hat(h) \( f \), S_n \( \| f \| \)) thin upright(d)^() f thin = 4 Re integral_0^oo frac(hat(g) zws^(*) \( f \) hat(h) \( f \), S_n \( f \)) thin upright(d)^() f thin \, $

where $hat(g) zws^(*)$ is the conjugate of the frequency Fourier transform of $g$. $S_n \( f \)$ is the #emph[noise power spectral density], characterising the detector sensitivity defined by:

$ macron(hat(n) zws^(*) \( f_1 \) hat(n) \( f_2 \)) = 1 / 2 delta^() \( f_1 - f_2 \) S_n \( f_1 \) Theta^() \( f_1 \) \, $

where the bar denotes the average over the noise realisation, $delta^() \( f_1 - f_2 \)$ is the Dirac delta function, and $Theta^() \( f_1 \)$ is the Heaviside step function. We can now define the #emph[signal to noise ratio] for the signal when filtered by $h_i$ as #footnote[The equality is due to the fact that we average over all realisations of noise, which averages to uniform: $macron(chevron.l h_i \, n chevron.r chevron.l n \, h_i chevron.r) = chevron.l h_i \, h_i chevron.r$.]

$ rho \( s \, h_i \) = frac(chevron.l s \, h_i chevron.r, "rms" chevron.l n \, h_i chevron.r) = frac(chevron.l s \, h_i chevron.r, sqrt(chevron.l h_i \, h_i chevron.r)) . $

where $"rms"$ denotes the root-mean-square. This is the functional $cal(F) \[ s \, h_i \]$ we are after and we claim detection if $rho \( h_i \) > rho^(*)$. The functional $cal(F) \[ s \, h_i \] = rho \( s \, h_i \)$, provided that the noise is normally distributed, is provably the optimal filtering technique, in the sense that it minimizes the probability of false positives. For example, if we have a fully Gaussian noisy signal $s = n$ then $rho$ is a normal variable with zero mean and unit variance. If a signal $h_i$ is present, over some again Gaussian noise $n$, then it can be proven that $rho$ is still normal but centered on $sqrt(chevron.l h_i \, h_i chevron.r)$ with unit variance.

The threshold can be set to correspond to a desired false positive rate $cal(F)$:#footnote[The complementary error function is given by $"erfc" \( z \) = 2 / sqrt(pi) integral_z^oo upright(e)^(- t^2) thin upright(d)^() t thin = 1 - "erf" \( z \) .$]

$ cal(F) = sqrt(frac(1, 2 pi)) integral_(rho^(*))^oo upright(e)^(- 1 / 2 rho^2) thin upright(d)^() rho thin = 1 / 2 "erfc" \( rho^(*) / sqrt(2) \) \, $

or correct detection rate $cal(D)$:

$ cal(D) = 1 / 2 "erfc" \[ frac(rho^(*) - sqrt(chevron.l h_i \, h_i chevron.r), sqrt(2)) \] . $

Given a signal and a template, we have described a procedure to determine if the signal is present or not. The physical output of a detection is therefore bounded from above by the physics content of the template. The matched filtering approach is contingent on having a waveform that corresponds to the physical process that is emitting the signal. Usually, these processes can be parametrized by a set of parameter. In the case of a compact binary these parameters are for example, the mass ratio of the binary, the orbit eccentricity, the possible spin etc. The filter waveform must then naturally depend on these parameters, be it heuristically or physically (i.e., from first principles).

= #acr("pta", form: "long")
A #acr("pta", form: "full") consists of an array of several pulsars whose pulse periods (or #acr("toa", form: "full") ) are monitored with very high precision by one or more radio telescopes. Pulsars, from #strong[pulsa]ting #strong[r]adio source, are though to be highly magnetized rotating neutron stars. These neutron stars emit strong electromagnetic radiation from their magnetic poles, which when not aligned with rotational poles, emit in the manner of a lighthouse. The measured pulses are extremely regular in nature, with periods ranging from a few milliseconds to a few seconds. Over a year, the variation in the pulse period is on the order of a few microseconds @Detweiler:1979wn. We can therefor use pulsars as clocks, and infer their variation from their normal cycle time. This methodology is shown in #ref(<fig-pta>).

#figure(timg("ptatrans.png"),
  caption: [
    How plusar timing arrays work
  ]
)
<fig-pta>

#acr("gw", plural: true) propagating between the pulsar and the observer act as anisotropic media. This will cause the pulse to be delayed or sped up, depending on the relative direction of the wave, its polarisation axes and the direction of the pulsar. Given a collection of such pulsars with precisely known periods, evenly distributed in the celestial sphere, then one can use the relative delay of the pulses to measure the direction and nature of the wave. This setup is essentially a blown up version of #acr("ligo") with light-year scale arms instead of kilometer scale arms.

Currently, the set of pulsars suitable for this type of measurement is around 40 @Maiorano:2021. Many more pulsars have been measured but not all are suitably regular to be used in #acr("pta", plural: true) . The frequency range of sensitivity of #acr("pta", plural: true) has a lower bound set by observation duration and higher bound set by cadence of measurement. Currently, the IPTA #cite(<Hobbs:2009yy>, form: "prose") has been measuring for 13 years, with measurements being taken every week yielding a sensitivity in a drastically different band than that of #acr("ligo") and #acr("lisa") :

$ \[ 10^(- 9) \, 10^(- 7) \] upright("Hz") . $

The nature of sources that can be detected by #acr("pta", plural: true) is therefore different from that of #acr("ligo") and #acr("lisa"). The #acr("pta") sensitivity is more suited to detect stochastic gravitational waves, such as those emitted by early-universe phenomena, or by supermassive black holes ($10^6 - 10^9 M_dot.o$) in the centers of galaxies #footnote[more massive objects have longer orbital periods].
