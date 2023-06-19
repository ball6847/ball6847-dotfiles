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
 *
 * To automatically activate this script on startup, add this to ~/.xsessionrc
 * $ echo "$HOME/.dotfiles/bin/configure-touchpad.ts" >> ~/.xsessionrc
 */

await configure([
  {
    name: "ELAN1200:00 04F3:3022 Touchpad",
    props: [
      {
        name: "Drag Lock Enabled",
        value: 1,
      },
      {
        name: "Scrolling Pixel Distance",
        value: 40,
      },
    ],
  },
  {
    name: "Apple Inc. Magic Trackpad 2",
    props: [
      {
        name: "Drag Lock Enabled",
        value: 1,
      },
      // {
      //   name: "Scrolling Pixel Distance",
      //   value: 30,
      // },
    ],
  },
  {
    name: "Apple Inc. Magic Trackpad",
    props: [
      {
        name: "Drag Lock Enabled",
        value: 1,
      },
    ],
  },
  {
    name: "ELAN0E03:00 04F3:3121 Touchpad",
    props: [
      {
        name: "Drag Lock Enabled",
        value: 1,
      },
      {
        name: "Scrolling Pixel Distance",
        value: 30,
      },
    ],
  },
]);
