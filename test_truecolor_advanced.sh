#!/bin/bash
# Advanced True Color Test with Visual Comparisons

echo "=== ADVANCED TRUE COLOR TESTS ==="
echo ""

echo "Test 1: Gradient Comparison"
echo "If true color works, the first line should be smoother than the second:"
echo "TRUE COLOR (256 levels):"
for i in {0..255}; do
    r=$((i))
    printf "\x1b[48;2;${r};0;0m "
done
printf "\x1b[0m\n"

echo "256 COLOR (stepped):"
for i in {0..16}; do
    val=$((i * 16))
    printf "\x1b[48;5;${val}m "
done
printf "\x1b[0m\n"

echo ""
echo "Test 2: Complex Color Gradients"
echo "Red-Yellow-Green-Cyan-Blue-Magenta:"
for i in {0..100}; do
    # Create RGB gradient through spectrum
    if [ $i -lt 25 ]; then
        # Red to Yellow
        r=255
        g=$((i * 255 / 24))
        b=0
    elif [ $i -lt 50 ]; then
        # Yellow to Green
        r=$((255 - (i-25) * 255 / 24))
        g=255
        b=0
    elif [ $i -lt 75 ]; then
        # Green to Cyan
        r=0
        g=255
        b=$(((i-50) * 255 / 24))
    else
        # Cyan to Blue
        r=0
        g=$((255 - (i-75) * 255 / 24))
        b=255
    fi
    printf "\x1b[48;2;${r};${g};${b}m "
done
printf "\x1b[0m\n"

echo ""
echo "Test 3: Subtle Gray Scale (very sensitive test)"
echo "If you see smooth grays with no color tinting, true color is perfect:"
for i in {10..50}; do
    printf "\x1b[48;2;${i};${i};${i}m "
done
printf "\x1b[0m\n"

echo ""
echo "Test 4: Random Colors (just for fun)"
echo "This shows you can represent any color:"
for i in {0..20}; do
    r=$((RANDOM % 256))
    g=$((RANDOM % 256))
    b=$((RANDOM % 256))
    printf "\x1b[48;2;${r};${g};${b}m "
done
printf "\x1b[0m\n"