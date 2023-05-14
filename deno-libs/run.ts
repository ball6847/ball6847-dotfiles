export async function run(bin: string, args: string[]) {
  const command = new Deno.Command(bin, {
    args,
  });
  const output = await command.output();
  const decoder = new TextDecoder();
  const stdout = decoder.decode(output.stdout);
  return stdout;
}
