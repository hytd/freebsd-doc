# bsd.web.mk
# $FreeBSD$

#
# Build and install a web site.
#
# Basic targets:
#
# all (default) -- performs batch mode processing necessary
# install -- installs everything
# clean -- remove anything generated by processing
#

.if exists(${.CURDIR}/../Makefile.inc)
.include "${.CURDIR}/../Makefile.inc"
.endif

WEBDIR?=	${.CURDIR:T}
CGIDIR?=	${.CURDIR:T}
DESTDIR?=	${HOME}/public_html

WEBOWN?=	${USER}
WEBGRP?=	www
WEBMODE?=	664

CGIOWN?=	${USER}
CGIGRP?=	www
CGIMODE?=	775

CP?=		/bin/cp
CVS?=		/usr/bin/cvs
ECHO_CMD?=	echo
SETENV?=	/usr/bin/env
LN?=		/bin/ln
MKDIR?=		/bin/mkdir
MV?=		/bin/mv
PERL?=		/usr/bin/perl5
RM?=		/bin/rm
SED?=		/usr/bin/sed
SH?=		/bin/sh
SORT?=		/usr/bin/sort
TOUCH?=		/usr/bin/touch

LOCALBASE?=	/usr/local
PREFIX?=	${LOCALBASE}

.if !defined(OPENJADE)
SGMLNORM?=	${PREFIX}/bin/sgmlnorm
.else
SGMLNORM?=	${PREFIX}/bin/osgmlnorm
.endif
CATALOG?=	${PREFIX}/share/sgml/html/catalog
SGMLNORMOPTS?=	-d ${SGMLNORMFLAGS} -c ${CATALOG} -D ${.CURDIR}

XSLTPROC?=	${PREFIX}/bin/xsltproc
XSLTPROCOPTS?=	${XSLTPROCFLAGS}

TIDY?=		${PREFIX}/bin/tidy
TIDYOPTS?=	-i -m -raw -preserve -f /dev/null -asxml ${TIDYFLAGS}

HTML2TXT?=	${PREFIX}/bin/w3m
HTML2TXTOPTS?=	-dump ${HTML2TXTFLAGS}
ISPELL?=	ispell
ISPELLOPTS?=	-l -p /usr/share/dict/freebsd ${ISPELLFLAGS}

#
# Install dirs derived from the above.
#
DOCINSTALLDIR=	${DESTDIR}${WEBBASE}/${WEBDIR}
CGIINSTALLDIR=	${DESTDIR}${WEBBASE}/${CGIDIR}

#
# The orphan list contains sources specified in DOCS that there
# is no transform rule for.  We start out with all of them, and
# each rule below removes the ones it knows about.  If any are
# left over at the end, the user is warned about them and build
# breaks.
#
ORPHANS:=	${DOCS}

#
# Tell install(1) to always copy file being installed.
#
COPY=	-C

#
# Where the ports live, if CVS isn't used (ie. NOPORTSCVS is defined)
#
PORTSBASE?=	/usr

#
# Instruct bsd.subdir.mk to NOT to process SUBDIR directive.  It is not
# neccessary since web.site.mk do it using own rules.
#
NO_SUBDIR=	YES

#
# for dependency
#
.if !defined(WITHOUT_DOC)
#
# When WITHOUT_DOC is not defined, we use doc.common.mk.
#
DOC_PREFIX?=	${WEB_PREFIX}/../doc
.if exists(${DOC_PREFIX}/share/mk/doc.common.mk)
.include "${DOC_PREFIX}/share/mk/doc.common.mk"
.else
.error	${DOC_PREFIX}/share/mk/doc.common.mk not found.\
	Define $$WITHOUT_DOC for building without the doc/ module.
.endif
.else # !defined(WITHOUT_DOC)
#
# When WITHOUT_DOC is defined, we should not use files in doc/ module at all.
#
.if !defined(WWW_LANGCODE) || empty(WWW_LANGCODE)
_WEB_PREFIX!=			realpath ${WEB_PREFIX}
WWW_LANGCODE:=			${.CURDIR:S,^${_WEB_PREFIX}/,,:C,^([^/]+)/.*,\1,}
.undef _WEB_PREFIX
.endif
.endif # !defined(WITHOUT_DOC)

