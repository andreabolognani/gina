NULL = 

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = $(NULL)

AM_CPPFLAGS = \
	$(VALA_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)

BUILT_SOURCES = src/ginanote.vala.stamp

bin_PROGRAMS = gina

gina_VALASOURCES = \
	src/ginanote.vala \
	$(NULL)

gina_SOURCES = \
	$(gina_VALASOURCES:.vala=.c) \
	$(gina_VALASOURCES:.vala=.h) \
	$(NULL)

src/ginanote.vala.stamp: $(gina_VALASOURCES)
	$(VALAC) -C --pkg gtk+-2.0 --basedir $(top_srcdir) $^
	touch $@

gina_LDADD = \
	$(VALA_LIBS) \
	$(NULL)

EXTRA_DIST = \
	$(gina_VALASOURCES) \
	src/ginanote.vala.stamp \
	$(NULL)

DISTCLEANFILES = \
	$(NULL)
