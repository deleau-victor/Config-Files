/**
 * VSCode Theme Generator
 *
 * Reads theme.yaml and generates colorCustomizations for settings.json
 *
 * Usage: npx tsx generate-theme.ts
 */

import * as fs from "fs";
import * as path from "path";
import * as yaml from "yaml";
import * as jsonc from "jsonc-parser";

// Paths
const THEME_FILE = path.join(__dirname, "theme.yaml");
const SETTINGS_FILE = path.join(process.env.APPDATA || "", "Code", "User", "settings.json");

interface ThemeConfig {
    colors: Record<string, string>;
    mappings: Record<string, string>;
}

function loadTheme(): ThemeConfig {
    const content = fs.readFileSync(THEME_FILE, "utf-8");
    return yaml.parse(content) as ThemeConfig;
}

function generateColorCustomizations(theme: ThemeConfig): Record<string, string> {
    const result: Record<string, string> = {};

    for (const [property, colorName] of Object.entries(theme.mappings)) {
        const color = theme.colors[colorName];
        if (color) {
            result[property] = color;
        } else {
            console.warn(`Warning: Color "${colorName}" not found for property "${property}"`);
        }
    }

    return result;
}

function writeSettingsJson(settings: any, originalContent: string): void {
    // Use jsonc to apply edits while preserving formatting and comments
    const edits = jsonc.modify(
        originalContent,
        ["workbench.colorCustomizations"],
        settings["workbench.colorCustomizations"],
        { formattingOptions: { tabSize: 2, insertSpaces: true } }
    );
    const newContent = jsonc.applyEdits(originalContent, edits);
    fs.writeFileSync(SETTINGS_FILE, newContent, "utf-8");
}

function main() {
    console.log("Loading theme configuration...");
    const theme = loadTheme();

    console.log(`Found ${Object.keys(theme.colors).length} colors`);
    console.log(`Found ${Object.keys(theme.mappings).length} mappings`);

    console.log("\nGenerating colorCustomizations...");
    const colorCustomizations = generateColorCustomizations(theme);

    console.log("\nReading settings.json...");
    const originalContent = fs.readFileSync(SETTINGS_FILE, "utf-8");
    const settings = jsonc.parse(originalContent);

    // Update colorCustomizations
    settings["workbench.colorCustomizations"] = colorCustomizations;

    console.log("\nWriting settings.json...");
    writeSettingsJson(settings, originalContent);

    console.log(
        `\n✓ Done! Applied ${Object.keys(colorCustomizations).length} color customizations.`
    );
}

main();
