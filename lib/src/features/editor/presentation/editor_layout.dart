/// Width at which the editor shows a persistent side panel instead of a drawer.
const editorSidePanelBreakpoint = 600.0;

/// Whether a window of [width] should show the persistent navigation panel.
///
/// Portrait tablets (800×1280) and landscape desktops (1280×800) both qualify.
/// The panel is hidden when the user has collapsed it.
bool editorShowsSidePanel({required double width, required bool enabled}) =>
    width >= editorSidePanelBreakpoint && enabled;

/// Whether a window of [width] should use a navigation drawer.
bool editorUsesDrawer(double width) => width < editorSidePanelBreakpoint;
