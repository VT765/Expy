import { Component } from 'react'
import Button from './Button'

// Last-resort crash screen in the app's style; data in IndexedDB is untouched.
export default class ErrorBoundary extends Component {
  state = { error: null }

  static getDerivedStateFromError(error) {
    return { error }
  }

  componentDidCatch(error, info) {
    console.warn('Expy crashed', error, info?.componentStack)
  }

  render() {
    if (!this.state.error) return this.props.children
    return (
      <div className="flex h-full flex-col items-center justify-center bg-canvas px-10 text-center">
        <span className="text-[44px]">🫠</span>
        <h1 className="mt-3 text-title font-bold">Something went wrong</h1>
        <p className="mt-1.5 text-footnote text-sub">Your data is safe on this device. Reload to continue.</p>
        <Button className="mt-6" size="md" onClick={() => window.location.reload()}>
          Reload
        </Button>
      </div>
    )
  }
}
