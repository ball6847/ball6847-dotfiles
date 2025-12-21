/**
 * Windows Terminal Settings Merger
 *
 * This script merges pre-configured actions and keybindings from
 * ./assets/windows-terminal-config.json into all Windows Terminal
 * settings.json files found on the system.
 *
 * Usage: deno run --allow-read --allow-write --allow-env scripts/merge-windows-terminal-settings.ts
 */

import { dirname, join, fromFileUrl } from "@std/path";

type Action = {
  command: string | Record<string, unknown>;
  id: string;
  [key: string]: unknown;
};

type Keybinding = {
  id: string | null;
  keys: string;
  [key: string]: unknown;
};

type ActionsAndKeybindings = {
  actions: Action[];
  keybindings: Keybinding[];
};

type WindowsTerminalSettings = {
  actions?: Action[];
  keybindings?: Keybinding[];
  [key: string]: unknown;
};

// Get script directory and resolve assets path using Deno's functions
// This script is in scripts/ directory, assets/ is one level up
const PRE_CONFIGURED_SETTINGS_PATH = join(
  dirname(dirname(fromFileUrl(import.meta.url))),
  "assets",
  "windows-terminal-config.json",
);

// Helper function to check if file exists
async function fileExists(filePath: string): Promise<boolean> {
  try {
    const stat = await Deno.stat(filePath);
    return stat.isFile;
  } catch {
    return false;
  }
}

// get pre-configured settings from ./assets/windows-terminal-config.json
async function getPreConfiguredSettings(): Promise<ActionsAndKeybindings> {
  const content = await Deno.readTextFile(PRE_CONFIGURED_SETTINGS_PATH);
  const config = JSON.parse(content);
  return {
    actions: config.actions || [],
    keybindings: config.keybindings || [],
  };
}

// lookup windows terminal settings.json files
async function windowsTerminalSettingsLookup(): Promise<string[]> {
  const settingsFiles: string[] = [];
  const localAppData = Deno.env.get("LOCALAPPDATA");

  if (!localAppData) {
    console.error("LOCALAPPDATA environment variable not found");
    return settingsFiles;
  }

  const packagesDir = `${localAppData}\\Packages`;

  try {
    for await (const entry of Deno.readDir(packagesDir)) {
      if (
        entry.name.startsWith("Microsoft.WindowsTerminal_") &&
        entry.isDirectory
      ) {
        const settingsPath = `${packagesDir}\\${entry.name}\\LocalState\\settings.json`;
        if (await fileExists(settingsPath)) {
          settingsFiles.push(settingsPath);
          console.log(`Found Windows Terminal settings: ${settingsPath}`);
        }
      }
    }
  } catch (error) {
    if (error instanceof Deno.errors.NotFound) {
      console.error(
        `Windows Terminal packages directory not found: ${packagesDir}`,
      );
    } else if (error instanceof Deno.errors.PermissionDenied) {
      console.error(`Permission denied accessing: ${packagesDir}`);
    } else {
      console.error(
        `Error scanning Windows Terminal packages: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  return settingsFiles;
}

// Helper function to check if action is duplicate
function isActionDuplicate(
  newAction: Action,
  existingActions: Action[],
): boolean {
  return existingActions.some((action) => action.id === newAction.id);
}

// Helper function to check if keybinding is duplicate
function isKeybindingDuplicate(
  newKeybinding: Keybinding,
  existingKeybindings: Keybinding[],
): boolean {
  return existingKeybindings.some(
    (keybinding) =>
      keybinding.keys === newKeybinding.keys &&
      keybinding.id === newKeybinding.id,
  );
}

// merge actions and keybindings settings into windows terminal setting file
async function mergeSettingsToFile(
  settings: ActionsAndKeybindings,
  filePath: string,
): Promise<void> {
  try {
    // Read existing settings
    const content = await Deno.readTextFile(filePath);
    const existingSettings: WindowsTerminalSettings = JSON.parse(content);

    // Initialize arrays if they don't exist
    const existingActions = existingSettings.actions || [];
    const existingKeybindings = existingSettings.keybindings || [];

    // Merge actions (avoid duplicates)
    const mergedActions = [...existingActions];
    for (const newAction of settings.actions) {
      if (!isActionDuplicate(newAction, mergedActions)) {
        mergedActions.push(newAction);
      }
    }

    // Merge keybindings (avoid duplicates)
    const mergedKeybindings = [...existingKeybindings];
    const nullIdKeybindings: Keybinding[] = [];
    const regularKeybindings: Keybinding[] = [];

    // Separate keybindings by id
    for (const newKeybinding of settings.keybindings) {
      if (!isKeybindingDuplicate(newKeybinding, mergedKeybindings)) {
        if (newKeybinding.id === null) {
          nullIdKeybindings.push(newKeybinding);
        } else {
          regularKeybindings.push(newKeybinding);
        }
      }
    }

    // Add new keybindings to existing ones
    mergedKeybindings.push(...nullIdKeybindings, ...regularKeybindings);

    // Sort keybindings: id=null at the top, then the rest
    mergedKeybindings.sort((a, b) => {
      if (a.id === null && b.id !== null) return -1;
      if (a.id !== null && b.id === null) return 1;
      return 0;
    });

    // Create merged settings object
    const mergedSettings: WindowsTerminalSettings = {
      ...existingSettings,
      actions: mergedActions,
      keybindings: mergedKeybindings,
    };

    // Write back the merged JSON
    await Deno.writeTextFile(filePath, JSON.stringify(mergedSettings, null, 2));
    console.log(`Successfully merged settings to: ${filePath}`);
  } catch (error) {
    if (error instanceof Deno.errors.NotFound) {
      console.error(`Settings file not found: ${filePath}`);
    } else if (error instanceof Deno.errors.PermissionDenied) {
      console.error(`Permission denied writing to: ${filePath}`);
    } else if (error instanceof SyntaxError) {
      console.error(`Invalid JSON in settings file: ${filePath}`);
    } else {
      console.error(
        `Error merging settings to ${filePath}: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }
}

try {
  const preConfiguredSettings = await getPreConfiguredSettings();
  const settingsFiles = await windowsTerminalSettingsLookup();

  if (settingsFiles.length === 0) {
    console.log("No Windows Terminal settings files found.");
    Deno.exit(0);
  }

  console.log(
    `Found ${settingsFiles.length} Windows Terminal settings file(s):`,
  );

  for (const filePath of settingsFiles) {
    console.log(`\nProcessing: ${filePath}`);
    await mergeSettingsToFile(preConfiguredSettings, filePath);
  }

  console.log("\nWindows Terminal settings merge completed!");
} catch (error) {
  console.error(
    `Windows Terminal settings merge failed: ${error instanceof Error ? error.message : String(error)}`,
  );
  console.error("Exiting.");
  Deno.exit(1);
}
