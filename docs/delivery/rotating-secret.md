# Rotating the Signing Secret

Rotate immediately if a signing key is exposed or suspected compromised.

Safe rotation plan:

- Create a new webhook to obtain a new signing key (keys are only returned on creation).
- Update your receiver to accept both the old and new keys for a short window.
- Monitor deliveries to confirm the new key is active.
- Remove the old key from your verifier and delete the old webhook if no longer needed.
