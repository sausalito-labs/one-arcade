#!/bin/bash
# Native macOS sprite slicer using built-in sips (Zero installs required)

SRC="fighter.png"

if [ ! -f "$SRC" ]; then
    echo "Error: $SRC not found in current directory."
    exit 1
fi

# Get image dimensions via sips
WIDTH=$(sips -g pixelWidth "$SRC" | awk '/pixelWidth/ {print $2}')
HEIGHT=$(sips -g pixelHeight "$SRC" | awk '/pixelHeight/ {print $2}')

echo "Image dimensions: ${WIDTH}x${HEIGHT}"

# Your sheet layout: 4 vertical sections, 2 columns
# We define clean bounding boxes (Height Width OffsetY OffsetX)
# sips format: -c Height Width --cropOffset OffsetY OffsetX

mkdir -p cuts

# 1. Top Head (Profile)
sips "$SRC" -o "cuts/head.png" -c $((HEIGHT / 5)) $((WIDTH / 3)) --cropOffset 1 1 > /dev/null

# 2. Torso & Chest
sips "$SRC" -o "cuts/torso.png" -c $((HEIGHT / 3)) $((WIDTH / 3)) --cropOffset 1 $((WIDTH * 2 / 3)) > /dev/null

# 3. Lead Arm / Bicep
sips "$SRC" -o "cuts/arm_lead.png" -c $((HEIGHT / 4)) $((WIDTH / 2)) --cropOffset $((HEIGHT / 4)) 1 > /dev/null

# 4. Long Leg
sips "$SRC" -o "cuts/leg_long.png" -c $((HEIGHT / 2)) $((WIDTH / 3)) --cropOffset $((HEIGHT / 2)) 1 > /dev/null

# 5. Forearms / Gloves
sips "$SRC" -o "cuts/forearm.png" -c $((HEIGHT / 6)) $((WIDTH / 3)) --cropOffset $((HEIGHT * 3 / 8)) $((WIDTH * 2 / 3)) > /dev/null

echo "Done! Slices exported to ./cuts/"
ls -lh cuts/
