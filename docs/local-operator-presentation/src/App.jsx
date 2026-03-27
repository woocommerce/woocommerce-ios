import { useEffect, useState } from "react";
import deviceStaffModeLockScreen from "./assets/device-staff-mode-lock-screen.png";

const pages = [
  {
    slug: "overview",
    label: "Overview",
    eyebrow: "WooCommerce iOS",
    title: "Local Operator Mode",
    subtitle:
      "A lightweight shared-device layer for the app: quick PIN unlock, cleaner handoff, and fewer accidental trips into sensitive areas.",
    render: () => (
      <div className="page-grid page-grid-hero">
        <section className="panel panel-hero">
          <p className="eyebrow">Shared-device concept</p>
          <h1>One Woo login. Multiple local operators.</h1>
          <p className="hero-lede">
            The app keeps a single backend account underneath, while the device
            reflects who is actively using it through a local operator and PIN.
          </p>
          <div className="hero-callouts">
            <span className="tag">Shared tablet</span>
            <span className="tag">PIN unlock</span>
            <span className="tag">Soft gating</span>
          </div>
        </section>

        <section className="stack">
          <article className="panel stat-panel">
            <span className="stat-label">Best fit</span>
            <strong>Store devices with frequent staff handoff</strong>
          </article>
          <article className="panel stat-panel">
            <span className="stat-label">Available to cashier</span>
            <strong>Order creation and daily workflow</strong>
          </article>
          <article className="panel stat-panel accent-panel">
            <span className="stat-label">Hidden first</span>
            <strong>Analytics, plugins, and admin-style settings</strong>
          </article>
        </section>
      </div>
    )
  },
  {
    slug: "why",
    label: "Why Now",
    eyebrow: "Framing",
    title: "A practical bridge before remote roles exist",
    subtitle:
      "This gives us a real shared-device workflow now without pretending we already have backend authorization.",
    render: () => (
      <div className="card-grid three-up">
        <article className="panel feature-card feature-card-dark">
          <h3>The gap</h3>
          <p>Stores want a cashier-style app experience, but remote roles are not ready yet.</p>
        </article>
        <article className="panel feature-card">
          <h3>The choice</h3>
          <p>Start with local operator capabilities so the device can behave differently by user.</p>
        </article>
        <article className="panel feature-card">
          <h3>The promise</h3>
          <p>Useful UX restriction today, with a clean path to backend-driven roles later.</p>
        </article>
      </div>
    )
  },
  {
    slug: "experience",
    label: "Experience",
    eyebrow: "Flow",
    title: "What the flow feels like",
    subtitle:
      "The interaction model is intentionally simple: unlock fast, work normally, switch cleanly.",
    render: () => (
      <div className="card-grid three-up">
        <article className="panel flow-card">
          <span className="flow-step">01</span>
          <h3>Setup once</h3>
          <p>Enable Device Staff Mode and create the first manager with a PIN.</p>
        </article>
        <article className="panel flow-card">
          <span className="flow-step">02</span>
          <h3>Unlock fast</h3>
          <p>Select the next operator, enter a PIN, and continue on the shared device.</p>
        </article>
        <article className="panel flow-card">
          <span className="flow-step">03</span>
          <h3>Gate only what matters</h3>
          <p>Cashiers keep operational flows while analytics and admin surfaces stay out of the way.</p>
        </article>
      </div>
    )
  },
  {
    slug: "screenshots",
    label: "Screens",
    eyebrow: "In Product",
    title: "What it looks like",
    subtitle:
      "The lock screen turns the app into a clear handoff flow: choose the next operator, enter a PIN, and unlock.",
    render: () => (
      <div className="page-grid screenshot-grid">
        <article className="panel screenshot-stage">
          <div className="device-frame">
            <img
              src={deviceStaffModeLockScreen}
              alt="Device Staff Mode lock screen with operator picker and PIN entry"
              className="device-shot"
            />
          </div>
        </article>

        <article className="stack">
          <article className="panel screenshot-caption">
            <span className="stat-label">Screenshot</span>
            <h3>Device Staff Mode lock screen</h3>
            <p>
              This is the shared-device unlock point. It is intentionally closer to
              a lock screen than a settings form.
            </p>
          </article>

          <article className="panel checklist-card">
            <h3>Key points</h3>
            <ul className="bullet-list">
              <li>Operators are local to the device.</li>
              <li>PIN unlock is fast enough for handoff.</li>
              <li>The management screen now includes an explicit Switch Operator action.</li>
            </ul>
          </article>
        </article>
      </div>
    )
  },
  {
    slug: "build",
    label: "Build",
    eyebrow: "What We Built",
    title: "The first slice is already tangible",
    subtitle:
      "Enough is implemented to demo the concept clearly without overcommitting to a full permissions system.",
    render: () => (
      <div className="page-grid implementation-grid">
        <article className="panel browser-frame">
          <div className="browser-bar">
            <span />
            <span />
            <span />
          </div>
          <div className="browser-body">
            <div className="mini-screen screen-lock">
              <div className="mini-badge">Unlock</div>
              <h3>PIN-based operator handoff</h3>
              <p>Bootstrap, lock, unlock, timeout, and switch operator are all wired in.</p>
            </div>
            <div className="mini-screen screen-restricted">
              <div className="mini-badge">Gating</div>
              <h3>Cashier restrictions</h3>
              <p>Analytics and admin-style settings are hidden or blocked for cashier.</p>
            </div>
            <div className="mini-screen screen-settings">
              <div className="mini-badge">Management</div>
              <h3>Manager controls</h3>
              <p>Managers can manage operators, PINs, and recovery rules on-device.</p>
            </div>
          </div>
        </article>

        <article className="stack">
          <article className="panel checklist-card">
            <h3>In place now</h3>
            <ul className="bullet-list">
              <li>Local profiles, PIN storage, and session state.</li>
              <li>Analytics and settings gating for cashier operators.</li>
              <li>Manager safeguards so the device cannot get stranded without recovery.</li>
            </ul>
          </article>

          <article className="panel matrix-card">
            <h3>Tech shape</h3>
            <ul className="bullet-list">
              <li>Capabilities drive the UI instead of raw role-name checks.</li>
              <li>The Woo account session remains untouched underneath.</li>
              <li>The same capability model can later point to backend roles.</li>
            </ul>
          </article>
        </article>
      </div>
    )
  },
  {
    slug: "next",
    label: "Next",
    eyebrow: "Roadmap",
    title: "What this is, and what it is not",
    subtitle:
      "This is a strong shared-device UX experiment now, not the final authorization model for the app.",
    render: () => (
      <div className="card-grid three-up">
        <article className="panel roadmap-card">
          <span className="phase-chip">Now</span>
          <h3>Useful local gating</h3>
          <p>Improve handoff and reduce accidental access on shared store devices.</p>
        </article>
        <article className="panel roadmap-card">
          <span className="phase-chip">Next</span>
          <h3>Remote capability source</h3>
          <p>Keep the same UI model, but resolve permissions from backend-managed roles.</p>
        </article>
        <article className="panel roadmap-card">
          <span className="phase-chip">Later</span>
          <h3>True enforcement</h3>
          <p>Move from soft gating to server-enforced permissions and per-user auditability.</p>
        </article>
      </div>
    )
  },
  {
    slug: "site",
    label: "Site",
    eyebrow: "Presentation Stack",
    title: "How this presentation site was built",
    subtitle:
      "The site is intentionally lightweight so it is easy to run locally, tweak quickly, and use as a polished walkthrough artifact.",
    render: () => (
      <div className="card-grid two-up">
        <article className="panel matrix-card">
          <h3>React</h3>
          <p>
            React is the UI layer. It lets the presentation behave like a browsable
            slide deck instead of a static page, with reusable sections and state
            for navigation.
          </p>
        </article>

        <article className="panel matrix-card">
          <h3>Vite</h3>
          <p>
            Vite is the dev server and build tool. It keeps the local preview fast
            while making it easy to produce a clean build for the final deck.
          </p>
        </article>
      </div>
    )
  }
];

