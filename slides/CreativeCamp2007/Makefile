## Makefile

BASENAME = bayes-swarm

# dirs

FIGDIR = figures/

# File lists

DISTFILES = *~ $(BASENAME).log $(BASENAME).aux $(BASENAME).out
CLEANFILES = $(DISTFILES)

# Build rules

all: $(BASENAME).pdf

$(BASENAME).pdf: $(BASENAME).tex figures
	pdflatex bayes-swarm.tex -interaction=nonstopmode > /dev/null
	pdflatex bayes-swarm.tex -interaction=nonstopmode > /dev/null

.PHONY: figures
figures:
	make -C $(FIGDIR)

# Clean-up rules

clean:
	make -C $(FIGDIR) clean
	rm -f $(CLEANFILES)

distclean:
	rm -f $(DISTFILES)
