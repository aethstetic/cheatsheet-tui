pkgname=cheatsheet-tui
pkgver=0.1.0
pkgrel=1
pkgdesc='Terminal UI for browsing and managing command cheatsheets'
arch=('x86_64')
license=('MIT')
makedepends=('ldc' 'make')
url='https://github.com/aethstetic/cheatsheet-tui'
source=("$pkgname-$pkgver::git+$url.git")
sha256sums=('SKIP')

build() {
    cd "$pkgname-$pkgver"
    make
}

package() {
    cd "$pkgname-$pkgver"
    install -Dm755 cheatsheet-tui "$pkgdir/usr/bin/cheatsheet-tui"
}
