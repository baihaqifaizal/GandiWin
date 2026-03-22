package animation

import (
	"math/rand"
	"strings"
	"time"
)

// Fire simulation constants
const (
// Reference uses 65 as heat injection value
// We will map 0-65 to our palette
)

// ANSI Colors for fire intensity
// Mapping based on reference styles:
// 0: Black
// 1: Maroon (Low)
// 2: Red (Medium)
// 3: DarkOrange (High)
// 4: Yellow (Bright/Bold)
var firePalette = []string{
	"\033[38;2;0;0;0m",     // 0: Black
	"\033[38;2;128;0;0m",   // 1: Maroon
	"\033[38;2;255;0;0m",   // 2: Red
	"\033[38;2;255;140;0m", // 3: Dark Orange
	"\033[1;33m",           // 4: Yellow (Bold)
}

// Characters for intensity (0-9)
// Reference: ' ', '.', ':', '^', '*', 'x', 's', 'S', '#', '$'
var fireChars = []rune{' ', '.', ':', '^', '*', 'x', 's', 'S', '#', '$'}

type Fire struct {
	Width  int
	Height int
	Buffer []int
	Rand   *rand.Rand
}

func NewFire(width, height int) *Fire {
	size := width * height
	// Buffer needs to be larger to handle the simple averaging kernel edge cases safely
	// Reference: buffer := make([]int, size+width+1)
	return &Fire{
		Width:  width,
		Height: height,
		Buffer: make([]int, size+width+1),
		Rand:   rand.New(rand.NewSource(time.Now().UnixNano())),
	}
}

func (f *Fire) Update() {
	w, h := f.Width, f.Height
	size := w * h

	// 1. Inject heat on bottom row
	// Reference: for i := 0; i < width/9; i++ ...
	// Since our width is small (80), width/9 is ~8 points.
	for i := 0; i < w/9; i++ {
		// Random index in the last row
		idx := f.Rand.Intn(w) + w*(h-1)
		if idx >= 0 && idx < len(f.Buffer) {
			f.Buffer[idx] = 65 // Heat value from reference
		}
	}

	// 2. Propagate and cool
	// Reference uses a simple average of 4 neighbors: current, right, down, down-right
	// It relies on implicit "in-place" updates where we are reading values that might
	// be from the previous frame (if they are > i) or current frame?
	// Actually, since i goes 0->size, and we read i+1, i+w, i+w+1, we are reading
	// mostly "old" values (from the bottom/right which haven't been written yet in this pass).

	for i := 0; i < size; i++ {
		// Boundary check for access is handled by oversized buffer,
		// but we should adhere to strict logic if possible.
		// Reference code just accesses buffer[i+width+1] which is why buffer is larger.

		b0 := f.Buffer[i]
		b1 := f.Buffer[i+1]
		b2 := f.Buffer[i+w]
		b3 := f.Buffer[i+w+1]

		v := (b0 + b1 + b2 + b3) / 4

		f.Buffer[i] = v
	}
}

func (f *Fire) RenderLine(lineIndex int) string {
	if lineIndex >= f.Height {
		return ""
	}
	var sb strings.Builder

	// Start of the line in buffer
	startIdx := lineIndex * f.Width

	for x := 0; x < f.Width; x++ {
		idx := startIdx + x
		if idx >= len(f.Buffer) {
			break
		}

		v := f.Buffer[idx]

		// Map value v (0-65) to Style and Char
		// Reference mapping:
		// >15 -> style 4
		// >9 -> style 3
		// >4 -> style 2
		// else -> style 1 (unless 0?)

		var colorCode string
		if v > 15 {
			colorCode = firePalette[4]
		} else if v > 9 {
			colorCode = firePalette[3]
		} else if v > 4 {
			colorCode = firePalette[2]
		} else {
			// v <= 4
			colorCode = firePalette[1]
		}

		// Char mapping: chIdx = v (clamped 0-9)
		chIdx := v
		if chIdx > 9 {
			chIdx = 9
		}
		if chIdx < 0 {
			chIdx = 0
		}

		sb.WriteString(colorCode)
		sb.WriteRune(fireChars[chIdx])
	}
	sb.WriteString("\033[0m") // Reset
	return sb.String()
}

func (f *Fire) Render() string {
	// For full debug reference if needed
	var sb strings.Builder
	for y := 0; y < f.Height; y++ {
		sb.WriteString(f.RenderLine(y))
		sb.WriteString("\n")
	}
	return strings.TrimSuffix(sb.String(), "\n")
}
