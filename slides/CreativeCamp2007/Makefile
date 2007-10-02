## Makefile

BASENAME = bayes-swarm

# dirs

FIGDIR = figures/

# File lists

DISTFILES = *~ $(BASENAME).log $(BASENAME).aux $(BASENAME).out
CLEANFILES = $(DISTFILES)

# Build rules

all: $(BASENAME).pdf figures

$(BASENAME).pdf: figures $(BASENAME).tex
	pdflatex bayes-swarm.tex > /dev/null
	pdflatex bayes-swarm.tex > /dev/null

figures:
	make -C $(FIGDIR)

# Clean-up rules

clean:
	make -C clean $(FIGDIR)
	rm -f $(CLEANFILES)

distclean:
	rm -f $(DISTFILES)
