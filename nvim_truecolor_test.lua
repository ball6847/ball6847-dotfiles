-- Neovim True Color Test
-- Run this with :source in Neovim

print("=== NEOVIM TRUE COLOR TEST ===")

-- Check if termguicolors is enabled
print("termguicolors enabled:", vim.o.termguicolors)

-- Check current terminal info  
print("TERM env var:", vim.fn.getenv("TERM"))
print("COLORTERM env var:", vim.fn.getenv("COLORTERM"))

-- Test true color output
print("\n=== Color Gradient Test ===")
for i = 0, 10 do
    local val = i * 25
    print(string.format("Color %d: \27[38;2;%d;128;255m■\27[0m", val, val))
end

print("\n=== Gray Scale Test ===")
for i = 20, 40 do
    print(string.format("Gray %d: \27[38;2;%d;%d;%dm▓\27[0m", i, i, i, i))
end

print("\nIf you see smooth gradients, true color is working in Neovim!")
