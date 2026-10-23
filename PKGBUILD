# Maintainer: Mauricio Montanares <mauricio.xmontanares@gmail.com>
# Packaging around python-validity (Copyright (c) 2020 uunicorn, MIT).
# The patch is https://github.com/uunicorn/python-validity/pull/290
pkgname=python-validity
pkgver=0.15
pkgrel=2
pkgdesc="Validity fingerprint sensor driver, with the 06cb:009a init fix"
arch=(any)
license=(MIT)
depends=(python python-yaml python-pyusb python-cryptography python-dbus python-gobject
  innoextract "open-fprintd>=0.6" fprintd-clients glib2)
makedepends=(python-setuptools glib2-devel)
conflicts=($pkgname)
provides=($pkgname)
url="https://github.com/uunicorn/${pkgname}"
source=(
  "$pkgname-$pkgver.tar.gz::${url}/archive/${pkgver}.tar.gz"
  python3-validity-suspend-hotfix.service
  fix-init-recovery-and-journal-flood.patch
)
sha256sums=('dab0567258480285de73fbf19709d75e20e5cabc6624a2dabd6a4ffde60d58c6'
            '5e263d2627ec60bf6aed53b82b7c053783884d942f3e9e7782fb4342f262b45d'
            'ddc0afdd9d8479d54db8913c3531dd5e37f75b69cf526d2d4c8efa8b624c95be')
install=$pkgname.install

prepare() {
  cd $srcdir/$pkgname-$pkgver
  patch -Np1 -i "$srcdir/fix-init-recovery-and-journal-flood.patch"
}

build() {
  cd $srcdir/$pkgname-$pkgver
  # Omarchy and other setups put a user Python ahead of /usr/bin. That
  # interpreter does not have the system setuptools this package builds with.
  /usr/bin/python setup.py build
}

package() {
  cd $srcdir/$pkgname-$pkgver
  /usr/bin/python setup.py install --prefix=/usr --root $pkgdir || return 1

  sed -i 's/^Restart=.*/Restart=on-failure/' debian/python3-validity.service
  install -D -m 644 debian/python3-validity.service \
    $pkgdir/usr/lib/systemd/system/python3-validity.service

  install -D -m 644 ../python3-validity-suspend-hotfix.service \
    $pkgdir/usr/lib/systemd/system/python3-validity-suspend-hotfix.service

  install -D -m 644 debian/python3-validity.udev \
    $pkgdir/usr/lib/udev/rules.d/60-python-validity.rules

  install -Dm644 LICENSE \
    ${pkgdir}/usr/share/licenses/${pkgname}/LICENSE
}