XML_ADVISORIES?=		${WEB_PREFIX}/share/sgml/advisories.xml

XML_NEWS_NEWS_MASTER=		${WEB_PREFIX}/en/news/news.xml
XML_NEWS_NEWS=			${WEB_PREFIX}/${WWW_LANGCODE}/news/news.xml
XML_NEWS_PRESS_MASTER=		${WEB_PREFIX}/en/news/press.xml
XML_NEWS_PRESS=			${WEB_PREFIX}/${WWW_LANGCODE}/news/press.xml
XML_NEWS_INCLUDES_MASTER=	${WEB_PREFIX}/en/news/includes.xsl
XML_NEWS_INCLUDES=		${WEB_PREFIX}/${WWW_LANGCODE}/news/includes.xsl

XML_NAVIGATION=			${WEB_PREFIX}/${WWW_LANGCODE}/navigation.xml

XML_INCLUDES=	${WEB_PREFIX}/${WWW_LANGCODE}/includes.xsl
XML_INCLUDES+=	${WEB_PREFIX}/share/sgml/includes.header.xsl
XML_INCLUDES+=	${WEB_PREFIX}/share/sgml/includes.misc.xsl
XML_INCLUDES+=	${WEB_PREFIX}/share/sgml/includes.release.xsl
XML_INCLUDES+=	${WEB_PREFIX}/share/sgml/transtable-common.xsl
XML_INCLUDES+=	${WEB_PREFIX}/share/sgml/includes.xsl

SGML_INCLUDES=	${WEB_PREFIX}/${WWW_LANGCODE}/includes.sgml
SGML_INCLUDES+=	${WEB_PREFIX}/share/sgml/includes.header.sgml
SGML_INCLUDES+=	${WEB_PREFIX}/share/sgml/includes.misc.sgml
SGML_INCLUDES+=	${WEB_PREFIX}/share/sgml/includes.release.sgml
SGML_INCLUDES+=	${WEB_PREFIX}/share/sgml/includes.sgml

##################################################################
# Transformation rules

###
# file.sgml --> file.html
#
# Runs file.sgml through spam to validate and expand some entity
# references are expanded.  file.html is added to the list of
# things to install.

