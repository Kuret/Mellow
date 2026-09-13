/*
 * On-device web inspector: Eruda (MIT, vendored as eruda.js) driven from the
 * app over a native port.
 *
 * Eruda is loaded lazily — a 500 KB parse on every page load would be a tax on
 * browsing for a tool that is almost never open. The first command pays for it.
 *
 * Two worlds, in order of preference:
 *
 *   page      A <script src="moz-extension://..."> tag. Eruda then shares the
 *             page's globals, so its Console and Network panels see the page's
 *             own console calls, fetch and XHR. This is the real thing.
 *   isolated  The page's CSP can block that script tag, and the sites where
 *             one most wants an inspector are exactly the ones that set a
 *             strict CSP. So fall back to running Eruda inside the content
 *             script's sandbox, where the DOM is shared but the globals are
 *             not: Elements, styles and storage still work, Console and
 *             Network only see the sandbox and stay empty.
 *
 * The app is told which world it got, so it can say so.
 */

const port = browser.runtime.connectNative('mozacWebInspector');

const ERUDA_URL = browser.runtime.getURL('eruda.js');

/** 'page' | 'isolated' once Eruda is loaded, null before. */
let world = null;
/** The sandbox's own Eruda, when [world] is 'isolated'. */
let sandboxEruda = null;
/** The load in flight, so concurrent commands wait on one injection. */
let loading = null;
/** Eruda is loaded but `init()` has not been called since the last teardown. */
let initialised = false;
let visible = false;
/** Teardown for the element picker, non-null only while it is running. */
let stopPicking = null;

/**
 * The page's own `eruda`, reached through the Xray wrapper. Undefined until
 * the injected script has run, and forever if the CSP blocked it.
 */
function pageEruda() {
  return window.wrappedJSObject && window.wrappedJSObject.eruda;
}

function eruda() {
  return world === 'page' ? pageEruda() : sandboxEruda;
}

function report(extra) {
  try {
    port.postMessage(
      Object.assign({ type: 'state', world: world, visible: visible }, extra),
    );
  } catch (error) {
    // The port outlives nothing here; a closed port just means the tab is
    // going away, which is not worth a broken inspector.
  }
}

function injectIntoPage() {
  return new Promise((resolve, reject) => {
    const script = document.createElement('script');
    script.src = ERUDA_URL;
    script.onload = () => {
      script.remove();
      // A CSP that allows the load but a page that shadows the global would
      // leave us with a script that ran and nothing to call.
      if (pageEruda()) {
        resolve();
      } else {
        reject(new Error('no eruda global in the page'));
      }
    };
    script.onerror = () => {
      script.remove();
      reject(new Error('blocked before it ran'));
    };
    (document.head || document.documentElement).appendChild(script);
  });
}

async function injectIntoSandbox() {
  const source = await fetch(ERUDA_URL).then((response) => response.text());
  // The extension's CSP carries 'unsafe-eval' for this one line. What it
  // evaluates is the file bundled with the extension, fetched over
  // moz-extension:, never anything the page can reach or influence.
  // eslint-disable-next-line no-new-func
  new Function(source).call(window);
  // Eruda's UMD assigns to the global it runs on; from the sandbox that is an
  // expando on the Xray wrapper, visible here and nowhere else.
  return window.eruda;
}

async function load() {
  if (world) return;
  if (!loading) {
    loading = injectIntoPage()
      .then(() => {
        world = 'page';
      })
      .catch(async () => {
        sandboxEruda = await injectIntoSandbox();
        world = 'isolated';
      })
      .finally(() => {
        loading = null;
      });
  }
  await loading;
}

async function ensureReady() {
  await load();
  const tools = eruda();
  if (!tools) throw new Error('eruda did not load');
  if (!initialised) {
    tools.init();
    initialised = true;
  }
  return tools;
}

async function show(panel) {
  const tools = await ensureReady();
  if (panel) {
    tools.show(panel);
  } else {
    tools.show();
  }
  visible = true;
  report();
}

function hide() {
  cancelPicking();
  const tools = eruda();
  // Destroy rather than hide: the floating entry button survives `hide()`, and
  // a tool that is switched off should leave no furniture on the page.
  if (tools && initialised) {
    tools.destroy();
    initialised = false;
  }
  visible = false;
  report();
}

function inspect(element) {
  const tools = eruda();
  if (!tools) return;
  tools.show('elements');
  visible = true;
  try {
    tools.get('elements').set(element);
  } catch (error) {
    // Older Eruda, or a panel that has not built yet: the Elements panel is
    // open on whatever it had, which still beats nothing.
    report({ selected: false });
    return;
  }
  report({ selected: true });
}

/**
 * Eats the click (and the mouse events synthesised alongside it) that follows
 * the tap which chose an element, so choosing a link inspects it instead of
 * following it. Capture on `window` runs before any page handler, including
 * the delegated ones frameworks hang off `document`.
 */
