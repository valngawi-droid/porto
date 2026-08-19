document.getElementById("year").textContent = new Date().getFullYear();

const nav = document.querySelector(".nav");
let lastY = 0;
window.addEventListener("scroll", () => {
  const y = window.scrollY;
  nav.classList.toggle("compact", y > 24);
  lastY = y;
});
