Presentazione per il CreativeCamp a Casalecchio (BO) del 6/10/2007.

Assicurati di aver installato:
* pdflatex + pacchetto foils
* R + pacchetto tgp

Su Ubuntu:
$ sudo apt-get install texlive-latex-base texlive-latex-extra texlive-fonts-recommended foiltex
$ sudo apt-get install r-base
# pacchetti necessari per la compilazione di tgp
$ sudo apt-get install gfrontran refblas3-dev
$ sudo R
R> install.packages("tgp")

Pacchetto per grafici 3d interattivi: rgl (build-depends: libglu1-mesa-dev)

some_data.Rdata contiene le serie storiche al 1/10/2007 di bayes-swarm degli stem:
* 1 - china
* 2 - india
* 8 - bush
* 21 - russia
* 25 - korea
* 26 - japan

