(function () {
  const canvas = document.getElementById("scene3d");
  if (!canvas || !window.THREE) return;

  const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true });
  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(55, 1, 0.1, 100);
  camera.position.z = 8;

  const group = new THREE.Group();
  scene.add(group);

  const geo = new THREE.IcosahedronGeometry(1.15, 0);
  const mat = new THREE.MeshStandardMaterial({
    color: 0xe8c27a,
    metalness: 0.35,
    roughness: 0.25,
    wireframe: true,
  });
  const core = new THREE.Mesh(geo, mat);
  group.add(core);

  const ring = new THREE.Mesh(
    new THREE.TorusGeometry(2.3, 0.03, 16, 80),
    new THREE.MeshBasicMaterial({ color: 0x6ee0d4 })
  );
  ring.rotation.x = Math.PI / 2.4;
  group.add(ring);

  const particles = new THREE.BufferGeometry();
  const count = 280;
  const pos = new Float32Array(count * 3);
  for (let i = 0; i < count * 3; i++) pos[i] = (Math.random() - 0.5) * 16;
  particles.setAttribute("position", new THREE.BufferAttribute(pos, 3));
  group.add(
    new THREE.Points(
      particles,
      new THREE.PointsMaterial({ color: 0xf6f1e8, size: 0.03, transparent: true, opacity: 0.55 })
    )
  );

  scene.add(new THREE.AmbientLight(0xffffff, 0.55));
  const light = new THREE.PointLight(0x6ee0d4, 40, 30);
  light.position.set(4, 3, 6);
  scene.add(light);

  function resize() {
    const w = window.innerWidth;
    const h = window.innerHeight;
    renderer.setSize(w, h, false);
    renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
    camera.aspect = w / h;
    camera.updateProjectionMatrix();
  }
  window.addEventListener("resize", resize);
  resize();

  let mx = 0, my = 0;
  window.addEventListener("pointermove", (e) => {
    mx = (e.clientX / innerWidth - 0.5) * 0.6;
    my = (e.clientY / innerHeight - 0.5) * 0.4;
  });

  function tick(t) {
    core.rotation.y += 0.004;
    core.rotation.x += 0.002;
    ring.rotation.z += 0.003;
    group.rotation.y += (mx - group.rotation.y) * 0.04;
    group.rotation.x += (my - group.rotation.x) * 0.04;
    group.position.y = Math.sin(t * 0.001) * 0.15;
    renderer.render(scene, camera);
    requestAnimationFrame(tick);
  }
  requestAnimationFrame(tick);
})();
