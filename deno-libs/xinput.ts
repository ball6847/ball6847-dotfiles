import { escapeStringRegexp } from "https://cdn.jsdelivr.net/gh/asabya/escape_string_regexp@v0.0.1/mod.ts";
import { run } from "./run.ts";

export async function findDeviceId(name: string) {
  const output = await run("xinput", ["--list"]);
  const pattern = new RegExp(escapeStringRegexp(name) + "\\s+id=(\\d+)", "g");
  const results = output.matchAll(pattern);
  const deviceIds: number[] = [];
  for (const parts of results) {
    if (parts[1]) {
      deviceIds.push(Number(parts[1]));
    }
  }
  return deviceIds;
}

export async function findPropId(deviceId: number, name: string) {
  const output = await run("xinput", ["--list-props", String(deviceId)]);
  const pattern = new RegExp(escapeStringRegexp(name) + "\\s+\\((\\d+)\\)");
  const parts = output.match(pattern);
  if (!parts || !parts[1]) {
    return null;
  }
  return Number(parts[1]);
}

export async function setPropValue(
  deviceId: number,
  propId: number,
  value: number
) {
  await run("xinput", [
    "--set-prop",
    String(deviceId),
    String(propId),
    String(value),
  ]);
}

export type Device = {
  name: string;
  props: Array<{
    name: string;
    value: number;
  }>;
};

export async function configure(devices: Device[]) {
  for (const device of devices) {
    const deviceIds = await findDeviceId(device.name);
    for await (const prop of device.props) {
      for await (const deviceId of deviceIds) {
        const propId = await findPropId(deviceId, prop.name);
        if (!propId) {
          console.warn(`Property(${prop.name}) not found`);
          continue;
        }
        console.log(`Setting ${device.name} [${prop.name}] to ${prop.value}`);
        await setPropValue(deviceId, propId, prop.value);
      }
    }
  }
}