function currentPageFromHash() {
  const slug = window.location.hash.replace("#", "") || "overview";
  return pages.find((page) => page.slug === slug) ?? pages[0];
}

function App() {
  const [activePage, setActivePage] = useState(currentPageFromHash);

  useEffect(() => {
    const onHashChange = () => {
      setActivePage(currentPageFromHash());
      window.scrollTo({ top: 0, behavior: "smooth" });
    };

    window.addEventListener("hashchange", onHashChange);
    return () => window.removeEventListener("hashchange", onHashChange);
  }, []);

  const activeIndex = pages.findIndex((page) => page.slug === activePage.slug);
  const previousPage = activeIndex > 0 ? pages[activeIndex - 1] : null;
  const nextPage = activeIndex < pages.length - 1 ? pages[activeIndex + 1] : null;

  return (
    <div className="page-shell">
      <header className="topbar">
        <div>
          <p className="eyebrow">Presentation Microsite</p>
          <h2 className="topbar-title">Local Operator Mode Story</h2>
        </div>
        <div className="progress-badge">
          <span>{String(activeIndex + 1).padStart(2, "0")}</span>
          <span className="progress-divider" />
          <span>{String(pages.length).padStart(2, "0")}</span>
        </div>
      </header>

      <nav className="page-nav">
        {pages.map((page) => (
          <a
            key={page.slug}
            href={`#${page.slug}`}
            className={page.slug === activePage.slug ? "nav-pill nav-pill-active" : "nav-pill"}
          >
            {page.label}
          </a>
        ))}
      </nav>

      <main className="deck-shell">
        <section key={activePage.slug} className="deck-page">
          <div className="deck-motif deck-motif-left" />
          <div className="deck-motif deck-motif-right" />

          <div className="page-heading">
            <p className="eyebrow">{activePage.eyebrow}</p>
            <h1 className="page-title">{activePage.title}</h1>
            <p className="page-subtitle">{activePage.subtitle}</p>
          </div>

          <div className="page-content">{activePage.render()}</div>
        </section>
      </main>

      <footer className="page-controls">
        <div className="control-side">
          {previousPage ? (
            <a href={`#${previousPage.slug}`} className="control-button">
              <span className="control-label">Previous</span>
              <strong>{previousPage.label}</strong>
            </a>
          ) : (
            <div className="control-placeholder" />
          )}
        </div>

        <div className="page-dots">
          {pages.map((page) => (
            <a
              key={page.slug}
              href={`#${page.slug}`}
              className={page.slug === activePage.slug ? "page-dot page-dot-active" : "page-dot"}
              aria-label={page.label}
            />
          ))}
        </div>

        <div className="control-side control-side-right">
          {nextPage ? (
            <a href={`#${nextPage.slug}`} className="control-button">
              <span className="control-label">Next</span>
              <strong>{nextPage.label}</strong>
            </a>
          ) : (
            <div className="control-placeholder" />
          )}
        </div>
      </footer>
    </div>
  );
}

export default App;
