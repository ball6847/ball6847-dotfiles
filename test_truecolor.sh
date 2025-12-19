#!/bin/bash
# True Color Test Script

echo "=== True Color Test ==="
echo "Checking environment:"
echo "TERM: $TERM"
echo "COLORTERM: $COLORTERM"
echo "In tmux: $TMUX"
echo ""

echo "=== 256 Color Test (should look stepped/banded) ==="
for i in {0..15}; do
    printf "\x1b[38;5;${i}mColor $i\x1b[0m "
done
echo ""

echo "=== True Color Test (should be smooth gradient) ==="
for i in {0..255}; do
    r=$((i * 255 / 255))
    g=$((i * 255 / 255))
    b=$((i * 255 / 255))
    printf "\x1b[38;2;${r};${g};${b}m█"
done
echo ""

echo "=== RGB Gradient Test ==="
for i in {0..100}; do
    r=$((i * 255 / 100))
    printf "\x1b[48;2;${r};0;0m "
done
printf "\x1b[0m\n"

echo "=== True Color vs 256 Color Comparison ==="
echo "If you see smooth gradients below, true color is working:"
for i in {0..10}; do
    val=$((i * 25))
    printf "\x1b[38;2;${val};128;255m■"
done
printf "\x1b[0m (True Color)\n"

for i in {0..10}; do
    val=$((i * 25))
    printf "\x1b[38;5;$((val/8))m■"
done
printf "\x1b[0m (256 Color)\n"