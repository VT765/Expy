// Renders the app icon SVG into the PNG sizes iOS and the manifest need.
import sharp from 'sharp'
import { writeFile } from 'node:fs/promises'

const icon = (pad = 0) => `
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <rect width="512" height="512" fill="#000"/>
  <g transform="translate(${pad} ${pad}) scale(${(512 - pad * 2) / 512})">
    <text x="256" y="338" text-anchor="middle" font-family="Helvetica Neue, Helvetica, Arial, sans-serif"
      font-weight="700" font-size="260" fill="#fff" letter-spacing="-10">E</text>
    <rect x="166" y="380" width="180" height="18" rx="9" fill="#fff"/>
  </g>
</svg>`

const out = 'public/icons'
await writeFile(`${out}/favicon.svg`, icon())
const jobs = [
  ['icon-192.png', 192, 0],
  ['icon-512.png', 512, 0],
  ['icon-512-maskable.png', 512, 64],
  ['apple-touch-icon.png', 180, 0],
]
for (const [name, size, pad] of jobs) {
  await sharp(Buffer.from(icon(pad))).resize(size, size).png().toFile(`${out}/${name}`)
}
console.log('icons written to', out)
