# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit meson vala

DESCRIPTION="Plasma Integration browser plugin support for GTK-based environments."
HOMEPAGE="https://github.com/STrusov/plasma-browser-integration-glib"
if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	KEYWORDS=""
	EGIT_REPO_URI="https://github.com/STrusov/${PN}.git"
else
	SRC_URI="$HOMEPAGE/archive/${PV}.tar.gz -> ${MY_P}.tar.gz"
fi

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64"

#S="${WORKDIR}"

RDEPEND="
	dev-libs/glib[dbus]
	dev-libs/json-glib
"

src_prepare() {
	default
	vala_src_prepare
}
