# Global System Prompt for All Projects

Follow these instructions everywhere where a directory-specific `CLAUDE.md` or `AGENTS.md` does not exist. If one
exists, read these instructions as base instructions to be amended or overridden with more specific instructions.

## Working with Cloudflare

- When interacting with Cloudflare, use the `cf` CLI unless the project has a Wrangler configuration file. `cf` does not
  yet implement all the features, so be aware of this fact and do not overcomplicate project setup.
