#import "/lib/page.typ": page
#import "/lib/links.typ": n
#import "/lib/thesis.typ": theses, acr
#let thesis = theses.at("msc-thesis")

#show: page.with(
  title: [Gravitational Waves from Feynman Diagrams],
  summary: "My master's thesis (ETH Zürich, 2022) on scattering amplitudes in gravitational wave physics.",
  meta: [#thesis.degree · #thesis.school, #thesis.date · #link(thesis.pdf)[PDF, 14 MB]],
)

My master's thesis, submitted at ETH Zürich in October 2022 under the supervision of
Prof. Babis Anastasiou. It is reproduced here chapter by chapter; the typeset original is
available as a #link(thesis.pdf)[PDF (14 MB)]. All the code used for the thesis is on
GitHub at #link("https://github.com/lcnbr/GWAmplitudes")[lcnbr/GWAmplitudes].

= Abstract

The goal of this thesis is to explain the nascent field of scattering amplitudes in gravitational wave physics. We explore the context in which these tools are revolutionizing the field, and then go into detail of their construction and application.

We begin with a brief overview of the topic and the academic context. The next chapter is devoted to the theoretical foundations of gravitational waves, and their important sources. In the third chapter we discuss the detection of these waves, highlighting the importance of the theoretical templates. The fourth chapter explores the theoretical methods for producing full wave templates, such as #acr("eob", form: "full") and #acr("nr", form: "full") as well as the expansions and approximations used for the inspiral: the #acr("pn", form: "full") and #acr("pm", form: "full") approximations.

The fifth chapter is the main focus of the thesis, and is devoted to the scattering amplitude techniques that can be applied to the general relativistic two-body problem. We begin with the #acr("eft", form: "full") matching technique to motivate the production of gravitational amplitudes. The #acr("kmoc", form: "full") formalism, defining the classical limit of wave functions, is explained in detail. Finally, amplitudes in a simplified theory, #acr("sqed", form: "full") are computed, with a focus on automation of calculations. The corresponding graphs, filters, Feynman rules and further simplifications are all implemented in a cocktail of the relevant languages. We also compare the results obtained with those found in the literature.

In the last chapter we provide some concluding remarks and a brief outlook.

= Contents

+ #n(<msc-thesis-introduction>)[Introduction] — Why scattering amplitudes from particle physics are useful for gravitational wave theory.
+ #n(<msc-thesis-gw-generation>)[Gravitational Wave Generation] — Gravitational waves from the linearised Einstein equations, and their astrophysical sources.
+ #n(<msc-thesis-gw-detection>)[Gravitational Wave Detection] — Laser interferometers, matched filtering and pulsar timing arrays.
+ #n(<msc-thesis-waveform-generation>)[Waveform Generation] — Numerical relativity, post-Newtonian and post-Minkowskian expansions, and effective one-body.
+ #n(<msc-thesis-scattering-amplitudes>)[Scattering Amplitudes and GWs] — From amplitudes to potentials, the KMOC formalism, and scalar QED amplitudes computed with QGRAF, Julia and FORM.
+ #n(<msc-thesis-conclusion>)[Conclusion] — Concluding remarks and outlook.

= Acknowledgements

First and foremost I would like to thank my supervisor, Prof.~Babis Anastasiou, for his trust, his support, and kindness throughout the last half year that has led to this thesis. Without his curiosity towards this new subject, I would have never discovered and learned about this wonderful world at the confluence of two great physical theories, #acr("gr", form: "full") and #acr("qft", form: "full") . I would also like to extend this thanks to the rest of the theoretical particle physics group a ETH. Dr Achilleas Lazopoulos, Dr.~Ben Ruijl, Dr.~Valentin Hirschi, Rayan Haindl, Dario Kermanschah, Zeno Capatti, Matilde Vicini, and Julia Karlen, the many shared lunches, coffee breaks, and discussions have been a incredible source of inspiration and motivation for me. In particular, I would like to thank Ben for his help with all things `FORM`, Zeno for our very insightful discussions and your great suggestions, and Julia for reading through the first draft of this thesis.

I would also like to thank my girlfriend, Maria Miklos, for her patience, love, and support. Thanks for keeping me grounded and reminding me that there is more to life than physics (such as math)!

Thanks as well to my grandfather Martin Huber, who graciously hosted me during the start of my masters, and with which I shared many great discussions and stories at the breakfast, dinner, and Jass table.

Finally, I would like to thank my parents for their unconditional love and support, and without whom I would not be here today.
