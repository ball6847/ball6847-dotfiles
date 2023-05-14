#!/usr/bin/env -S deno run --allow-run

import { configure } from "../deno-libs/xinput.ts";

/**
 * Configure devices,
 * I commonly use this to enable locked drags on my touchpad.
 *
 * To list all devices:
 * $ xinput --list

 * To list all properties of a device
 * $ xinput --list-props <device-id>
 *
 * To set a property of a device
 * $ xinput --set-prop <device-id> <property-id> <value>
 */

await configure([
  {
    name: "ELAN0E03:00 04F3:3121 Touchpad",
    props: [
      {
        name: "Drag Lock Enabled",
        value: 1,
      },
    ],
  },
]);
