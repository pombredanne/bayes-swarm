## Makefile

# File lists

DISTFILES = *~
FIGURES = lm_hw_gp.pdf bi_lm_gp.pdf timeseries_bush.pdf\
	timeseries_chinaindia.pdf scatterplot_chinaindia.pdf
CLEANFILES = $(DISTFILES) $(FIGURES)

# Build rules

all: $(FIGURES)

lm_hw_gp.pdf: lm_hw_gp_demo.r
	cat lm_hw_gp_demo.r | R --vanilla --slave

bi_lm_gp.pdf: bi_lm_gp_demo.r
	cat bi_lm_gp_demo.r | R --vanilla --slave

timeseries_bush.pdf: timeseries_bush.r
	cat timeseries_bush.r | R --vanilla --slave

timeseries_chinaindia.pdf scatterplot_chinaindia.pdf: timeseries_chinaindia.r
	cat timeseries_chinaindia.r | R --vanilla --slave

# Clean-up rules

clean:
	rm -f $(CLEANFILES)

distclean:
	rm -f $(DISTFILES)