function swallowNextClick() {
  const swallow = (event) => {
    event.preventDefault();
    event.stopPropagation();
  };
  const events = ['click', 'mousedown', 'mouseup'];
  for (const name of events) {
    window.addEventListener(name, swallow, true);
  }
  setTimeout(() => {
    for (const name of events) {
      window.removeEventListener(name, swallow, true);
    }
  }, 700);
}

function cancelPicking() {
  if (stopPicking) {
    stopPicking();
    stopPicking = null;
  }
}

/**
 * Tap-to-inspect: a shield over the page turns the next tap into a selection
 * instead of a click, with the element under the finger outlined as it moves.
 */
async function pick() {
  const tools = await ensureReady();
  // Out of the way while aiming; `inspect` brings it back on the selection.
  if (visible) {
    tools.hide();
    visible = false;
  }
  if (stopPicking) return;

  const shield = document.createElement('div');
  shield.style.cssText = [
    'position:fixed',
    'inset:0',
    'z-index:2147483645',
    'cursor:crosshair',
    'background:transparent',
  ].join(';');

  const outline = document.createElement('div');
  outline.style.cssText = [
    'position:fixed',
    'z-index:2147483646',
    'pointer-events:none',
    'border:2px solid #4f9cff',
    'background:rgba(79,156,255,0.18)',
    'border-radius:2px',
    'box-shadow:0 0 0 1px rgba(0,0,0,0.35)',
  ].join(';');
  outline.style.display = 'none';

  const hint = document.createElement('div');
  hint.style.cssText = [
    'position:fixed',
    'left:50%',
    'bottom:24px',
    'transform:translateX(-50%)',
    'z-index:2147483647',
    'display:flex',
    'gap:12px',
    'align-items:center',
    'padding:8px 12px',
    'border-radius:999px',
    'background:rgba(20,20,22,0.92)',
    'color:#fff',
    'font:500 13px/1.2 system-ui,sans-serif',
    'box-shadow:0 4px 16px rgba(0,0,0,0.4)',
  ].join(';');
  hint.textContent = 'Tap an element to inspect';

  const cancel = document.createElement('button');
  cancel.textContent = 'Cancel';
  cancel.style.cssText = [
    'all:unset',
    'padding:4px 10px',
    'border-radius:999px',
    'background:#4f9cff',
    'color:#0b0b0c',
    'font:600 13px/1.2 system-ui,sans-serif',
    'cursor:pointer',
  ].join(';');
  hint.appendChild(cancel);

  const root = document.body || document.documentElement;
  root.appendChild(shield);
  root.appendChild(outline);
  root.appendChild(hint);

  function elementAt(event) {
    // elementFromPoint skips pointer-events:none, so lifting the shield for
    // the duration of the call is what makes it report the page's element.
    shield.style.pointerEvents = 'none';
    const element = document.elementFromPoint(event.clientX, event.clientY);
    shield.style.pointerEvents = 'auto';
    return element;
  }

  function highlight(element) {
    if (!element) {
      outline.style.display = 'none';
      return;
    }
    const box = element.getBoundingClientRect();
    outline.style.display = 'block';
    outline.style.left = `${box.left}px`;
    outline.style.top = `${box.top}px`;
    outline.style.width = `${box.width}px`;
    outline.style.height = `${box.height}px`;
  }

  function onMove(event) {
    event.preventDefault();
    highlight(elementAt(event));
  }

  function onSelect(event) {
    event.preventDefault();
    event.stopPropagation();
    const element = elementAt(event);
    // The shield swallows the pointer events, but the click the browser
    // synthesises from the same touch lands after it is gone — on whatever is
    // underneath. Without this, picking a link navigates the page.
    swallowNextClick();
    cancelPicking();
    if (element) inspect(element);
  }

  function onCancel(event) {
    event.preventDefault();
    event.stopPropagation();
    cancelPicking();
    report({ cancelled: true });
  }

  shield.addEventListener('pointermove', onMove, { passive: false });
  shield.addEventListener('pointerdown', onMove, { passive: false });
  shield.addEventListener('pointerup', onSelect, { passive: false });
  cancel.addEventListener('pointerup', onCancel, { passive: false });

  stopPicking = () => {
    shield.remove();
    outline.remove();
    hint.remove();
  };

  report({ picking: true });
}

port.onMessage.addListener((message) => {
  const action = message && message.action;
  const run = async () => {
    switch (action) {
      case 'show':
        await show(message.panel);
        break;
      case 'hide':
        hide();
        break;
      case 'toggle':
        if (visible || stopPicking) {
          hide();
        } else {
          await show(message.panel);
        }
        break;
      case 'pick':
        await pick();
        break;
      case 'state':
        report();
        break;
      default:
        break;
    }
  };

  run().catch((error) => {
    report({ error: String((error && error.message) || error) });
  });
});

window.addEventListener('pagehide', cancelPicking);
