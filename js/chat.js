const msgsEl = document.getElementById("msgs");
const form = document.getElementById("composer");
const input = document.getElementById("msg");
const typing = document.getElementById("typing");
const nameEl = document.getElementById("guest-name");

const guest =
  localStorage.getItem("nr-name") ||
  `Tamu-${Math.floor(1000 + Math.random() * 9000)}`;
if (nameEl) nameEl.value = guest;

let lastId = 0;

function bubble(msg) {
  const div = document.createElement("div");
  div.className = `bubble ${msg.role === "me" || msg.name === guest ? "me" : "noval"}`;
  div.innerHTML = `<div class="who">${escapeHtml(msg.name)}</div>${escapeHtml(msg.text)}`;
  msgsEl.appendChild(div);
  msgsEl.scrollTop = msgsEl.scrollHeight;
}

function escapeHtml(s) {
  return String(s)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

const API = window.CHAT_API || "/api/chat";

async function pull() {
  try {
    const res = await fetch(`${API}?since=${lastId}`, { cache: "no-store" });
    if (!res.ok) throw new Error("offline");
    const data = await res.json();
    for (const m of data.messages || []) {
      if (m.id > lastId) {
        lastId = m.id;
        bubble({ ...m, role: m.name === guest ? "me" : "noval" });
      }
    }
    if (typing) typing.textContent = data.typing ? "Noval sedang mengetik…" : "";
  } catch {
    if (!window.__localBooted) {
      window.__localBooted = true;
      bubble({
        name: "Noval",
        text: "Chat server belum hidup. Mode lokal: saya tetap balas di browser ini.",
      });
    }
  }
}

form?.addEventListener("submit", async (e) => {
  e.preventDefault();
  const text = input.value.trim();
  if (!text) return;
  const name = (nameEl?.value || guest).trim() || guest;
  localStorage.setItem("nr-name", name);
  input.value = "";
  try {
    const res = await fetch(API, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name, text }),
    });
    if (!res.ok) throw new Error("offline");
  } catch {
    bubble({ name, text, role: "me" });
    setTimeout(() => bubble({ name: "Noval", text: localReply(text) }), 600);
  }
});

function localReply(text) {
  const t = text.toLowerCase();
  if (t.includes("sekolah") || t.includes("smk")) return "Saya sekolah di SMK Al Madani Garut, kelas 11 PPLG.";
  if (t.includes("halo") || t.includes("hai") || t.includes("hi")) return "Halo! Saya Noval Rizki. Mau ngobrol soal web, sekolah, atau proyek?";
  if (t.includes("pplg")) return "PPLG = Pengembangan Perangkat Lunak dan Gim. Fokus saya di web & UI.";
  if (t.includes("garut")) return "Iya, Garut. Al Madani tempat saya belajar dan ngerjain proyek.";
  return "Siap. Ceritakan lebih banyak — saya Noval, siswa 11 PPLG SMK Al Madani Garut.";
}

pull();
setInterval(pull, 1200);
