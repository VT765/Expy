// Category accent → tints used for chips and emoji circles.
const hexToRgb = (hex) => {
  const n = parseInt(hex.slice(1), 16)
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255]
}

export const tint = (hex = '#9DB0C4', alpha = 0.15) => {
  const [r, g, b] = hexToRgb(hex)
  return `rgba(${r}, ${g}, ${b}, ${alpha})`
}

export const CATEGORY_COLORS = [
  '#FF6B6B', '#FF7A59', '#FF9F7A', '#FFB340', '#E8D25A', '#5FD38D',
  '#5AC8FA', '#8AB4F8', '#B48CFF', '#FF5C8A', '#9DB0C4', '#D9D9D9',
]
