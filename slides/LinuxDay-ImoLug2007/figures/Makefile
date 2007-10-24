## Makefile

# File lists

DISTFILES = *~
FIGURES = timeseries_bindi-letta.pdf timeseries-scatter_veltroni-pd.pdf
CLEANFILES = $(DISTFILES) $(FIGURES)

# Build rules

all: $(FIGURES)

timeseries_bindi-letta.pdf: timeseries_bindi-letta.r
	cat timeseries_bindi-letta.r | R --vanilla --slave

timeseries-scatter_veltroni-pd.pdf: timeseries-scatter_veltroni-pd.r
	cat timeseries-scatter_veltroni-pd.r | R --vanilla --slave

# Clean-up rules

clean:
	rm -f $(CLEANFILES)

distclean:
	rm -f $(DISTFILES)
