import { defineConfig } from "vite";

export default defineConfig({
    build: {
        emptyOutDir: true,
        lib: {
            entry: "index.ts",
            fileName: "index",
            formats: ["es"],
        },
    },
});
