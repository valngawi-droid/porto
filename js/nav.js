document.querySelectorAll("[data-year]").forEach((el) => {
  el.textContent = new Date().getFullYear();
});
const here = location.pathname.split("/").pop() || "index.html";
document.querySelectorAll(".nav-links a").forEach((a) => {
  const href = a.getAttribute("href");
  if (href === here || (here === "" && href === "index.html")) a.classList.add("active");
});
