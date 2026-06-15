{{flutter_js}}
{{flutter_build_config}}

// Standard Flutter web bootstrap.
// hostElement defaults to document.body — no need to override it.
// Viewport enforcement is handled by the JavaScript in index.html.
_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    let appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
  },
});
