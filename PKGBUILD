pkgname=cheatsheet-tui
pkgver=0.1.0
pkgrel=1
pkgdesc='Terminal UI for browsing and managing command cheatsheets'
arch=('x86_64')
license=('MIT')
makedepends=('ldc')
source=()

build() {
    cd "$startdir"
    make clean
    make
}

package() {
    cd "$startdir"
    install -Dm755 cheatsheet-tui "$pkgdir/usr/bin/cheatsheet-tui"
}
