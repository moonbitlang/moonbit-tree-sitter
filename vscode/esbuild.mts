import ESBuild from "esbuild";
import * as Fs from "node:fs";
import * as Path from "path";
import * as Module from "node:module";

const production = process.argv.includes("--production");
const watch = process.argv.includes("--watch");
const serve = process.argv.includes("--serve");

const esbuildProblemMatcherPlugin: ESBuild.Plugin = {
  name: "esbuild-problem-matcher",

  setup(build) {
    build.onStart(() => {
      console.log("[watch] build started");
    });
    build.onEnd((result) => {
      result.errors.forEach(({ text, location }) => {
        console.error(`✘ [ERROR] ${text}`);
        if (!location) {
          return;
        }
        console.error(`    ${location.file}:${location.line}:${location.column}:`);
      });
      console.log("[watch] build finished");
    });
  },
};

function findOutdir(buildOptions: ESBuild.BuildOptions): string | undefined {
  if (buildOptions.outdir) {
    return buildOptions.outdir;
  } else if (buildOptions.outfile) {
    return Path.dirname(buildOptions.outfile);
  }
  return undefined;
}

const executablePlugin: ESBuild.Plugin = {
  name: "executable-plugin",
  setup(build) {
    build.onResolve({ filter: /\.exe$/ }, (args): ESBuild.OnResolveResult => {
      return {
        path: Path.join(args.resolveDir, args.path),
        namespace: "exe",
      };
    });
    build.onLoad(
      { filter: /\.exe$/, namespace: "exe" },
      async (args): Promise<ESBuild.OnLoadResult> => {
        const outdir = findOutdir(build.initialOptions);
        if (!outdir) {
          throw new Error(`Could not find outdir for executable`);
        }
        if (!Fs.existsSync(outdir)) {
          await Fs.promises.mkdir(outdir, { recursive: true });
        }
        const sourcePath = Path.resolve(args.path);
        const destFile = Path.basename(args.path);
        const destPath = Path.join(outdir, destFile);
        await Fs.promises.copyFile(sourcePath, destPath);
        return {
          contents: `export default "${destFile}";`,
          loader: "js",
        };
      }
    );
  },
};

const vscodePlugin: ESBuild.Plugin = {
  name: "vscode-plugin",
  setup(build) {
    build.onEnd(async () => {
      const outfile = build.initialOptions.outfile;
      if (!outfile) {
        throw new Error(`Could not find outfile for vscode`);
      }
      const outdir = findOutdir(build.initialOptions);
      if (!outdir) {
        throw new Error(`Could not find outdir for vscode`);
      }
      const packageJSON = JSON.parse(await Fs.promises.readFile("package.json", "utf-8"));
      packageJSON["main"] = Path.relative(outdir, outfile);
      await Fs.promises.writeFile(
        Path.join(outdir, "package.json"),
        JSON.stringify(packageJSON, null, 2),
        "utf-8"
      );
    });
  },
};

async function webviewCtx(path: string): Promise<ESBuild.BuildContext> {
  return await ESBuild.context({
    entryPoints: [`src/${path}/index.tsx`],
    bundle: true,
    format: "iife",
    minify: production,
    sourcemap: !production,
    sourcesContent: false,
    platform: "browser",
    outfile: `dist/${path}/index.js`,
    logLevel: "silent",
    plugins: [esbuildProblemMatcherPlugin],
    loader: {
      ".ttf": "file",
      ".tsx": "tsx",
      ".jsx": "jsx",
    },
  });
}

async function main() {
  const extensionCtx = await ESBuild.context({
    entryPoints: ["src/extension.ts"],
    bundle: true,
    format: "esm",
    minify: production,
    sourcemap: !production,
    sourcesContent: false,
    platform: "node",
    outfile: "dist/extension.js",
    external: ["vscode"],
    logLevel: "silent",
    plugins: [esbuildProblemMatcherPlugin, executablePlugin, vscodePlugin],
    loader: {
      ".html": "text",
      ".wasm": "file",
    },
  });
  const sidebarCtx = await webviewCtx("sidebar");

  if (watch) {
    await Promise.all([extensionCtx.watch(), sidebarCtx.watch()]);
    if (serve) {
      const { hosts, port } = await sidebarCtx.serve({
        servedir: "dist/sidebar",
      });
      for (const host of hosts) {
        console.log(`Serving sidebar on http://${host}:${port}`);
      }
    }
  } else {
    await Promise.all([extensionCtx.rebuild(), sidebarCtx.rebuild()]);
    await Promise.all([extensionCtx.dispose(), sidebarCtx.dispose()]);
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
