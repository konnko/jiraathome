This is a web application written using the Phoenix web framework and Ash Framework for modelling data

## Project guidelines

- Use `mix precommit` alias when you are done with all changes and fix any pending issues
- Use the already included and available `:req` (`Req`) library for HTTP requests, **avoid** `:httpoison`, `:tesla`, and `:httpc`. Req is included by default and is the preferred HTTP client for Phoenix apps
- Never write backwards compatibility code, consider this project an unreleased WIP
- When writing backend code, consult Ash Framework skills to write logic the Ash Framework way. If something interacts with database in any way, it is better be wrapped in an action and be made accessible via code_interface
- When writing tests, make sure they can fail
- When writing Ash Framework resources, make actions as if they are an API. They better do singular thing
- Give functions/actions/variables precise names that explain what they do/return
- Don't write checks/barriers/rules or other logic that handle extremely unlikely. Keep code straightforward and simple, for extreme cases we have customer support
- Make sure unexpected errors crash the server. When handling expected errors, do it using ErrorReport module

### Phoenix v1.8 guidelines

- **Always** begin your LiveView templates with `<Layouts.app flash={@flash} ...>` which wraps all inner content
- The `MyAppWeb.Layouts` module is aliased in the `my_app_web.ex` file, so you can use it without needing to alias it again
- Anytime you run into errors with no `current_scope` assign:
  - You failed to follow the Authenticated Routes guidelines, or you failed to pass `current_scope` to `<Layouts.app>`
  - **Always** fix the `current_scope` error by moving your routes to the proper `live_session` and ensure you pass `current_scope` as needed
- Phoenix v1.8 moved the `<.flash_group>` component to the `Layouts` module. You are **forbidden** from calling `<.flash_group>` outside of the `layouts.ex` module
- Out of the box, `core_components.ex` imports an `<.icon name="hero-x-mark" class="w-5 h-5"/>` component for for hero icons. **Always** use the `<.icon>` component for icons, **never** use `Heroicons` modules or similar
- **Always** use the imported `<.input>` component for form inputs from `core_components.ex` when available. `<.input>` is imported and using it will save steps and prevent errors
- If you override the default input classes (`<.input class="myclass px-2 py-1 rounded-lg">)`) class with your own values, no default classes are inherited, so your
  custom classes must fully style the input

### JS and CSS guidelines

- **Use daisyUI as the project's chosen component system**, with Tailwind CSS utilities for layout, spacing, and responsive behaviour.
- Tailwindcss v4 **no longer needs a tailwind.config.js** and uses a new import syntax in `app.css`:

      @import "tailwindcss" source(none);
      @source "../css";
      @source "../js";
      @source "../../lib/my_app_web";

- **Always use and maintain this import syntax** in the app.css file for projects generated with `phx.new`
- **Prefer `@apply`** over long or repeated Tailwind class lists. When the same set of utilities repeats across elements, or a single class attribute grows unwieldy, extract it into a CSS rule with `@apply` instead of copying the classes around
- **Prefer colocated CSS** for styles that belong to a single component or template, so the styles live next to the markup they apply to. Use `PochestWeb.ColocatedCSS` (not `Phoenix.LiveView.ColocatedCSS` directly) — it hashes class names per module like CSS Modules, so pair it with the `c/2` helper on the markup side:

      import PochestWeb.ColocatedCSS, only: [c: 2]

      ~H"""
      <style :type={PochestWeb.ColocatedCSS}>
        .card h2 { @apply text-xl font-semibold; }
      </style>

      <div class={c(__MODULE__, "card")}>...</div>
      """

  Only class selectors get the suffix — tags, pseudo-classes and `@apply` are left alone. Use `assets/css/app.css` for genuinely global styles

- **Prefer colocated hooks** (`<script :type={Phoenix.LiveView.ColocatedHook} name=".MyHook">`) for JS that belongs to a single component, so the behaviour lives next to the markup it drives. The leading dot in the name scopes the hook to the defining module, and `phx-hook=".MyHook"` on the element references it. Colocated hooks are already wired up in `app.js` via `phoenix-colocated/pochest` — no manual registration needed. Put JS in `assets/js/` and register it explicitly only when it is shared across several LiveViews (see `EncryptedVault`, `MemoryRecorder`)
- **Prefer daisyUI components wherever available** (`btn`, `card`, `badge`, `alert`, `tabs`, `input`, etc.) over custom implementations. Use custom CSS only where daisyUI does not cover the requirement, preserving the project's theme. For client-facing UI, consult the `design-system` skill for tokens, component patterns, and accessibility rules.
- Out of the box **only the app.js and app.css bundles are supported**
  - You cannot reference an external vendor'd script `src` or link `href` in the layouts
  - You must import the vendor deps into app.js and app.css to use them
  - **Never write inline <script>custom js</script> tags within templates** — the one exception is colocated hooks (`:type={Phoenix.LiveView.ColocatedHook}`), which are extracted at compile time and never end up inline in the rendered page

### UI/UX & design guidelines

- UI should be predictable and easy to understand by old, non-technical people
- Use DaisyUI as a design system and a backbone for unified look across the project, extend it if needed
- **Produce world-class UI designs** with a focus on usability, aesthetics, and modern design principles
- Implement **subtle micro-interactions** (e.g., button hover effects, and smooth transitions)
- Ensure **clean typography, spacing, and layout balance** for a refined, premium look
