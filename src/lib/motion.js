// Shared motion presets. Everything here animates transform/opacity only.

export const spring = { type: 'spring', stiffness: 420, damping: 38, mass: 0.9 }
export const softSpring = { type: 'spring', stiffness: 300, damping: 34 }
export const iosEase = [0.32, 0.72, 0, 1]

// Tab-to-tab: short horizontal nudge in the direction of travel.
export const tabVariants = {
  enter: (dir) => ({ x: dir * 28, opacity: 0 }),
  center: { x: 0, opacity: 1 },
  exit: (dir) => ({ x: dir * -28, opacity: 0 }),
}
export const tabTransition = { duration: 0.24, ease: iosEase }