.SUFFIXES:	.sgml .html
.if defined(REVCHECK)
PREHTML?=	${WEB_PREFIX}/ja/prehtml
CANONPREFIX0!=	cd ${WEB_PREFIX}; ${ECHO_CMD} $${PWD};
CANONPREFIX=	${PWD:S/^${CANONPREFIX0}//:S/^\///}
LOCALTOP!=	${ECHO_CMD} ${CANONPREFIX} | \
	${PERL} -pe 's@[^/]+@..@g; $$_.="/." if($$_ eq".."); s@^\.\./@@;'
DIR_IN_LOCAL!=	${ECHO_CMD} ${CANONPREFIX} | ${PERL} -pe 's@^[^/]+/?@@;'
PREHTMLOPTS?=	-revcheck "${LOCALTOP}" "${DIR_IN_LOCAL}" ${PREHTMLFLAGS}
.else
DATESUBST?=	's/<!ENTITY date[ \t]*"$$Free[B]SD. .* \(.* .*\) .* .* $$">/<!ENTITY date	"Last modified: \1">/'
PREHTML?=	${SED} -e ${DATESUBST}
.endif

GENDOCS+=	${DOCS:M*.sgml:S/.sgml$/.html/g}
ORPHANS:=	${ORPHANS:N*.sgml}

.sgml.html: ${SGML_INCLUDES}
	${PREHTML} ${PREHTMLOPTS} ${.IMPSRC} | \
	${SETENV} SGML_CATALOG_FILES= \
		${SGMLNORM} ${SGMLNORMOPTS} > ${.TARGET} || \
			(${RM} -f ${.TARGET} && false)
.if !defined(NO_TIDY)
	-${TIDY} ${TIDYOPTS} ${.TARGET}
.endif


##################################################################
# Special Targets

#
# Spellcheck all generated documents in the current directory.
#
spellcheck:
.for _entry in ${GENDOCS}
	@echo "Spellcheck ${_entry}"
	@${HTML2TXT} ${HTML2TXTOPTS} ${.CURDIR}/${_entry} | ${ISPELL} ${ISPELLOPTS}
.endfor

##################################################################
# Main Targets

#
# If no target is specified, .MAIN is made.
#
.MAIN: all

#
# Build most everything.
#
all: ${COOKIE} orphans ${GENDOCS} ${DATA} ${CGI} _PROGSUBDIR

#
# Warn about anything in DOCS that has no suffix translation rule.
#
.if !empty(ORPHANS)
orphans:
	@${ECHO} Warning!  I don\'t know what to do with: ${ORPHANS}; \
	exit 1
.else
orphans:
.endif

#
# Clean things up.
#
.if !target(clean)
clean: _PROGSUBDIR
	${RM} -f Errs errs mklog ${GENDOCS} ${CLEANFILES}
.endif

#
# Really clean things up.
#
.if !target(cleandir)
cleandir: clean _PROGSUBDIR
	${RM} -f ${.CURDIR}/tags .depend
.if ${.OBJDIR} != ${.CURDIR} && exists(${.OBJDIR}/)
	${RM} -rf ${.OBJDIR}
.endif
	@if [ -L ${.CURDIR}/obj ]; then ${RM} -f ${.CURDIR}/obj; fi
.endif

#
# Install targets: before, real, and after.
#
.if !target(install)
.if !target(beforeinstall)
beforeinstall:
.endif
.if !target(afterinstall)
afterinstall:
.endif

INSTALL_WEB?=	\
	${INSTALL} ${COPY} ${INSTALLFLAGS} \
				-o ${WEBOWN} -g ${WEBGRP} -m ${WEBMODE}
INSTALL_CGI?=	\
	${INSTALL} ${COPY} ${INSTALLFLAGS} \
				-o ${CGIOWN} -g ${CGIGRP} -m ${CGIMODE}
_ALLINSTALL+=	${GENDOCS} ${DATA}

realinstall: ${COOKIE} ${_ALLINSTALL} ${CGI} _PROGSUBDIR
.if !empty(_ALLINSTALL)
	@${MKDIR} -p ${DOCINSTALLDIR}
.for entry in ${_ALLINSTALL}
.if exists(${.CURDIR}/${entry})
	${INSTALL_WEB} ${.CURDIR}/${entry} ${DOCINSTALLDIR}
.else
	${INSTALL_WEB} ${entry} ${DOCINSTALLDIR}
.endif
.endfor
.if defined(INDEXLINK) && !empty(INDEXLINK)
	cd ${DOCINSTALLDIR}; ${LN} -fs ${INDEXLINK} index.html
.endif
.endif
.if defined(CGI) && !empty(CGI)
	@${MKDIR} -p ${CGIINSTALLDIR}
.for entry in ${CGI}
	${INSTALL_CGI} ${.CURDIR}/${entry} ${CGIINSTALLDIR}
.endfor
.endif

# Set up install dependencies so they happen in the correct order.
install: afterinstall
afterinstall: realinstall2
realinstall: beforeinstall
realinstall2: realinstall
.endif 

#
# This recursively calls make in subdirectories.
#
_PROGSUBDIR: .USE
.if defined(SUBDIR) && !empty(SUBDIR)
.for entry in ${SUBDIR}
	@${ECHODIR} "===> ${DIRPRFX}${entry}"
	@cd ${.CURDIR}/${entry}; \
		${MAKE} ${.TARGET:S/realinstall/install/:S/.depend/depend/} \
			DIRPRFX=${DIRPRFX}${entry}/
.endfor
.endif

.include <bsd.obj.mk>

# THE END
