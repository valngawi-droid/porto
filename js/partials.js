document.querySelector("[data-nav]")?.insertAdjacentHTML(
  "afterbegin",
  `
  <a class="logo" href="index.html">NR<span>.</span></a>
  <nav class="nav-links">
    <a href="index.html">Beranda</a>
    <a href="tentang.html">Tentang</a>
    <a href="sekolah.html">Sekolah</a>
    <a href="karya.html">Karya</a>
    <a href="keahlian.html">Keahlian</a>
    <a href="chat.html">Chat</a>
    <a href="kontak.html">Kontak</a>
  </nav>
  <a class="nav-cta" href="chat.html">Chat Noval</a>
`
);
document.querySelector("[data-foot]")?.insertAdjacentHTML(
  "afterbegin",
  `<p>© <span data-year></span> Noval Rizki · 11 PPLG · SMK Al Madani Garut</p>`
);
