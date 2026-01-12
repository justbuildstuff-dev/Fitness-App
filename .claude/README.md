# Claude Code Configuration

This directory contains configuration files for Claude Code (claude.ai/code).

## Setup Instructions

### First Time Setup

1. **Copy the settings template:**
   ```bash
   cp settings.json.template settings.json
   ```

2. **Create a GitHub Personal Access Token:**
   - Go to https://github.com/settings/tokens
   - Click "Generate new token (classic)"
   - Name: "Claude Code - Fitness App"
   - Expiration: Choose your preference (90 days recommended)
   - Scopes required:
     - `repo` (Full control of private repositories)
     - `workflow` (Update GitHub Action workflows)
     - `read:org` (Read org and team membership)
   - Click "Generate token"
   - Copy the token (starts with `github_pat_`)

3. **Create a Notion Integration Token:**
   - Go to https://www.notion.so/my-integrations
   - Click "+ New integration"
   - Name: "Claude Code - Fitness App"
   - Associated workspace: Select "FitTrack Development"
   - Capabilities: Read content, Update content, Insert content
   - Click "Submit"
   - Copy the "Internal Integration Token" (starts with `ntn_`)
   - **Important:** Share the following Notion databases with your integration:
     - Product Requirements
     - Technical Designs
     - Decisions & Notes

4. **Update settings.json with your tokens:**
   ```json
   {
     "mcpServers": {
       "github": {
         "env": {
           "GITHUB_PERSONAL_ACCESS_TOKEN": "paste_your_github_token_here"
         }
       },
       "notion": {
         "env": {
           "NOTION_TOKEN": "paste_your_notion_token_here"
         }
       }
     }
   }
   ```

5. **Verify it works:**
   - Restart Claude Code
   - The MCP servers should connect automatically
   - Test by asking Claude to list GitHub issues or query Notion

## Security Notes

- **NEVER commit `settings.json` to git** - It contains sensitive tokens
- The `.gitignore` file is configured to exclude `settings.json`
- Only `settings.json.template` should be committed to version control
- If you accidentally commit tokens, revoke them immediately and create new ones

## Files in This Directory

- `settings.json.template` - Template with placeholder values (safe to commit)
- `settings.json` - Your actual configuration with real tokens (NEVER commit)
- `settings.local.json` - Additional local overrides (NEVER commit)
- `agents/` - Agent-specific instruction files
- `skills/` - Reusable procedural knowledge for agents

## Troubleshooting

### MCP Servers Not Connecting

1. Check that `settings.json` exists and has valid tokens
2. Verify tokens haven't expired
3. For Notion: Ensure databases are shared with the integration
4. Restart Claude Code

### Token Permissions Issues

- **GitHub:** Ensure `repo` and `workflow` scopes are enabled
- **Notion:** Ensure integration has Read/Update/Insert capabilities
- **Notion:** Verify databases are shared with the integration

## Token Rotation

For security, rotate your tokens periodically:

1. Create new tokens (follow setup steps above)
2. Update `settings.json` with new tokens
3. Revoke old tokens in GitHub/Notion
4. Test to ensure everything still works
