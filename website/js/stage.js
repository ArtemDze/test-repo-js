(() => {
  const navToggle = document.querySelector(".nav-toggle");
  const navLinks = document.querySelector(".nav-links");

  if (navToggle && navLinks) {
    navToggle.addEventListener("click", () => {
      const open = navLinks.classList.toggle("open");
      navToggle.setAttribute("aria-expanded", open ? "true" : "false");
    });
  }

  const reveals = document.querySelectorAll(".reveal");
  const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  if (reveals.length) {
    if (reduce) {
      reveals.forEach((el) => el.classList.add("in"));
    } else {
      const io = new IntersectionObserver(
        (entries) => {
          entries.forEach((entry) => {
            if (entry.isIntersecting) {
              entry.target.classList.add("in");
              io.unobserve(entry.target);
            }
          });
        },
        { threshold: 0.14, rootMargin: "0px 0px -8% 0px" }
      );
      reveals.forEach((el) => io.observe(el));
    }
  }

  // Hero diamond constellation
  const canvas = document.querySelector(".hero-canvas");
  if (!canvas || !(canvas instanceof HTMLCanvasElement)) return;

  const ctx = canvas.getContext("2d");
  if (!ctx) return;

  let w = 0;
  let h = 0;
  let t = 0;
  let raf = 0;

  const diamonds = Array.from({ length: 42 }, (_, i) => ({
    x: Math.random(),
    y: Math.random(),
    s: 3 + Math.random() * 7,
    sp: 0.15 + Math.random() * 0.45,
    phase: Math.random() * Math.PI * 2,
    warm: i % 3 !== 0,
  }));

  function resize() {
    const rect = canvas.getBoundingClientRect();
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    w = rect.width;
    h = rect.height;
    canvas.width = Math.floor(w * dpr);
    canvas.height = Math.floor(h * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  }

  function drawDiamond(x, y, size, color) {
    ctx.beginPath();
    ctx.moveTo(x, y - size);
    ctx.lineTo(x + size * 0.7, y);
    ctx.lineTo(x, y + size);
    ctx.lineTo(x - size * 0.7, y);
    ctx.closePath();
    ctx.fillStyle = color;
    ctx.fill();
  }

  function frame(now) {
    t = now * 0.001;
    ctx.clearRect(0, 0, w, h);

    // soft footlight
    const g = ctx.createRadialGradient(w * 0.5, h * 0.38, 10, w * 0.5, h * 0.4, w * 0.45);
    g.addColorStop(0, "rgba(184,148,92,0.16)");
    g.addColorStop(0.45, "rgba(140,56,71,0.08)");
    g.addColorStop(1, "transparent");
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, w, h);

    diamonds.forEach((d, i) => {
      const px = d.x * w + Math.sin(t * d.sp + d.phase) * 12;
      const py = d.y * h * 0.85 + Math.cos(t * d.sp * 0.8 + d.phase) * 10;
      const pulse = 0.25 + 0.35 * (0.5 + 0.5 * Math.sin(t * 1.2 + d.phase));
      const color = d.warm
        ? `rgba(184,148,92,${pulse})`
        : `rgba(77,133,133,${pulse * 0.85})`;
      drawDiamond(px, py, d.s + (i % 4), color);
    });

    // center emblem
    const cx = w * 0.5;
    const cy = h * 0.36;
    for (let i = 0; i < 12; i++) {
      const a = (i / 12) * Math.PI * 2 + t * 0.15;
      const r = 48 + (i % 3) * 10;
      drawDiamond(
        cx + Math.cos(a) * r,
        cy + Math.sin(a) * r * 0.92,
        5 + (i % 2),
        i % 2 ? "rgba(212,176,120,0.55)" : "rgba(140,56,71,0.45)"
      );
    }

    raf = requestAnimationFrame(frame);
  }

  resize();
  window.addEventListener("resize", resize);
  if (!reduce) raf = requestAnimationFrame(frame);
  else {
    // static draw once
    frame(0);
    cancelAnimationFrame(raf);
  }
})();
