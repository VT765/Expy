import { fromB64Url, randomBytes, toB64Url } from './crypto'

// Face ID / Touch ID through the WebAuthn platform authenticator. This is a
// local unlock gate: success means the device verified the user (UV flag set)
// for our credential. There's no server round-trip.

export async function isFaceIdAvailable() {
  try {
    return Boolean(window.PublicKeyCredential && (await PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable()))
  } catch {
    return false
  }
}

export async function registerFaceId() {
  const cred = await navigator.credentials.create({
    publicKey: {
      challenge: randomBytes(32),
      rp: { name: 'Expy', id: location.hostname },
      user: { id: randomBytes(16), name: 'expy', displayName: 'Expy' },
      pubKeyCredParams: [
        { type: 'public-key', alg: -7 },
        { type: 'public-key', alg: -257 },
      ],
      authenticatorSelection: { authenticatorAttachment: 'platform', userVerification: 'required', residentKey: 'discouraged' },
      attestation: 'none',
      timeout: 60000,
    },
  })
  return toB64Url(cred.rawId)
}

export async function verifyFaceId(credentialId) {
  const assertion = await navigator.credentials.get({
    publicKey: {
      challenge: randomBytes(32),
      rpId: location.hostname,
      allowCredentials: [{ type: 'public-key', id: fromB64Url(credentialId), transports: ['internal'] }],
      userVerification: 'required',
      timeout: 60000,
    },
  })
  // authenticatorData flags byte: bit 0 = user present, bit 2 = user verified.
  const flags = new Uint8Array(assertion.response.authenticatorData)[32]
  return (flags & 0x05) === 0x05
}
