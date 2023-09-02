import { resolve } from "path";
import esbuild from "rollup-plugin-esbuild";

export default [
    {
        input: "index.ts",
        plugins: [esbuild()],
        output: [
            {
                file: resolve("./dist/es/index.mjs"),
                format: "es",
            },
            {
                file: resolve("./dist/cjs/index.cjs"),
                format: "cjs",
            },
        ],
    },
];
