# isaweb configuration
# $Id$

# python interpreter (> 2.2)
PYTHON=python2.3

# GNU find
FIND=gfind

# HTML tidy (needs not to be set if tidy usage is disabled, see below)
TIDY=tidy

# dirs to copy to build target
STATICDIRS=img media dist/css dist/img

# build target (attention: ~ will not work!)
OUTPUTROOT=$(HOME)/isaweb_public

# current distribution name
DISTNAME=Isabelle2004

# location of isabelle distribution packages
ISABELLE_DIST=/home/proj/isabelle/dist/Isabelle2004

# location of isabelle library 
ISABELLE_LIBR=/home/proj/isabelle/dist/Isabelle2004/library

# location of doc content file
ISABELLE_DOC_CONTENT_FILE=/home/proj/isabelle/Isabelle2004/doc/Contents

# set to a true value to use the "pypager iso-8859-1" hack
# (may be neccessary for older versions of HTML tidy)
FORCE_ISO_8859_1=

# set to a true value to disable html tidy postprocessing
DISABLE_TIDY=
